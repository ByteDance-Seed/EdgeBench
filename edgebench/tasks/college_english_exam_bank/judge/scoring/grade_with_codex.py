#!/usr/bin/env python3
"""Codex agent-based rubrics grader for SE-Bench none-CS tasks.

Drop-in alternative to grade_with_llm.py. Uses Codex CLI as an agent
to grade submissions — supports multimodal (images) and network access.

Environment variables:
  OPENAI_API_KEY        API key for Codex
  OPENROUTER_API_KEY    API key for OpenRouter
  SFORGE_JUDGE_API_KEY  API key for the LLM judge
  SFORGE_JUDGE_API_BASE_URL  Codex-compatible base URL (default: https://openrouter.ai/api/v1)
  SFORGE_JUDGE_MODEL    Model id; required when no Codex config exists in the judge container

Usage:
  python3 grade_with_codex.py \
    --report report.md \
    --scoring-dir scoring/ \
    --task-id labor_compliance_design \
    --input-dir input/
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile
from pathlib import Path


DEFAULT_CODEX_BASE_URL = "https://openrouter.ai/api/v1"


# ---------------------------------------------------------------------------
# File readers (same interface as grade_with_llm.py)
# ---------------------------------------------------------------------------

def read_md(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def read_xlsx(path: Path) -> str:
    import openpyxl
    wb = openpyxl.load_workbook(path, data_only=True)
    parts: list[str] = []
    for ws in wb.worksheets:
        parts.append(f"## Sheet: {ws.title}\n")
        for row in ws.iter_rows(values_only=True):
            cells = [str(c) if c is not None else "" for c in row]
            parts.append(" | ".join(cells))
    return "\n".join(parts)


def read_docx(path: Path) -> str:
    from docx import Document
    doc = Document(str(path))
    parts: list[str] = []
    for p in doc.paragraphs:
        if p.text.strip():
            parts.append(p.text)
    for ti, table in enumerate(doc.tables):
        parts.append(f"\n[Table {ti + 1}]")
        for row in table.rows:
            cells = [c.text.strip() for c in row.cells]
            parts.append(" | ".join(cells))
    return "\n".join(parts)


def read_scoring_files(scoring_dir: Path) -> str:
    readers = {".md": read_md, ".xlsx": read_xlsx, ".docx": read_docx}
    text_parts: list[str] = []
    for f in sorted(scoring_dir.iterdir()):
        reader = readers.get(f.suffix.lower())
        if reader:
            try:
                text_parts.append(f"### File: {f.name}\n\n{reader(f)}")
            except Exception as e:
                text_parts.append(f"### File: {f.name}\n\n[ERROR reading file: {e}]")
    return "\n\n---\n\n".join(text_parts)


def read_input_files(input_dir: Path) -> str:
    readers = {".md": read_md, ".xlsx": read_xlsx, ".docx": read_docx, ".txt": read_md}
    text_parts: list[str] = []
    if not input_dir.is_dir():
        return ""
    for f in sorted(input_dir.iterdir()):
        if f.is_file():
            reader = readers.get(f.suffix.lower())
            if reader:
                try:
                    content = reader(f)
                    text_parts.append(f"### Input File: {f.name}\n\n{content}")
                except Exception as e:
                    text_parts.append(f"### Input File: {f.name}\n\n[ERROR: {e}]")
    return "\n\n---\n\n".join(text_parts)


def read_submission(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix == ".md":
        return read_md(path)
    elif suffix == ".docx":
        return read_docx(path)
    elif suffix == ".txt":
        return read_md(path)
    else:
        return path.read_text(encoding="utf-8", errors="replace")


# ---------------------------------------------------------------------------
# Codex CLI setup
# ---------------------------------------------------------------------------

def ensure_codex_installed() -> str:
    """Ensure codex CLI is installed. Returns path to binary."""
    codex_path = shutil.which("codex")
    if codex_path:
        return codex_path

    sys.stderr.write("[codex-judge] Installing codex CLI...\n")
    subprocess.run(
        ["npm", "install", "-g", "@openai/codex"],
        check=True, capture_output=True, timeout=120,
    )
    codex_path = shutil.which("codex")
    if not codex_path:
        raise RuntimeError("codex CLI installation failed")
    return codex_path


# ---------------------------------------------------------------------------
# Prompt construction
# ---------------------------------------------------------------------------

CODEX_GRADING_PROMPT = """\
你是一个严格、公正的评分 agent。你可以执行 Bash 命令来读取文件、验证信息。

## 你的任务

1. 先读取结构化评分规则 JSON，理解每条规则的通过/不通过标准
2. 枚举并读取评分目录里的原始评分附件、真值表、参考答案和参考成品；这些文件只能作为 JSON 规则的证据来源，不得新增规则
3. 再读取被评分的提交文件或目录，逐条对照 JSON 规则和评分附件里的真值评分
4. 如果需要，读取输入材料来交叉验证提交内容是否真实使用了输入数据
5. 评分完成后自查一遍，确认每条分数与规则标准一致
6. 最后输出评分 JSON

## 文件路径

- 结构化评分规则: `{rubrics_json}`（唯一 authoritative rubric source）
- 原始评分材料目录: `{scoring_dir}`（用于读取 JSON source/reference 指向的真值、参考答案、评分表、专家结果分析）
- 被评分的提交文件或目录: `{report_path}`
- 输入材料目录: `{input_dir}`（用于交叉核验）
- 提交清单: `{submission_manifest}`（先读它；里面列出期望交付物、实际提交文件、缺失文件和可解析性检查）
- 视觉资产清单: `{visual_manifest}`（先读它；里面列出从提交文件中抽出的图片、嵌图和联系表路径，视觉类规则只能基于这些真实资产或你实际读取的页面/图片评分）
- 提交结构清单: `{structure_manifest}`（先读它；里面列出 PPT/Word/Excel 的客观结构数量，如页数、表格、图片、图表、公式、工作表；它只提供事实，不替代你按 rubric 判断）

## 工作流程

### 步骤 1：读取评分规则 JSON
运行 `cat {rubrics_json}` 获取完整评分规则。该文件形如：

```json
{{
  "rules": [
    {{
      "rule_id": "R001",
      "title": "规则名称",
      "max_score": 5,
      "scoring_mode": "additive",
      "criteria": "完整评分要求",
      "scoring_details": [{{"description": "具体评分细节", "points": 1}}],
      "positive_example": "",
      "negative_example": "",
      "source": {{"file": "原始评分附件", "sheet": "", "row_range": ""}}
    }}
  ]
}}
```

严格以 `rules` 数组为评分清单。不要新增、删除、合并 rule；不要用原始附件替代 JSON 规则。additive/deductive rule 如有字段 `veto_conditions`，必须先检查；任一条件被提交触发时，该 rule 直接记 0 分，并在该 rule 的 reason 中写明触发条件和提交证据；其他 rule 继续正常评分，总分不因此清零。penalty rule 不应包含 `veto_conditions`。

### 步骤 1.5：读取评分证据源
运行 `find {scoring_dir} -maxdepth 3 -type f | sort` 枚举评分目录。除 `rubrics.json` 外，优先读取 JSON 中 `source`、`reference_sources`、`criteria`、`scoring_details` 指向或提到的评分附件、真值表、参考答案、专家结果分析、参考成品。

必须遵守：
- 不得默认 `rubrics.json` 已经自包含。每条 rule 评分前先做自包含性检查：JSON 是否已经内联了足够具体的 `scoring_details`、阈值、公式、标准答案、参考清单或可判定文本。
- 如果某条 rule 的 JSON 内联内容足够具体，则直接按 JSON 内联内容评分；无需为了复述来源而全量读取与判分无关的原始 xlsx/docx/pdf。
- 如果某条 rule 的 JSON 只写了“与真实成果一致”“参考真值表”“参考答案”“标准答案”“对应式”“按附件/评分表/专家结果判断”，但没有内联具体真值、公式、清单、阈值或判定文本，必须读取对应原始评分材料，抽出具体依据后再评分。
- 如果 JSON 不自包含且对应评分材料不存在、不可读、抽取不到关键真值，该 rule 不能因为提交“看起来合理”而给分；对依赖该真值的得分点给 0，并在 reason 中写明 JSON 不自包含且无法读取依据。
- 如果对应评分材料不存在、不可读、抽取不到关键真值，且 JSON 也没有内联具体真值，则该规则不能因为提交“看起来合理”而给分；对依赖该真值的得分点给 0，并在 reason 中写明缺少/未读到的依据。
- 原始评分材料只能用于解释和核验 JSON 中已有规则，不得把评分材料中的新维度扩展成额外 rule。
- 对图片型 PDF、扫描件、图片、长图、PPT、Excel、Word 等材料，必须尝试用可用工具读取；读取失败要在相关 rule reason 中说明，不能静默忽略。

常用读取方式：
- `.xlsx` / `.xls`: 用 `python3` + `openpyxl` / `xlrd` 或 `python3` + `pandas` 读取所有 sheet
- `.docx`: 用 `python3` + `python-docx` 读取段落和表格
- `.pptx`: 用 `python3` + `python-pptx` 读取每页文字和表格
- `.pdf`: 用 `python3` + `pdfplumber` 和 `pypdf` 读取；如果文本为空，按不可可靠读取处理
- `.csv` / `.txt` / `.md` / `.json`: 直接读取
- `.jpg` / `.png` / `.gif`: 尝试用可用视觉/图像工具读取；读不到关键信息时按证据不足处理

### 步骤 2：读取提交内容
读取 `{report_path}`。如果它是目录，先用 `find {report_path} -maxdepth 3 -type f` 枚举其中的交付物文件，并读取所有与任务相关的可读文件；忽略 `.git`、`__pycache__`、临时缓存和明显的依赖目录。如果它是单个文件，直接读取该文件。

先运行 `cat {submission_manifest}`。如果清单显示缺少期望交付物、文件格式不匹配、Excel 工作簿没有公式链、或提交文件无法解析，必须把这些作为逐条评分证据；但不得自行发明总分上限、额外扣分比例或新规则。
再运行 `cat {visual_manifest}`。如果该清单显示提交中抽出了图片/嵌图，视觉、图片、PPT页面、Excel嵌图、抽检类规则的证据必须引用这些资产的 `asset_path`、原始文件名和样本位置；如果清单为空或你无法实际读取这些图片内容，依赖视觉内容的得分点按证据不足处理。若清单包含 `assets_truncated=true`，只能读取 `sampled_assets`、`contact_sheet` 和 `sampled_contact_sheet` 中列出的有限样本，不得运行会枚举或打开全部 `visual_assets` 文件的命令。
再运行 `cat {structure_manifest}`。如果规则要求 PPT/Word/Excel 中存在表格、图表、流程图、图片、结构化对象、公式链、工作表或页数，必须使用该结构清单交叉验证；清单显示对象不存在时，不得把项目符号、普通文本框或章节标题当作对应结构化对象。

如果不是纯文本文件，使用合适的 Python 库读取：
- `.docx`: `python3 -c "from docx import Document; d=Document('{report_path}'); [print(p.text) for p in d.paragraphs]"`
- `.xlsx`: 用 `openpyxl`
- `.pptx`: 用 `python-pptx`
- `.pdf`: 用 `pdfplumber`
- 图片文件: 直接打开/查看图片，或用可用视觉能力判断其内容

注意检查：
- 提交是否有实质内容（不是占位/骨架）
- 提交是否引用了输入材料中的具体事实
- 提交的结构是否与交付物要求匹配

### 步骤 3：交叉验证（按需）
如果规则要求引用具体材料/法条/数据，可以读取 `{input_dir}` 下的文件来验证提交内容的准确性。
对于 .docx 文件可以用 `python3 -c "from docx import Document; [print(p.text) for p in Document('file.docx').paragraphs]"` 读取。
对于 .pdf 文件可以用 `python3 -c "import pdfplumber; [print(p.extract_text()) for p in pdfplumber.open('file.pdf').pages]"` 读取。

### 步骤 4：逐条评分
对照 `rubrics.json` 中的每条 rule 逐条打分。采用严格判分：只有提交内容明确满足规则且有可引用证据时才给分；如果某个点比较模糊、证据不足、规则匹配不确定，处于可给可不给的边界，一律不给分。

计分算法必须按以下优先级执行：
1. `scoring_mode` 只应是 `additive`、`deductive` 或 `penalty`。
2. 如果 rule 的 `scoring_mode` 是 `additive`，`scoring_details` 是得分点。必须逐条独立核验并累加 `points`。每个 detail 只有在提交中有明确、具体、可引用证据，且必要时能被评分附件/输入附件核验时，才给该 detail 的 `points`；否则该 detail 给 0。
3. 如果 rule 的 `scoring_mode` 是 `deductive`，这是扣分制正向规则：先按该 rule 的 `max_score` 起评，再按命中的 `scoring_details[].points` 扣分，最低扣到 0。rule 的 `score` 必须在 `[0, max_score]` 范围内，不得输出负数。若 detail 明确写有“每有1个/每出现1处/每缺失1项/每错误1处/每少或每多1个/每超出1个/每累计N个/按差额每...”等可重复扣分语义，必须先统计命中次数，再按 `points × 次数` 扣分；不得把整类问题只当成一次触发。若命中次数很多，继续累计到该 rule 扣至 0 为止。
4. 如果 rule 的 `scoring_mode` 是 `penalty`，这是额外扣分项，不提供任何保底正分。默认该 rule 的 `score` 为 0；命中 `scoring_details` 中的扣分触发项时，按对应 `points` 记为负分，单条 rule 最低为 `-max_score`。不要从 `max_score` 开始给分，也不要把 penalty details 当成正向加分项。若 penalty detail 明确写有“每有/每出现/每缺失/每错误/每超出/每累计/按差额每”等可重复扣分语义，同样必须按实际次数累计扣分，直到该 penalty rule 达到 `-max_score` 下限。
5. 如果 additive/deductive rule 有字段 `veto_conditions`，逐条核验。任一条件命中时，仅该 rule 记 0 分：该 rule 的 `score` 必须为 0，所有 checkpoint score 也应为 0，并在该 rule 的 `reason` 中引用触发条件和提交证据。未命中的 veto condition 不影响该 rule 正常得分。不要因为 rule-level `veto_conditions` 命中而设置全局 `veto_triggered=true`；其他 rule 继续正常评分。penalty rule 不应包含 `veto_conditions`。
6. `max_score` 和 `scoring_details[].points` 已经是最终分值尺度；不要再按原始权重、百分比或源表 10 分制重复换算。
7. 可重复扣分的计数证据必须写进对应 rule 的 `reason` 或 checkpoint 说明中，例如“30 个稳档中 28 个不在区间，按每个 1 分扣，规则扣至 0”。如果无法精确计数但能确认超过规则剩余分值，也要说明“至少 N 个，已足以扣至 0”。不要因为 JSON 只有一个 `scoring_details` 条目就只扣一次。
8. 如果 detail 描述包含多个并列条件，必须全部满足才给分或避免扣分；只满足其中一部分按不满足处理，除非该 detail 自己明确写了可部分得分。
9. 旧缓存兼容：如果 JSON 里仍有旧字段 `checkpoints` 或 `deductions`，按同样语义处理为 additive details、deductive deductions 或 penalty triggers；但新 rubric 以 `scoring_details` 为准。

严禁宽判：
- 不得因为提交自称“已调研”“已使用工具”“原创”“符合要求”“参考了材料”就给分；必须看到可核验的具体证据、数据、引用、公式、内容对应关系或产物文件。
- 对事实准确性、原创性、工具链、数据来源、真实材料使用情况、参考答案一致性等规则，产物自述不是证据。
- 对原创性、查重、同质化、调研路径、工具链、数据来源、官方来源核验、参考成品一致性等规则，必须实际读取并引用可验证的外部材料、输入附件、评分真值表或参考成品。若只看到提交自述“已脑暴/已调研/已查重/自主原创/参考材料”，对应 checkpoint 给 0；不要自行套用固定比例上限。
- 对创意路径、试错过程、查重/同质化、岗位来源真实、官方发布来源、外部证据、调研路径、工具链执行等规则，提交成品内部的“过程叙述”本身不是可验证证据。只有在提交中提供了可复核的来源标题/URL、引用片段、对比对象、检索记录、数据表、代码日志、证据台账，或这些证据能在输入附件/评分附件中被逐项核验时，才可给对应得分。仅写“我做了脑暴/找反例/查重/参考了国网天津公众号/来源于官方发布”不得给高分。
- 如果某个 scoring_detail 的核心要求是“路径可验证”“查重”“来源真实”“官方发布”“参考真值表/参考成品/同质化对比”，而提交只提供自己的结论或过程描述，没有可复核的对比对象、来源标题/URL、原文摘录、表格行匹配、日志或附件证据，则该 detail 的 score 必须为 0；不要给“过程意识分”或“看起来合理分”，除非该 detail 原文本身明确把这种自述列为可得分证据。
- 如果某条 rule 或 scoring_detail 明确绑定命名交付物（例如 `D-01《专家论证意见书》`、`valuation_report.md`、`risk_assessment_matrix.xlsx`、某个工作表/文件名），必须先在提交清单和实际文件中确认该交付物存在。该交付物缺失时，与该交付物绑定的 rule/detail 按缺少可评分对象处理，不得用其他文件、合并报告、摘要章节或提交自述替代，除非规则原文明确允许等价合并交付。
- 如果只是文件名语言、大小写或格式不同，但提交清单显示存在同一交付物的等价文件，按实际内容评分，并在 reason 中说明命名/格式差异；不要因为命名差异自行给总分上限。
- 对明确要求“汇总表、检查清单、审批矩阵、岗位职责矩阵、模板、流程图、决策树、四象限图、对比表、台账、附件表单”的规则，必须核验提交中是否真的存在对应结构化对象，且该对象本身包含规则要求的字段、行列、节点、分支或表单项。散落在正文里的段落、条列、原则描述、章节摘要或口头承诺，不能替代“表/模板/矩阵/清单/图”这个结构化交付本身。
- 对 PPT/Word/Excel 的“可视化、图表、表格、流程图、结构化要素、图文并茂”规则，必须读取 `submission_structure_manifest.json`。普通文本框、项目符号列表、标题页、分栏文字、加粗小标题不等于表格/图表/图片/流程图/SmartArt。若结构清单显示 `tables=0`、`pictures=0`、`charts=0` 或相应对象数量不足，不得给这类结构化/可视化 detail 满分。
- 如果 scoring_detail 单独要求“提供模板/汇总表/矩阵/图示/清单示例”，而提交只在正文里提到相关制度或阈值，没有可定位的模板、表格、矩阵或图示，该 detail 必须给 0。其他非结构化 detail 可以按其自身证据评分，但不得把散点内容折算成结构化 detail 的部分分。
- 对“来自官方发布/真实案例/真值表/参考答案”的要求，必须指出具体来源文件和匹配项；无法逐项匹配时，不得给优秀档。
- 如果规则是 binary/严格一致性判断（例如 max_score 为 1，或 criteria/scoring_details 写“正确/一致/符合/不符合/是/否/必须/否则不得分”），不要给形式相似分或部分分；只有完全满足才给满分，否则给 0。若不满足条件位于 `veto_conditions`，则该 rule 给 0，其他 rule 不受影响。
- 如果 JSON 中有 scoring_details，逐条严格核验；没有直接证据的 additive detail 给 0；deductive/penalty detail 只有在扣分触发项有明确证据时才扣分。
- 如果提交与真值公式、数值、阈值、名单、表格、参考成品只有表面相似但关键细节不一致，相关分数给 0。
- 如果规则要求明确结论、标准口径或必须明说的判断（例如“不适用安全港”“不得通过”“必须删除/禁止/不合格/直接触发”），提交中的“理论上有空间”“需进一步评估”“不宜直接适用”“原则上建议”“可能存在风险”等模糊或相反口径不能替代明确结论；该 detail 不给分。
- 对深度分析类规则，标题齐全、章节齐全、每项重复同一套通用话术，不等于逐项机制分析。若多个制度/对象/案例复用近似模板句，没有各自的具体条款号、运行机制、时间节点、数据或案例支撑，只能给覆盖广度分，不能给深度分析满分。
- 对“阈值依据、权重依据、历史数据校准、参数校准、分级依据、计算依据、来源依据”类规则，提交只给出阈值/权重/公式本身不等于满足“依据”。必须看到可复核的来源、历史数据字段/行、前后参数对比、计算过程、制度条款比例、监管要求或专家给定真值如何推出这些数值；否则只能给“有数值/有方法”的部分，不能给“依据充分/校准完成”的分。
- 对“模板、报告模板、检查模板、评估模板、清单模板”类规则，必须存在可复用的字段化模板、表格、标题字段或填报项。正文段落、操作原则、流程说明、示例描述不能替代模板本身。
- 对“清单、检查清单、尽调清单、调整清单、Checklist”类规则，必须看到逐项可执行的检查条目、字段或勾选项。权重表、维度权重、风险因子表、原则说明或章节目录不能替代清单；例如“种子期技术尽调权重40%、成熟期财务尽调权重35%”只能证明权重差异，不能证明已经给出差异化尽调检查项清单。
- 当 scoring_detail 明确要求“清单/检查项/Checklist/清单调整表”时，给分 evidence 必须引用至少一个具体检查条目、字段或勾选项；只引用“技术尽调、财务尽调、法律尽调”等维度名称、权重百分比或阶段权重表，该 detail 必须给 0。维度权重可以支持“权重方案”规则，但不能支持“检查清单/清单调整表”规则。
- 对“定义、通用规则、边缘案例定义、适用条件”类规则，单个案例推演不能替代通用定义。必须先有可复用的判定条件，再用案例套用；且案例中的数值/等级必须满足该定义。若定义说“高风险”，但示例风险评分或等级没有达到提交自己设定的高风险阈值，该案例得分点不得给满分。
- 对“覆盖全部类别/至少 N 类/列明 X、Y、Z/标准译名映射/参考文献覆盖”等枚举型规则，必须逐项核对每个被列名的类别或条目。文件存在、章节存在、类别大体相关，不能替代缺失的枚举项；若缺少任一明确列名类别或条目，不得给满分。尤其是参考文献覆盖要求包含“学术文献”时，只有法规、案例、政策、国际资料不能满分；术语规则要求标准中英文映射时，只是未误译不能满分。
- 对多步骤工具链、数据处理、药物-靶点筛选、网络构建等流程型规则，最终图像、截图、PPT 或报告摘要只能证明其中可直接看见的结果，不能证明上游筛选、清洗、工具调用、参数设置、交集计算、边表/节点表完整性或数据来源合规。若提交缺少中间表、日志、代码、导出数据、可复核引用或明确元数据，相关上游工具使用、数据使用、完整性和约束条件规则按证据不足给 0，或只给直接可见部分的低分。
- 对数据使用合规性，不能因为“没有看到额外数据/错误数据”就给满分；必须看到正向证据证明提交使用了规则要求的输入对象、疾病/公司/样本/字段等，且没有引入无关数据。
- 对 PPI 网络图、可视化图、截图类提交，图中可见的 STRING/Homo sapiens/阈值/清晰度等只可支持网络图呈现或可见参数的部分得分；不得用一张图替代 TCMSP/PubChem/SwissTargetPrediction/GeneCards/OMIM 等上游步骤、交集基因清单、边表、节点表、筛选阈值和工具链证据。
- 对 deductive/penalty rule，不得把多个缺失项、错误数字、错误条件、错误对象或错误口径合并成一个泛泛问题。若规则或评分附件写明“每缺失1条/每错误1处/逐条勾选/按清单核对”，必须按可判定的最小条目逐项计数并分别扣分；deductive 最低扣到 0，penalty 最低到 `-max_score`。
- 对“必讲点覆盖、标准说法一致性、测试题覆盖、数字阈值准确性、处罚要件、法律构成要件”等规则，形式存在不等于内容满足。只有目录、章节、题目、答案、风险提示、法条摘要等外形，不能抵消缺失的 AnswerKey 条目、关键数字、适用条件、主体/行为/后果绑定或处罚要素。
- 对测试题/测验/问答类规则，评分重点是题目是否覆盖评分附件要求的关键必讲点、数字、条件和标准答案。若只是有若干题目和答案，但漏掉多数关键必讲点，不得给高分；应按漏覆盖的关键条目逐项扣分。
- 对法律处罚和构成要件类规则，泛泛写“可能处罚/需合规/有风险”只能作为低质量证据；必须能把主体、行为、适用条件、法律后果、罚款区间、没收/许可/备案/期限等要素绑定到具体情形，才能避免对应扣分。
- 对宣传策划、文案、PPT、方案设计类任务，最终文案看起来完整不等于满足调研、来源真实性、原创性、查重、合规审核、官方案例覆盖等过程型规则。若评分细则要求“路径可验证”“来源真实”“避免同质化”“官方发布案例”“参考真值表”，必须逐项核验提交中是否提供了可复核证据；没有证据的过程型得分点给 0 或低分。

每条必须给出：
- rule_id（规则编号）
- rule_name（使用 JSON 中的 title）
- score（additive/deductive rule 为 0 到 max_score；penalty rule 为 0 或负数，最低为 -max_score）
- max_score（必须等于 JSON 中该 rule 的 max_score）
- reason（1-2 句理由，引用具体证据：提交文件名/评分附件名 + 关键短句、数值、公式或明确缺失点）

对于 deductive rule：
- `checkpoint_scores` 用来逐条列出 `scoring_details` 的扣分项核验结果；每个 checkpoint 的 `score` 是实际扣掉的正数，未触发为 0；rule 的 `score` 必须是 `max_score - min(sum(triggered deduction scores), max_score)`。
- reason 必须列出关键扣分触发项，尤其是缺失的必讲点、错误标准口径、缺失关键数字。

对于 penalty rule：
- `checkpoint_scores` 用来逐条列出 `scoring_details` 的扣分项核验结果；每个 checkpoint 的 `score` 是实际扣掉的正数，未触发为 0；rule 的 `score` 必须是这些扣分之和的相反数，并且不低于 `-max_score`。
- reason 必须列出关键扣分触发项，尤其是缺失的必讲点、错误标准口径、缺失关键数字。
- 如果 scoring_details 很多，不必逐项长篇展开，但必须说明命中/缺失数量和最重要的缺失项。
- deductive/penalty rule 的评分应高效完成：先用脚本抽取提交文本并做关键词/短语检索，再人工复核关键命中和缺失；不要逐页重读与 JSON 已内联内容重复的评分附件。

每个 checkpoint 的 `evidence` 必须是可复核证据，不是结论。格式上必须尽量同时包含：
- 提交文件名或目录中文件名 + 可定位位置/标题 + 原文短句、数值、公式或清单项
- 若该 checkpoint 依赖评分附件、真值表、参考答案、官方来源、输入附件或参考成品，则还必须写出对应来源文件名 + sheet/页/段落/条目 + 关键真值或匹配项
- 任意正分 checkpoint 的 evidence 必须能让第三方不重新推理也看懂为什么给分。只写“结构完整”“覆盖充分”“有依据”“已校准”“逻辑清晰”“可执行”“有清单”“引用历史数据”等评价性结论，不能作为正分 evidence；这种 checkpoint 必须改为 0 或降为只给已被原文短引支撑的部分。
- 如果 evidence 需要同时证明两个对象的对应关系（例如提交值与附件真值、公式与历史数据、案例与定义、清单项与阶段要求），必须同时引用这两个对象。只引用提交本身，不引用对应附件/真值/定义的，不能给满分。
- 对历史数据/CSV/Excel 附件相关 checkpoint，正分 evidence 必须包含附件文件名、行号或 case_id、字段名和字段值，例如 `historical_failed_cases.csv F03 due_diligence_score=0.7`；只写“使用历史失败数据”“历史均值0.40”“来自附件”不够，除非同时列出用于计算的行和值。
- 对“校准前后参数对比”，必须引用同一个参数的 before 值和 after 值，以及导致变化的数据依据。只有校准方法、最终阈值或历史均值，没有 before/after 同参对比时，该 detail 不得给分。

示例：
- 可给分 evidence: `公众号成品.pdf 第3页“带电作业员...绝缘斗臂车...不停电抢修”；真值验证表.xlsx Sheet1 row 4 将带电作业列为天津官方保电岗位。`
- 不可给分 evidence: `提交覆盖了带电作业并符合官方材料。`

视觉、附件和抽检类规则必须额外严格：
- 如果规则要求检查图片、截图、PPT页面、Excel嵌入图片、附件中的参考成品、或“随机抽检/抽样检查”，给分 evidence 必须列出实际检查过的样本位置、`visual_assets_manifest.json` 中的 `asset_path`（如适用）和观察结果，例如 `分镜表.xlsx row 12/37/58 场景画面，对应 visual_assets/xlsx_...png：主体、动作、环境均与画面描述一致`，或 `课程PPT.pdf 第10/24/45页：每页包含标题、案例图、步骤说明和练习`。
- 不得用“未发现问题”“整体一致”“图片清晰”“可抽检”“看起来符合”等负证据或概括判断给满分。没有列出具体样本、页码、行号、图片/页面观察结果时，视觉/抽检 detail 视为证据不足，不给该 detail 分。
- 如果 rubrics.json 中有 max_score=0 的执行约束、真实性约束、否决说明或评分说明，不要因为它“不单独计分”就忽略。必须把其中的真实性、EXIF、来源可核验、抽查比例、抄袭/同质化、图片标注等约束应用到相关有分规则。
- 对“实拍、真实案例图、原创图片、拍摄案例、EXIF、拍摄场景可核验、图片来源真实”类要求，图片存在、图片清晰、PPT嵌图存在、配有说明文字，只能证明“有配图”，不能证明“实拍/真实/原创”。只有看到 EXIF、拍摄设备/时间/地点、原图文件、拍摄过程记录、可核验来源或评分附件明确认可的真实案例来源，才可给真实性/实拍相关得分。没有这些证据时，相关 detail 不得满分；如果该 detail 的核心就是实拍真实性，给 0。
- 对构图、摄影、分镜、视觉案例等规则，若评分要求“真实案例/实拍案例”而提交只有无法核验来源的示意图或嵌图，最多只能给构图名称、文字说明、教学解释等非真实性部分；不得把“有案例图”直接当成“有实拍案例图”。
- 对视觉/抽检 detail，`evidence` 或 `reason` 中只写“抽查样本显示”“多处图片”“整体配图”“可见图解”“案例图较多”“未发现问题”等概括语，且没有明确的页码、行号、slide编号、图片编号或样本编号时，必须在最终自查阶段把该 detail 改为 0 分。不要把这种证据格式当作合格证据。
- 如果无法读取图片、PPT页面、Excel嵌入图片或参考附件的视觉内容，必须在 evidence 中写明读取失败，并对依赖该视觉内容的得分点给 0；不得仅凭文件存在、文件名、表格行数或提交自述给分。
- 如果规则要求“逐页/逐行/全部图片/全部题目”核查，必须给出总数、抽查或全量核查方法、以及关键缺失/命中样本；不能只写“全覆盖”“均满足”。
- 视觉抽检必须有界完成，避免全量逐图阅读导致无法输出。除非评分规则明确要求全量逐图核验并且图像数量很小，否则先读取 `visual_assets/contact_sheet.jpg` 或 `visual_assets/sampled_contact_sheet.jpg`，再抽查 3-5 个能代表得分判断的具体样本；若这 3-5 个样本已经足以证明严重不符、缺失或重复，即可据此扣分/触发源规则中的否决。对于图片数量、缺失率、重复率这类统计项，优先用脚本/manifest/文件数量计算，再抽样核对内容。若 `asset_count` 很大，禁止打印全部图片列表、逐个 `identify` 全部图片、逐张 OCR/读取全部嵌图；这类全量操作会导致无法稳定输出，必须改用 manifest 里的总数和样本。
- 如果时间或上下文不足以完成视觉细项，必须保守输出 JSON：已核实的缺陷照常扣分；未能核实的视觉得分点按证据不足给 0。不得因为工作量大而不输出 JSON。

### 步骤 5：自查并输出
评完后回顾一遍：
- `scores` 是否覆盖了 `rubrics.json.rules` 中每一个 rule_id，且没有额外 rule_id
- 每条 `max_score` 是否与 JSON 完全一致
- `raw_total` 是否等于所有 rule score 之和（包含 penalty 负分）
- `max_total` 是否等于所有 additive/deductive rule 的 max_score 之和；penalty rule 的 max_score 是最多扣分，不计入 max_total
- reason 是否引用了提交中的具体内容和必要的评分依据；不能只复述规则或提交自述
- 视觉/抽检类给分是否列出了具体页码/行号/slide编号/图片编号/样本编号；如果没有，回到对应 detail 改为 0 分后再输出
- PPT/Word/Excel 可视化/结构化类 rule/detail 是否真的由结构清单中的 table/picture/chart/shape/formula 等客观对象支撑；如果只是 bullet 文本或章节标题，回到对应 detail 扣分
- 必须明说的标准口径是否被模糊表述替代；如果是，回到对应 detail 扣分
- 深度分析类 rule/detail 是否只是标题齐全或模板话术复用；如果没有逐项具体机制、条款、数据、案例或时间节点，回到对应 detail 扣分
- 实拍/真实性/EXIF/来源可核验类 rule/detail 是否只有“图片存在”或“图文说明”；如果没有 provenance 证据，回到对应 detail 扣分
- 阈值依据、权重依据、历史数据校准、模板类 rule/detail 是否只有结论或原则，没有可复核推导/模板对象；如果是，回到对应 detail 扣分
- 清单/检查项/Checklist 类 detail 的 evidence 是否只引用维度权重或权重表；如果是，回到该 detail 给 0
- 任意满分 rule 是否存在一个 scoring_detail 的 evidence 只有评价性结论、缺少原文短引、缺少附件行级依据、或只证明“看起来相关”；如果是，回到该 detail 扣分
- 对所有 score >= max_score 的 rule，先主动寻找一个最强反例：缺失的并列条件、格式不符、附件未引用、定义未满足、模板对象缺失、before/after 缺失、case_id/字段值缺失。只要反例成立，就不能满分
- 枚举型规则是否漏掉明确列名类别或条目，例如学术文献类别、标准中英文译名、指定机构/制度/案例字段；如果有漏项，回到该 rule/detail 扣分

修正后输出最终 JSON。

## 输出格式

最终必须输出一个 ```json 包裹的 JSON block：

```json
{{
  "veto_triggered": false,
  "veto_reason": null,
  "summary": "给做题 agent 的一次性高层反馈",
  "scores": [
    {{
      "rule_id": "R001",
      "rule_name": "规则名称",
      "scoring_mode": "additive",
      "checkpoint_scores": [
        {{
          "description": "子得分点描述",
          "score": 0,
          "max_score": 1,
          "evidence": "提交和评分依据中的具体证据；无证据时写明缺失"
        }}
      ],
      "score": 2,
      "max_score": 2,
      "rule_veto_triggered": false,
      "veto_reason": "",
      "reason": "评分理由（引用具体证据）"
    }}
  ],
  "raw_total": 48,
  "max_total": 60
}}
```

规则：
1. rule_id: 必须使用 rubrics.json 中的 rule_id
2. score: additive/deductive rule 必须在 [0, max_score] 范围内；penalty rule 必须在 [-max_score, 0] 范围内
3. max_score: 必须与 rubrics.json 中该 rule 的 max_score 一致
4. checkpoint_scores: 如果该 rule 有 scoring_details，必须逐 detail 返回一项。additive detail 的 score 是 0 或该 detail 的 points；deductive/penalty detail 的 score 是该 detail 实际扣掉的正数。若 detail 是“每有/每出现/每缺失/每错误/每超出/每累计/按差额每”这类可重复扣分项，checkpoint 的 score 必须是 `points × 命中次数`，可以大于该 detail 的单次 points；max_score 可写单次 points 或实际累计扣分，后处理会按可重复扣分语义保留累计值。
4a. 如果 rule 是 deductive，rule score 必须是 `max_score - min(sum(triggered deduction scores), rule.max_score)`；不要输出负数。
4b. 如果 rule 是 penalty，rule score 必须是负数或 0：`-min(sum(triggered deduction scores), rule.max_score)`；不要按正向 detail 加分，也不要从 rule.max_score 开始扣。
5. `veto_triggered` 是兼容旧结果的全局字段，通常保持 false。不要因为某条 rule 的 `veto_conditions` 命中而设置顶层 `veto_triggered=true`；rule-level veto 只让对应 rule 记 0 分，并写入该 rule reason。不得自行发明全局 veto。
5a. 如果某条 additive/deductive rule 命中 `veto_conditions`，该 score object 必须设置 `rule_veto_triggered=true`、`veto_reason` 写明触发条件；该 rule 的 `score` 必须为 0。penalty rule 不应触发 rule-level veto。
6. raw_total = 所有 scores 中 score 之和
7. max_total = 所有 additive/deductive scores 中 max_score 之和；penalty rule 的 max_score 是最多扣分，不计入 max_total
8. 务必覆盖 rubrics.json.rules 中每一条，不要遗漏
9. reason 必须引用提交内容中的具体文字或指出具体缺失，不能泛泛说"不够好"
10. summary 是给做题 agent 看的本次提交唯一反馈，必须是 15-20 token 左右的一句话高层修改方向：
    - 只能基于 task_instruction.md 的任务目标、交付物要求、输入材料使用方式和提交整体形态来概括
    - 不要按单条 rubric 生成反馈，不要提 rule_id、rubric 名称、评分项名称、checkpoint、评分附件、隐藏标准或评分依据
    - 不要泄露隐藏答案、参考答案、真值、URL、页码、行号、sheet 名、具体公式、精确数值或百分比
    - 不要列举完整缺失清单，不要写“应包含 A/B/C/D”
    - 不能照抄 reason/evidence；要抽象成任务级改进方向
    - 合格示例：请先补齐任务要求的主要交付内容，再完善整体说明和依据。
    - 合格示例：请围绕任务目标加强内容覆盖、结构组织和可复核证据。
    - 不合格示例：缺少 R003 的三个标准频点、参考答案第 3 页不一致、未包含某评分表指定真值

## 严格要求

- 评分必须严格按照规则标准，不主观增减
- 采用保守严格判分：没有明确证据证明满足的得分点不给分；模糊、含混、可给可不给的情况一律不给分
- rubrics.json 是唯一 authoritative source；不得使用其他文件替代规则来源
- 评分附件是真值/参考依据来源；当 JSON 规则依赖附件真值时，必须读附件，读不到就不得宽判
- 视觉/附件/抽检项必须基于实际读取的可定位样本；不能用“未发现问题”替代正向证据
- 如果提交是明显的占位/骨架（含"待补充""占位"等），相关实质规则必须给 0 分
- 如果提交引用了外部 URL，你可以 curl 验证其真实性
- 最终只输出 JSON block，不要有其他多余文字
"""


def build_codex_prompt(rubrics_text: str, submission_text: str, input_text: str = "",
                       scoring_dir: str = "", input_dir: str = "", report_path: str = "",
                       submission_manifest: str = "", visual_manifest: str = "",
                       structure_manifest: str = "") -> str:
    # 不再嵌入全文——让 codex agent 自己读文件
    # 只在 prompt 里给路径和简要概述
    return CODEX_GRADING_PROMPT.format(
        rubrics_json=str(Path(scoring_dir or "/home/workspace/scoring") / "rubrics.json"),
        scoring_dir=scoring_dir or "/home/workspace/scoring",
        report_path=report_path or "/home/workspace/report.md",
        input_dir=input_dir or "/home/workspace/input",
        submission_manifest=submission_manifest or "/home/workspace/submission_manifest.json",
        visual_manifest=visual_manifest or "/home/workspace/visual_assets_manifest.json",
        structure_manifest=structure_manifest or "/home/workspace/submission_structure_manifest.json",
    )


# ---------------------------------------------------------------------------
# Submission and evidence manifests
# ---------------------------------------------------------------------------

EXCLUDED_SUBMISSION_PARTS = {
    ".git",
    "__pycache__",
    "input",
    "scoring",
}
EXCLUDED_SUBMISSION_FILES = {
    "grade_with_codex.py",
    "grading_result.json",
    "submission_manifest.json",
    "submission_structure_manifest.json",
    "visual_assets_manifest.json",
}


def _is_submission_relpath(path: Path) -> bool:
    if any(part in EXCLUDED_SUBMISSION_PARTS for part in path.parts):
        return False
    if path.name in EXCLUDED_SUBMISSION_FILES:
        return False
    if path.name.startswith("."):
        return False
    return True


def _count_xlsx_formulas(path: Path) -> int:
    """Count formula cells without importing openpyxl inside minimal images."""
    try:
        count = 0
        with zipfile.ZipFile(path) as zf:
            for name in zf.namelist():
                if name.startswith("xl/worksheets/") and name.endswith(".xml"):
                    data = zf.read(name)
                    count += data.count(b"<f") + data.count(b"<x:f")
        return count
    except Exception:
        return -1


def _load_expected_outputs(input_dir: Path | None) -> list[dict]:
    if not input_dir:
        return []
    meta_path = input_dir / "task_instruction.meta.json"
    if not meta_path.is_file():
        return []
    try:
        meta = json.loads(meta_path.read_text(encoding="utf-8", errors="replace"))
    except Exception:
        return []
    outputs = meta.get("outputs")
    if isinstance(outputs, list) and outputs:
        clean = []
        for item in outputs:
            if isinstance(item, dict) and str(item.get("path") or "").strip():
                clean.append({
                    "path": str(item.get("path")).strip(),
                    "format": str(item.get("format") or "").strip(),
                })
        if clean:
            return clean
    submit_paths = meta.get("submit_paths")
    if isinstance(submit_paths, list):
        return [
            {"path": str(path).strip(), "format": ""}
            for path in submit_paths
            if str(path).strip() and str(path).strip() != "."
        ]
    return []


def _split_expected_path_variants(path: str) -> list[str]:
    """Handle renderer output like "report.docx 或 report.pdf"."""
    text = path.strip()
    if not text:
        return []
    parts = re.split(r"\s+(?:或|or|OR)\s+", text)
    variants = [part.strip().strip("`'\"") for part in parts if part.strip()]
    return variants or [text]


def _path_match_key(path: str) -> str:
    return path.strip().replace("\\", "/").lstrip("./").lower()


def _path_stem_key(path: str) -> str:
    key = _path_match_key(path)
    p = Path(key)
    parent = p.parent.as_posix()
    stem = p.stem
    return f"{parent}/{stem}" if parent and parent != "." else stem


def build_submission_manifest(report_path: Path, input_dir: Path | None) -> dict:
    expected = _load_expected_outputs(input_dir)
    base = report_path if report_path.is_dir() else report_path.parent
    actual: list[dict] = []
    if report_path.is_file():
        files = [report_path]
    else:
        files = [
            p for p in sorted(report_path.rglob("*"))
            if p.is_file() and _is_submission_relpath(p.relative_to(base))
        ]
    for path in files:
        try:
            rel = path.relative_to(base).as_posix()
        except ValueError:
            rel = path.name
        item = {
            "path": rel,
            "size": path.stat().st_size,
            "suffix": path.suffix.lower(),
        }
        if path.suffix.lower() == ".xlsx":
            item["xlsx_formula_count"] = _count_xlsx_formulas(path)
        actual.append(item)

    actual_by_path = {_path_match_key(str(item["path"])): item for item in actual}
    actual_by_stem: dict[str, list[dict]] = {}
    for item in actual:
        actual_by_stem.setdefault(_path_stem_key(str(item["path"])), []).append(item)

    expected_clean = [
        item for item in expected
        if str(item.get("path") or "").strip() and str(item.get("path")).strip() != "."
    ]
    missing = []
    present = []
    matched = []
    format_mismatches = []
    for item in expected_clean:
        path = str(item.get("path") or "").strip()
        variants = _split_expected_path_variants(path)
        exact = None
        stem_match = None
        for variant in variants:
            exact = actual_by_path.get(_path_match_key(variant))
            if exact:
                break
        if not exact:
            for variant in variants:
                matches = actual_by_stem.get(_path_stem_key(variant)) or []
                if matches:
                    stem_match = matches[0]
                    break

        if exact:
            present.append(path)
            matched.append({"expected": path, "actual": exact["path"], "match_type": "exact_or_alternative"})
        elif stem_match:
            present.append(path)
            matched.append({"expected": path, "actual": stem_match["path"], "match_type": "same_stem_different_format"})
            format_mismatches.append({"expected": path, "actual": stem_match["path"]})
        else:
            missing.append(path)

    name_mismatches = []
    if expected_clean and missing and len(missing) == len(expected_clean) and len(actual) >= len(expected_clean):
        missing = []
        present = [str(item.get("path") or "").strip() for item in expected_clean]
        matched = []
        for item, actual_item in zip(expected_clean, actual):
            expected_path = str(item.get("path") or "").strip()
            matched.append({
                "expected": expected_path,
                "actual": actual_item["path"],
                "match_type": "same_count_name_mismatch",
            })
            name_mismatches.append({"expected": expected_path, "actual": actual_item["path"]})

    return {
        "expected_outputs": expected,
        "actual_files": actual,
        "present_expected_outputs": present,
        "missing_expected_outputs": missing,
        "matched_expected_outputs": matched,
        "format_mismatches": format_mismatches,
        "name_mismatches": name_mismatches,
    }


IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".tif", ".tiff"}
OFFICE_MEDIA_PREFIXES = ("xl/media/", "ppt/media/", "word/media/")


def _safe_asset_name(text: str) -> str:
    safe = re.sub(r"[^A-Za-z0-9_.-]+", "_", text.strip())
    return safe[:120] or "asset"


def _iter_submission_files(report_path: Path) -> list[Path]:
    base = report_path if report_path.is_dir() else report_path.parent
    if report_path.is_file():
        return [report_path]
    return [
        p for p in sorted(report_path.rglob("*"))
        if p.is_file() and _is_submission_relpath(p.relative_to(base))
    ]


def build_visual_assets_manifest(report_path: Path, out_dir: Path) -> dict:
    """Extract visual assets for the judge to reference; this does not score."""
    out_dir.mkdir(parents=True, exist_ok=True)
    base = report_path if report_path.is_dir() else report_path.parent
    assets: list[dict] = []
    for source in _iter_submission_files(report_path):
        try:
            rel = source.relative_to(base).as_posix()
        except ValueError:
            rel = source.name
        suffix = source.suffix.lower()
        if suffix in IMAGE_SUFFIXES:
            dst_name = f"{len(assets)+1:04d}_{_safe_asset_name(rel)}"
            dst = out_dir / dst_name
            try:
                shutil.copy2(source, dst)
                assets.append({"source_file": rel, "asset_path": dst.as_posix(), "kind": "image_file", "size": dst.stat().st_size})
            except Exception as exc:
                assets.append({"source_file": rel, "kind": "image_file", "error": str(exc)})
            continue

        if suffix in {".xlsx", ".xlsm", ".pptx", ".docx"}:
            try:
                with zipfile.ZipFile(source) as zf:
                    for member in zf.namelist():
                        if not member.startswith(OFFICE_MEDIA_PREFIXES):
                            continue
                        member_suffix = Path(member).suffix.lower()
                        if member_suffix not in IMAGE_SUFFIXES:
                            continue
                        dst_name = f"{len(assets)+1:04d}_{_safe_asset_name(rel)}__{_safe_asset_name(member)}"
                        if not Path(dst_name).suffix:
                            dst_name += member_suffix
                        dst = out_dir / dst_name
                        try:
                            dst.write_bytes(zf.read(member))
                            assets.append({
                                "source_file": rel,
                                "asset_path": dst.as_posix(),
                                "kind": "office_embedded_image",
                                "zip_member": member,
                                "size": dst.stat().st_size,
                            })
                        except Exception as exc:
                            assets.append({"source_file": rel, "kind": "office_embedded_image", "zip_member": member, "error": str(exc)})
            except Exception as exc:
                assets.append({"source_file": rel, "kind": "office_archive", "error": str(exc)})

    contact_sheet = None
    sampled_contact_sheet = None
    real_assets = [a for a in assets if a.get("asset_path") and not a.get("error")]
    asset_count = len(real_assets)
    max_manifest_assets = int(os.environ.get("SEBENCH_VISUAL_MANIFEST_MAX_ASSETS", "40"))
    max_contact_assets = int(os.environ.get("SEBENCH_VISUAL_CONTACT_SHEET_MAX_ASSETS", "80"))
    if asset_count > max_manifest_assets:
        sample_indexes = sorted({
            round(i * (asset_count - 1) / max(1, max_manifest_assets - 1))
            for i in range(max_manifest_assets)
        })
        sampled_assets = [real_assets[i] for i in sample_indexes]
    else:
        sampled_assets = real_assets
    sampled_paths = {item.get("asset_path") for item in sampled_assets}
    if asset_count > max_manifest_assets:
        # Keep the judge from accidentally enumerating hundreds of extracted
        # visual files and overflowing the model context. The manifest preserves
        # the true total count and a representative sample.
        for item in real_assets:
            path = item.get("asset_path")
            if path and path not in sampled_paths:
                try:
                    Path(path).unlink()
                except Exception:
                    pass
    if sampled_assets:
        try:
            from PIL import Image, ImageDraw  # type: ignore
            thumbs = []
            for idx, item in enumerate(sampled_assets[:max_contact_assets], start=1):
                img = Image.open(item["asset_path"]).convert("RGB")
                img.thumbnail((160, 120))
                tile = Image.new("RGB", (180, 150), "white")
                tile.paste(img, ((180 - img.width) // 2, 5))
                draw = ImageDraw.Draw(tile)
                draw.text((5, 128), f"{idx}: {Path(item['asset_path']).name[:24]}", fill=(0, 0, 0))
                thumbs.append(tile)
            cols = 4
            rows = (len(thumbs) + cols - 1) // cols
            sheet = Image.new("RGB", (cols * 180, rows * 150), "white")
            for i, tile in enumerate(thumbs):
                sheet.paste(tile, ((i % cols) * 180, (i // cols) * 150))
            contact_path = out_dir / "contact_sheet.jpg"
            sheet.save(contact_path, quality=85)
            contact_sheet = contact_path.as_posix()
            sampled_contact_sheet = contact_sheet
        except Exception as exc:
            contact_sheet = f"ERROR: {exc}"

    return {
        "visual_assets_dir": out_dir.as_posix(),
        "asset_count": asset_count,
        "manifest_asset_count": len(sampled_assets),
        "assets_truncated": asset_count > len(sampled_assets),
        "contact_sheet": contact_sheet,
        "sampled_contact_sheet": sampled_contact_sheet,
        "sampled_assets": sampled_assets,
        "assets": sampled_assets,
    }


def _inspect_pptx_structure(path: Path) -> dict:
    info = {
        "slides": 0,
        "tables": 0,
        "pictures": 0,
        "charts": 0,
        "groups": 0,
        "text_shapes": 0,
        "slides_with_visual_objects": 0,
        "slide_summaries": [],
    }
    try:
        from pptx import Presentation  # type: ignore
        prs = Presentation(str(path))
        info["slides"] = len(prs.slides)
        for idx, slide in enumerate(prs.slides, start=1):
            slide_info = {
                "slide": idx,
                "tables": 0,
                "pictures": 0,
                "charts": 0,
                "groups": 0,
                "text_shapes": 0,
                "shapes": len(slide.shapes),
            }
            for shape in slide.shapes:
                if getattr(shape, "has_table", False):
                    slide_info["tables"] += 1
                    info["tables"] += 1
                if getattr(shape, "has_chart", False):
                    slide_info["charts"] += 1
                    info["charts"] += 1
                shape_type = str(getattr(shape, "shape_type", ""))
                if "PICTURE" in shape_type:
                    slide_info["pictures"] += 1
                    info["pictures"] += 1
                if "GROUP" in shape_type:
                    slide_info["groups"] += 1
                    info["groups"] += 1
                if getattr(shape, "has_text_frame", False):
                    text = getattr(shape, "text", "") or ""
                    if text.strip():
                        slide_info["text_shapes"] += 1
                        info["text_shapes"] += 1
            if slide_info["tables"] or slide_info["pictures"] or slide_info["charts"] or slide_info["groups"]:
                info["slides_with_visual_objects"] += 1
            info["slide_summaries"].append(slide_info)
    except Exception as exc:
        info["error"] = str(exc)
    return info


def _inspect_docx_structure(path: Path) -> dict:
    info = {"paragraphs": 0, "tables": 0, "inline_shapes": 0}
    try:
        from docx import Document  # type: ignore
        doc = Document(str(path))
        info["paragraphs"] = sum(1 for p in doc.paragraphs if p.text.strip())
        info["tables"] = len(doc.tables)
        info["inline_shapes"] = len(doc.inline_shapes)
    except Exception as exc:
        info["error"] = str(exc)
    return info


def _inspect_xlsx_structure(path: Path) -> dict:
    info = {
        "sheets": [],
        "sheet_count": 0,
        "formula_count": _count_xlsx_formulas(path),
        "embedded_image_count": 0,
    }
    try:
        with zipfile.ZipFile(path) as zf:
            info["embedded_image_count"] = sum(1 for name in zf.namelist() if name.startswith("xl/media/"))
    except Exception as exc:
        info["zip_error"] = str(exc)
    try:
        import openpyxl  # type: ignore
        wb = openpyxl.load_workbook(path, data_only=False, read_only=False)
        info["sheet_count"] = len(wb.worksheets)
        for ws in wb.worksheets:
            non_empty = 0
            for row in ws.iter_rows():
                for cell in row:
                    if cell.value not in (None, ""):
                        non_empty += 1
            info["sheets"].append({
                "name": ws.title,
                "max_row": ws.max_row,
                "max_column": ws.max_column,
                "non_empty_cells": non_empty,
            })
    except Exception as exc:
        info["workbook_error"] = str(exc)
    return info


def build_structure_manifest(report_path: Path) -> dict:
    files = []
    base = report_path if report_path.is_dir() else report_path.parent
    for source in _iter_submission_files(report_path):
        try:
            rel = source.relative_to(base).as_posix()
        except ValueError:
            rel = source.name
        suffix = source.suffix.lower()
        entry = {"path": rel, "suffix": suffix, "size": source.stat().st_size}
        if suffix == ".pptx":
            entry["structure"] = _inspect_pptx_structure(source)
        elif suffix == ".docx":
            entry["structure"] = _inspect_docx_structure(source)
        elif suffix in {".xlsx", ".xlsm"}:
            entry["structure"] = _inspect_xlsx_structure(source)
        files.append(entry)
    return {"files": files}


def write_grading_result(payload: dict) -> None:
    try:
        detail_path = Path(os.environ.get("SEBENCH_GRADE_RESULT_JSON", "grading_result.json"))
        detail_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    except Exception as e:
        sys.stderr.write(f"[grader] WARNING: could_not_write_grading_result_json={e}\n")


GRADING_RESULT_JSON_START = "<<<SEBENCH_GRADING_RESULT_JSON_START>>>"
GRADING_RESULT_JSON_END = "<<<SEBENCH_GRADING_RESULT_JSON_END>>>"


def emit_grading_result_marker(payload: dict) -> None:
    """Emit the full grading result into judge logs for host-only postprocessing."""
    try:
        print(GRADING_RESULT_JSON_START)
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        print(GRADING_RESULT_JSON_END)
    except Exception as e:
        sys.stderr.write(f"[grader] WARNING: could_not_emit_grading_result_json={e}\n")


# ---------------------------------------------------------------------------
# Codex invocation
# ---------------------------------------------------------------------------

def invoke_codex(prompt: str, timeout: int = 600) -> str:
    """Run codex exec and return its stdout output.

    Uses the user's local ~/.codex/config.toml for base_url and auth.
    If no config exists (e.g. inside judge container), creates one pointing
    to SFORGE_JUDGE_API_BASE_URL (or CODEX_BASE_URL), which defaults to OpenRouter.
    """
    codex_path = ensure_codex_installed()

    # Ensure config.toml exists (needed inside judge containers). The judge
    # container is ephemeral, so writing the API key into this local config as
    # an env_key reference is acceptable and avoids host-specific assumptions.
    codex_home = Path.home() / ".codex"
    config_file = codex_home / "config.toml"
    api_key = (
        os.environ.get("SFORGE_JUDGE_API_KEY")
        or os.environ.get("OPENROUTER_API_KEY")
        or os.environ.get("BRIDGE_API_KEY")
        or ""
    )
    if not api_key:
        raise RuntimeError("No API key: set SFORGE_JUDGE_API_KEY in container env")
    base_url = os.environ.get("SFORGE_JUDGE_API_BASE_URL") or os.environ.get("CODEX_BASE_URL") or DEFAULT_CODEX_BASE_URL
    key_env = "OPENROUTER_API_KEY" if "openrouter.ai" in base_url else "BRIDGE_API_KEY"
    provider = "openrouter" if "openrouter.ai" in base_url else "proxy"
    provider_name = "OpenRouter" if provider == "openrouter" else "Codex-compatible"
    if not config_file.exists():
        codex_home.mkdir(parents=True, exist_ok=True)
        model = (
            os.environ.get("SFORGE_JUDGE_MODEL")
            or os.environ.get("SEBENCH_JUDGE_MODEL")
            or ""
        ).strip()
        if not model:
            raise RuntimeError(
                "No judge model configured and no Codex config.toml exists; "
                "set SFORGE_JUDGE_MODEL or pass --judge-model from the workflow"
            )
        config_file.write_text(
            f'model = "{model}"\n'
            f'model_provider = "{provider}"\n'
            f'model_reasoning_effort = "medium"\n\n'
            f'[model_providers.{provider}]\n'
            f'name = "{provider_name}"\n'
            f'base_url = "{base_url}"\n'
            f'wire_api = "responses"\n'
            f'env_key = "{key_env}"\n'
        )
        sys.stderr.write(f"[codex-judge] Created Codex config.toml (model={model}, base_url={base_url})\n")

    with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
        f.write(prompt)
        prompt_file = f.name

    try:
        model = (
            os.environ.get("SFORGE_JUDGE_MODEL")
            or os.environ.get("SEBENCH_JUDGE_MODEL")
            or ""
        ).strip()
        cmd = [
            codex_path, "exec",
        ]
        if model:
            cmd += ["-m", model]
        cmd += [
            "--dangerously-bypass-approvals-and-sandbox",
            "--skip-git-repo-check",
            "-",  # read prompt from stdin
        ]

        env = os.environ.copy()
        env[key_env] = api_key
        env["SFORGE_JUDGE_API_KEY"] = api_key
        env["BRIDGE_API_KEY"] = api_key
        if "openrouter.ai" in base_url:
            env["OPENROUTER_API_KEY"] = api_key
        no_proxy = env.get("NO_PROXY") or env.get("no_proxy") or ""
        base_host = base_url.split("://", 1)[-1].split("/", 1)[0].split(":", 1)[0]
        items = ["127.0.0.1", "localhost", "::1"]
        if base_host and base_host != "openrouter.ai" and not base_host.endswith(".openrouter.ai"):
            items.insert(0, base_host)
        env["NO_PROXY"] = ",".join(items + ([no_proxy] if no_proxy else []))
        env["no_proxy"] = env["NO_PROXY"]

        model_label = model or "codex_config"
        sys.stderr.write(f"[codex-judge] model={model_label}, timeout={timeout}s\n")
        sys.stderr.write(f"[codex-judge] provider={provider_name}\n")
        sys.stderr.write(f"[codex-judge] base_url={base_url}\n")
        # Read prompt and pass via stdin (avoids ARG_MAX for large prompts).
        with open(prompt_file, "r") as pf:
            prompt_content = pf.read()

        transient_markers = (
            "stream disconnected before completion",
            "stream closed before response.completed",
            "Reconnecting...",
        )
        attempts = max(1, int(os.environ.get("SEBENCH_CODEX_JUDGE_RETRIES", "2")) + 1)
        last_result = None
        for attempt in range(1, attempts + 1):
            sys.stderr.write(f"[codex-judge] Running codex attempt {attempt}/{attempts}...\n")
            result = subprocess.run(
                cmd,
                input=prompt_content,
                capture_output=True, text=True, timeout=timeout, env=env,
                start_new_session=True,
            )
            last_result = result

            sys.stderr.write(f"[codex-judge] codex exit code: {result.returncode}\n")
            if result.stderr:
                sys.stderr.write(f"[codex-judge] stderr (last 500): {result.stderr[-500:]}\n")

            if result.returncode == 0:
                return result.stdout

            stderr = result.stderr or ""
            is_transient = any(marker in stderr for marker in transient_markers)
            if not is_transient or attempt >= attempts:
                break
            wait_s = min(60, 10 * attempt)
            sys.stderr.write(
                f"[codex-judge] transient codex failure; retrying ({attempt}/{attempts - 1}) after {wait_s}s\n"
            )
            time.sleep(wait_s)

        assert last_result is not None
        raise RuntimeError(
            f"Codex exited with code {last_result.returncode}: {(last_result.stderr or '')[-300:]}"
        )
    finally:
        os.unlink(prompt_file)


# ---------------------------------------------------------------------------
# Output parsing
# ---------------------------------------------------------------------------

def extract_json_from_output(output: str) -> dict | None:
    """Extract JSON scoring result from codex output with validation."""
    # Try ```json block first (case-insensitive, flexible whitespace)
    pattern = r"```(?:json|JSON)?\s*\n(.*?)\n\s*```"
    matches = re.findall(pattern, output, re.DOTALL)
    if matches:
        for match in reversed(matches):
            result = _try_parse_and_validate(match)
            if result:
                return result

    # Fallback: find JSON with raw_decode from last { onwards
    decoder = json.JSONDecoder()
    for i in range(len(output) - 1, -1, -1):
        if output[i] == "{":
            try:
                obj, _ = decoder.raw_decode(output, i)
                if isinstance(obj, dict) and "scores" in obj:
                    return _validate_result(obj)
            except (json.JSONDecodeError, ValueError):
                continue

    return None


def _try_parse_and_validate(text: str) -> dict | None:
    try:
        obj = json.loads(text)
        if isinstance(obj, dict) and "scores" in obj:
            return _validate_result(obj)
    except (json.JSONDecodeError, ValueError):
        pass
    return None


def _truthy(value: object) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes", "y", "是", "命中", "触发"}
    return bool(value)


def _rule_level_veto_triggered(src: dict, rule: dict, scoring_mode: str, checkpoint_scores: list) -> bool:
    """Detect a rule-level veto without confusing normal deductive scoring."""
    if scoring_mode not in {"additive", "deductive"}:
        return False
    veto_conditions = rule.get("veto_conditions")
    if not isinstance(veto_conditions, list) or not veto_conditions:
        return False
    if _truthy(src.get("rule_veto_triggered")) or _truthy(src.get("veto_triggered")):
        return True

    text = " ".join(str(part or "") for part in (src.get("veto_reason"), src.get("reason")))
    condition_hit = any(str(cond).strip() and str(cond).strip() in text for cond in veto_conditions)
    if condition_hit:
        return True

    veto_reason = str(src.get("veto_reason") or "")
    marker_hit = any(marker in text for marker in ("veto", "否决", "不合格", "不得通过", "触发"))
    veto_reason_marker_hit = any(marker in veto_reason for marker in ("veto", "否决", "不合格", "不得通过", "触发"))
    if veto_reason_marker_hit:
        return True

    raw_score = src.get("score")
    if not isinstance(raw_score, (int, float)) or abs(float(raw_score)) > 1e-9:
        return False
    if checkpoint_scores:
        for cp in checkpoint_scores:
            if isinstance(cp, dict) and isinstance(cp.get("score", 0), (int, float)) and abs(float(cp.get("score", 0))) > 1e-9:
                return False

    return marker_hit


def _is_repeatable_deduction_detail(description: str) -> bool:
    text = re.sub(r"\s+", "", str(description or ""))
    return any(
        marker in text
        for marker in (
            "每有",
            "每出现",
            "每缺失",
            "每错误",
            "每遗漏",
            "每少",
            "每多",
            "每超出",
            "每累计",
            "每填报",
            "按差额每",
        )
    )


def _reason_declares_deductive_floor(reason: str) -> bool:
    """Detect a Codex result that says a deductive rule should be floored at 0.

    Codex sometimes writes the correct natural-language conclusion for a
    repeatable deduction ("deductions exceed the rule max, floor at 0") while
    reporting per-detail checkpoint scores on the single-occurrence scale.  The
    reconciliation step is responsible for making the structured score match
    that declared capped-deduction conclusion.
    """
    text = re.sub(r"\s+", "", str(reason or ""))
    if re.search(r"(?:累计|合计|总计)?扣分(?:已)?(?:超过|超出|远超)[^，。；;]*上限", text):
        return True
    if re.search(r"扣分(?:已|合计|累计|总计)?达到[^，。；;]*上限", text):
        return True
    if re.search(r"已达(?:到)?[^，。；;]*扣分上限", text):
        return True
    return any(
        marker in text
        for marker in (
            "扣至0",
            "扣至零",
            "本规则扣至0",
            "本规则得0",
            "本项得0",
            "规则得0",
            "扣分已超过",
            "扣分合计超过",
            "扣分超过",
            "扣分远超",
            "扣满",
            "已扣满",
        )
    )


def _validate_result(obj: dict) -> dict:
    """Validate and normalize the scoring result schema."""
    scores = obj.get("scores", [])
    validated_scores = []
    for s in scores:
        if not isinstance(s, dict):
            continue
        score = s.get("score", 0)
        max_score = s.get("max_score", 0)
        scoring_mode = str(s.get("scoring_mode") or "additive").strip().lower()
        if scoring_mode not in {"additive", "deductive", "penalty"}:
            scoring_mode = "additive"
        if not isinstance(score, (int, float)):
            score = 0
        if not isinstance(max_score, (int, float)):
            max_score = 0
        rule_veto_triggered = _truthy(s.get("rule_veto_triggered")) or _truthy(s.get("veto_triggered"))
        if scoring_mode == "penalty":
            score = max(-max_score, min(score, 0))
        else:
            score = max(0, min(score, max_score))
        if rule_veto_triggered and scoring_mode in {"additive", "deductive"}:
            score = 0
        checkpoint_scores = []
        for cp in s.get("checkpoint_scores", []) if isinstance(s.get("checkpoint_scores", []), list) else []:
            if not isinstance(cp, dict):
                continue
            cp_score = cp.get("score", 0)
            cp_max = cp.get("max_score", 0)
            if not isinstance(cp_score, (int, float)):
                cp_score = 0
            if not isinstance(cp_max, (int, float)):
                cp_max = 0
            # Keep the raw checkpoint deduction here.  Reconciliation has the
            # rubric detail text and can decide whether a deduction is
            # repeatable; capping at the single-occurrence max here would lose
            # "N occurrences * points" evidence before that decision point.
            cp_score = max(0, float(cp_score))
            cp_max = max(0, float(cp_max))
            checkpoint_scores.append({
                "description": str(cp.get("description", ""))[:160],
                "score": cp_score,
                "max_score": cp_max,
                "evidence": str(cp.get("evidence", ""))[:240],
            })
        validated_scores.append({
            "rule_id": str(s.get("rule_id", "?"))[:10],
            "rule_name": str(s.get("rule_name", "unknown"))[:80],
            "scoring_mode": scoring_mode,
            "checkpoint_scores": checkpoint_scores,
            "score": score,
            "max_score": max_score,
            "rule_veto_triggered": rule_veto_triggered if scoring_mode in {"additive", "deductive"} else False,
            "veto_reason": str(s.get("veto_reason", ""))[:200] if rule_veto_triggered else "",
            "reason": str(s.get("reason", ""))[:200],
        })

    # Recompute totals from validated scores
    raw_total = sum(s["score"] for s in validated_scores)
    max_total = sum(
        s["max_score"]
        for s in validated_scores
        if s.get("scoring_mode") in {"additive", "deductive"}
    )

    veto = bool(obj.get("veto_triggered", False))
    return {
        "veto_triggered": veto,
        "veto_reason": str(obj.get("veto_reason", "")) if veto else None,
        "summary": _sanitize_summary_feedback(obj.get("summary", "")),
        "scores": validated_scores,
        "raw_total": raw_total,
        "max_total": max_total,
    }


def load_rubrics_json(scoring_dir: Path) -> list[dict]:
    """Load the authoritative normalized rubric rules."""
    path = scoring_dir / "rubrics.json"
    if not path.is_file():
        raise FileNotFoundError(f"authoritative rubrics.json not found: {path}")
    data = json.loads(path.read_text(encoding="utf-8", errors="replace"))
    rules = data.get("rules") if isinstance(data, dict) else data
    if not isinstance(rules, list) or not rules:
        raise ValueError(f"rubrics.json has no non-empty rules array: {path}")
    for rule in rules:
        if not isinstance(rule, dict):
            raise ValueError("rubrics.json contains a non-object rule")
        if not re.fullmatch(r"R\d{3}", str(rule.get("rule_id", ""))):
            raise ValueError(f"invalid rule_id in rubrics.json: {rule.get('rule_id')!r}")
        if not isinstance(rule.get("max_score"), (int, float)):
            raise ValueError(f"non-numeric max_score for {rule.get('rule_id')}")
    return rules


def reconcile_result_with_rubrics(result: dict, rules: list[dict]) -> dict:
    """Force result coverage/order/max_score to match rubrics.json."""
    by_id = {str(s.get("rule_id")): s for s in result.get("scores", []) if isinstance(s, dict)}
    reconciled = []
    for rule in rules:
        rid = str(rule["rule_id"])
        max_score = float(rule["max_score"])
        src = by_id.get(rid) or {}
        scoring_mode = str(rule.get("scoring_mode") or "additive")
        details = rule.get("scoring_details") if isinstance(rule.get("scoring_details"), list) else []
        if not details and scoring_mode == "additive" and isinstance(rule.get("checkpoints"), list):
            details = [
                {"description": cp.get("description", ""), "points": cp.get("max_score", 0)}
                for cp in rule.get("checkpoints", [])
                if isinstance(cp, dict)
            ]
        if not details and scoring_mode in {"deductive", "penalty"} and isinstance(rule.get("deductions"), list):
            details = [
                {"description": d.get("description", ""), "points": d.get("points", 0)}
                for d in rule.get("deductions", [])
                if isinstance(d, dict)
            ]
        checkpoint_scores = src.get("checkpoint_scores") if isinstance(src.get("checkpoint_scores"), list) else []
        rule_veto_triggered = _rule_level_veto_triggered(src, rule, scoring_mode, checkpoint_scores)
        rule_veto_reason = str(src.get("veto_reason") or src.get("reason") or "")[:200] if rule_veto_triggered else ""
        if rule_veto_triggered:
            reconciled_checkpoints = []
            for idx, detail in enumerate(details):
                got = checkpoint_scores[idx] if idx < len(checkpoint_scores) and isinstance(checkpoint_scores[idx], dict) else {}
                try:
                    cp_max = float(detail.get("points", 0))
                except Exception:
                    cp_max = 0.0
                reconciled_checkpoints.append({
                    "description": str(detail.get("description", ""))[:160],
                    "score": 0.0,
                    "max_score": max(0.0, cp_max),
                    "evidence": str(got.get("evidence") or got.get("reason") or "")[:240],
                })
            score = 0.0
            checkpoint_reason = ""
        elif scoring_mode in {"deductive", "penalty"}:
            checkpoint_reason = ""
            reconciled_checkpoints = []
            deduction_total = 0.0
            raw_score = src.get("score")
            if details:
                checkpoint_iter = []
                for idx, detail in enumerate(details):
                    got = checkpoint_scores[idx] if idx < len(checkpoint_scores) and isinstance(checkpoint_scores[idx], dict) else {}
                    checkpoint_iter.append((detail, got))
            else:
                checkpoint_iter = [(None, cp) for cp in checkpoint_scores if isinstance(cp, dict)]
            for detail, cp in checkpoint_iter:
                detail_max = None
                detail_desc = ""
                if isinstance(detail, dict):
                    detail_desc = str(detail.get("description", ""))
                    try:
                        detail_max = float(detail.get("points", 0))
                    except Exception:
                        detail_max = 0.0
                cp_score = cp.get("score", 0)
                cp_max = detail_max if detail_max is not None else cp.get("max_score", 0)
                if not isinstance(cp_score, (int, float)):
                    cp_score = 0
                if not isinstance(cp_max, (int, float)):
                    cp_max = 0
                repeatable = _is_repeatable_deduction_detail(detail_desc or str(cp.get("description", "")))
                if repeatable:
                    cp_score = max(0.0, float(cp_score))
                    cp_max = max(float(cp_max), cp_score)
                else:
                    cp_score = max(0.0, min(float(cp_score), float(cp_max)))
                deduction_total += cp_score
                reconciled_checkpoints.append({
                    "description": (detail_desc or str(cp.get("description", "")))[:160],
                    "score": cp_score,
                    "max_score": max(0.0, float(cp_max)),
                    "evidence": str(cp.get("evidence") or cp.get("reason") or "")[:240],
                })
            if details and len(checkpoint_scores) < len(details):
                raw_deduction = None
                if isinstance(raw_score, (int, float)):
                    if scoring_mode == "deductive":
                        raw_score_num = max(0.0, min(float(raw_score), max_score))
                        raw_deduction = max_score - raw_score_num
                    else:
                        raw_score_num = float(raw_score)
                        if raw_score_num < 0:
                            raw_deduction = min(abs(raw_score_num), max_score)
                        elif raw_score_num > 0:
                            raw_deduction = min(raw_score_num, max_score)
                        else:
                            raw_deduction = 0.0
                if raw_deduction is not None:
                    deduction_total = max(deduction_total, raw_deduction)
                    checkpoint_reason = f" Missing {scoring_mode} detail scores; reconciled with rule-level score."
                else:
                    checkpoint_reason = f" Missing {scoring_mode} detail scores; unreported deduction triggers treated as not triggered."
            if not details:
                if scoring_mode == "deductive" and isinstance(raw_score, (int, float)):
                    score = max(0.0, min(float(raw_score), max_score))
                    deduction_total = max_score - score
                elif isinstance(raw_score, (int, float)) and raw_score < 0:
                    deduction_total = min(abs(float(raw_score)), max_score)
                elif isinstance(raw_score, (int, float)) and raw_score > 0:
                    deduction_total = min(float(raw_score), max_score)
            if scoring_mode == "deductive" and _reason_declares_deductive_floor(str(src.get("reason") or "")):
                deduction_total = max_score
                checkpoint_reason += " Deductive reason declared deductions reach the rule floor; reconciled rule score to 0."
            if scoring_mode == "deductive":
                score = max(0.0, max_score - min(deduction_total, max_score))
            else:
                score = -min(deduction_total, max_score)
        elif details:
            score_by_checkpoint = 0.0
            reconciled_checkpoints = []
            for idx, detail in enumerate(details):
                cp_max = float(detail.get("points") or 0)
                got = checkpoint_scores[idx] if idx < len(checkpoint_scores) and isinstance(checkpoint_scores[idx], dict) else {}
                cp_score = got.get("score", 0)
                if not isinstance(cp_score, (int, float)):
                    cp_score = 0
                cp_score = max(0.0, min(float(cp_score), cp_max))
                evidence = str(got.get("evidence") or got.get("reason") or "")[:240]
                score_by_checkpoint += cp_score
                reconciled_checkpoints.append({
                    "description": str(detail.get("description", ""))[:160],
                    "score": cp_score,
                    "max_score": cp_max,
                    "evidence": evidence,
                })
            score = min(score_by_checkpoint, max_score)
            checkpoint_reason = "" if len(checkpoint_scores) >= len(details) else " Missing scoring detail scores; unreported additive details scored 0."
        else:
            score = src.get("score", 0)
            if not isinstance(score, (int, float)):
                score = 0
            score = max(0, min(float(score), max_score))
            reconciled_checkpoints = []
            checkpoint_reason = ""
        reconciled.append({
            "rule_id": rid,
            "rule_name": str(rule.get("title", rid))[:80],
            "scoring_mode": scoring_mode,
            "checkpoint_scores": reconciled_checkpoints,
            "score": score,
            "max_score": max_score,
            "rule_veto_triggered": rule_veto_triggered,
            "veto_reason": rule_veto_reason,
            "reason": (str(src.get("reason") or "Codex did not provide a valid score for this rule.") + checkpoint_reason)[:240],
        })
    result["scores"] = reconciled
    result["raw_total"] = sum(s["score"] for s in reconciled)
    result["max_total"] = sum(
        s["max_score"]
        for s, rule in zip(reconciled, rules)
        if str(rule.get("scoring_mode") or "additive") in {"additive", "deductive"}
    )
    result["summary"] = _sanitize_summary_feedback(result.get("summary", ""))
    return result


# ---------------------------------------------------------------------------
# Structured result output
# ---------------------------------------------------------------------------

STRUCTURED_RESULT_START = ">>>>> Start Structured Result"
STRUCTURED_RESULT_END = ">>>>> End Structured Result"
SUMMARY_MAX_CHARS = 80


def _sanitize_summary_feedback(value: object) -> str:
    """Keep worker-facing feedback high-level and non-leaky."""
    raw = str(value or "").strip()
    if not raw:
        return ""
    unsafe_patterns = [
        r"https?://\S+",
        r"[A-Za-z0-9_.+\-]+\.(?:pdf|docx?|xlsx?|pptx?|csv|json|md|txt|py|png|jpe?g)",
        r"\d",
        r"\bR\d{3}\b",
    ]
    unsafe_terms = (
        "rubric", "Rubric", "rule_id", "checkpoint", "参考答案", "评分附件",
        "评分方案", "评分表", "评分项", "评分规则", "真值", "答案", "页码",
        "行号", "sheet", "Sheet", "URL", "http", "www", "应包含", "必须包含",
        "具体为", "逐项", "完整清单", "附件名", "文件名", "隐藏", "标准答案",
    )
    if any(re.search(pattern, raw, flags=re.I) for pattern in unsafe_patterns):
        return ""
    if any(term in raw for term in unsafe_terms):
        return ""

    text = re.sub(r"[\r\n\t]+", " ", raw)
    text = re.sub(r"\s+", " ", text)
    text = text.strip(" -")
    if len(text) < 8:
        return ""
    if len(text) > SUMMARY_MAX_CHARS:
        text = text[:SUMMARY_MAX_CHARS].rstrip(" _，,。；;、")
    return text


def _fallback_submission_summary(result: dict) -> str:
    """Use task-facing signals only; never derive fallback from rubric failures."""
    manifest = result.get("submission_manifest") if isinstance(result.get("submission_manifest"), dict) else {}
    if manifest.get("missing_expected_outputs"):
        return "请先补齐任务要求的交付物，再完善整体内容和说明依据。"
    if manifest.get("format_mismatches") or manifest.get("name_mismatches"):
        return "请先核对交付格式和文件命名，再完善整体内容和说明依据。"
    raw_total = result.get("raw_total")
    max_total = result.get("max_total")
    if isinstance(raw_total, (int, float)) and isinstance(max_total, (int, float)) and max_total > 0:
        if raw_total >= max_total - 1e-6:
            return "整体已覆盖任务要求，请继续保持交付清晰和依据可复核。"
    return "请围绕任务目标补强主要内容覆盖、结构组织和可复核依据。"


def _ensure_submission_summary(result: dict) -> str:
    summary = _sanitize_summary_feedback(result.get("summary", ""))
    if not summary:
        summary = _fallback_submission_summary(result)
    result["summary"] = summary
    return summary


def emit_structured_output(result: dict, total_score: float, warnings: list[str]) -> None:
    summary = _ensure_submission_summary(result)
    for w in warnings:
        sys.stderr.write(f"[grader] WARNING: {w}\n")
    structured = {
        "valid": result.get("grader_status") == "ok",
        "score": round(float(total_score), 6),
        "pass_rate": max(0.0, min(float(total_score) / 100.0, 1.0)),
        "summary": summary,
        "metrics": {
            "raw_total": result.get("raw_total", 0),
            "max_total": result.get("max_total", 0),
        },
    }
    print(STRUCTURED_RESULT_START)
    print(json.dumps(structured, ensure_ascii=False, indent=2))
    print(STRUCTURED_RESULT_END)


def emit_all_failed(reason: str, status: str = "error") -> None:
    sys.stderr.write(f"[grader] fatal: {reason}\n")
    payload = {
        "grader_status": status,
        "error": reason,
        "veto_triggered": False,
        "veto_reason": None,
        "summary": "评分服务暂时未完成，请先核对任务交付物是否完整。",
        "scores": [],
        "raw_total": 0,
        "max_total": 0,
    }
    write_grading_result(payload)
    emit_grading_result_marker(payload)
    print(STRUCTURED_RESULT_START)
    print(json.dumps({
        "valid": False,
        "score": 0,
        "pass_rate": 0,
        "summary": payload["summary"],
        "metrics": {"grader_status": status},
    }, ensure_ascii=False, indent=2))
    print(STRUCTURED_RESULT_END)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description="Codex agent rubrics grader")
    ap.add_argument("--report", required=True, help="Path to agent submission file or directory")
    ap.add_argument("--scoring-dir", required=True, help="Dir with scoring/rubrics files")
    ap.add_argument("--task-id", required=True, help="Task identifier")
    ap.add_argument("--input-dir", default=None, help="Dir with agent input files")
    ap.add_argument("--timeout", type=int, default=600, help="Codex execution timeout")
    ap.add_argument("--dump-prompt", default=None, help="Dump prompt to file")
    ap.add_argument("--dump-codex-output", default=None, help="Dump raw codex output")
    args = ap.parse_args()

    scoring_dir = Path(args.scoring_dir)
    if not scoring_dir.is_dir():
        emit_all_failed(f"scoring dir not found: {scoring_dir}")
        return 1
    try:
        rubric_rules = load_rubrics_json(scoring_dir)
    except Exception as e:
        emit_all_failed(str(e))
        return 1

    report_path = Path(args.report)
    if not report_path.exists():
        emit_all_failed(f"submission missing or empty: {report_path}")
        return 0
    if report_path.is_file() and report_path.stat().st_size == 0:
        emit_all_failed(f"submission missing or empty: {report_path}")
        return 0
    if report_path.is_dir():
        has_submission_file = any(
            p.is_file()
            and ".git" not in p.parts
            and "__pycache__" not in p.parts
            for p in report_path.rglob("*")
        )
        if not has_submission_file:
            emit_all_failed(f"submission directory has no files: {report_path}")
            return 0

    sys.stderr.write(f"[codex-judge] task={args.task_id}\n")
    if report_path.is_dir():
        sys.stderr.write(f"[codex-judge] submission={report_path} (directory)\n")
    else:
        sys.stderr.write(f"[codex-judge] submission={report_path} ({report_path.stat().st_size} bytes)\n")
    sys.stderr.write(f"[codex-judge] scoring_dir={scoring_dir}\n")
    sys.stderr.write(f"[codex-judge] input_dir={args.input_dir or 'none'}\n")
    sys.stderr.write(f"[codex-judge] mode=agent (codex reads files directly)\n")

    input_path = Path(args.input_dir) if args.input_dir else None
    submission_manifest = build_submission_manifest(report_path, input_path)
    manifest_path = Path("submission_manifest.json")
    manifest_path.write_text(json.dumps(submission_manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    visual_manifest = build_visual_assets_manifest(report_path, Path("visual_assets"))
    visual_manifest_path = Path("visual_assets_manifest.json")
    visual_manifest_path.write_text(json.dumps(visual_manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    structure_manifest = build_structure_manifest(report_path)
    structure_manifest_path = Path("submission_structure_manifest.json")
    structure_manifest_path.write_text(json.dumps(structure_manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    sys.stderr.write(
        "[codex-judge] submission_manifest="
        f"expected={len(submission_manifest.get('expected_outputs') or [])} "
        f"actual={len(submission_manifest.get('actual_files') or [])} "
        f"missing={len(submission_manifest.get('missing_expected_outputs') or [])}"
        "\n"
    )
    sys.stderr.write(
        "[codex-judge] visual_assets="
        f"count={visual_manifest.get('asset_count')} "
        f"contact_sheet={visual_manifest.get('contact_sheet')}\n"
    )
    sys.stderr.write(
        "[codex-judge] structure_manifest="
        f"files={len(structure_manifest.get('files') or [])}\n"
    )

    # 构建 prompt（只传路径，codex 自己读文件）
    prompt = build_codex_prompt(
        rubrics_text="", submission_text="", input_text="",
        scoring_dir=str(scoring_dir),
        input_dir=str(Path(args.input_dir)) if args.input_dir else "",
        report_path=str(report_path),
        submission_manifest=str(manifest_path),
        visual_manifest=str(visual_manifest_path),
        structure_manifest=str(structure_manifest_path),
    )
    if args.dump_prompt:
        Path(args.dump_prompt).write_text(prompt, encoding="utf-8")

    try:
        codex_output = invoke_codex(prompt, timeout=args.timeout)
    except subprocess.TimeoutExpired:
        emit_all_failed(f"Codex timed out after {args.timeout}s", status="timeout")
        return 0
    except Exception as e:
        emit_all_failed(f"Codex invocation failed: {e}", status="codex_failed")
        return 0

    if args.dump_codex_output:
        Path(args.dump_codex_output).write_text(codex_output, encoding="utf-8")

    result = extract_json_from_output(codex_output)
    if not result:
        sys.stderr.write(f"[codex-judge] Failed to extract JSON from output (len={len(codex_output)})\n")
        sys.stderr.write(f"[codex-judge] Output tail: {codex_output[-1000:]}\n")
        emit_all_failed("Codex output did not contain valid scoring JSON", status="json_parse_failed")
        return 0
    result = reconcile_result_with_rubrics(result, rubric_rules)
    result["grader_status"] = "ok"
    result["submission_manifest"] = submission_manifest
    result["visual_assets_manifest"] = {
        "asset_count": visual_manifest.get("asset_count"),
        "contact_sheet": visual_manifest.get("contact_sheet"),
    }
    result["submission_structure_manifest"] = structure_manifest

    warnings: list[str] = []
    judge_model = (
        os.environ.get("SFORGE_JUDGE_MODEL")
        or os.environ.get("SEBENCH_JUDGE_MODEL")
        or "codex_config"
    )
    warnings.append(f"judge_backend=codex, model={judge_model}")

    # Rule-level veto_conditions are already reflected in per-rule scores.
    if result.get("veto_triggered"):
        warnings.append(f"VETO: {result.get('veto_reason', 'unknown')}")
    max_total = result.get("max_total", 100)
    raw_total = result.get("raw_total", 0)
    if max_total > 0:
        total_score = max(0.0, (raw_total / max_total) * 100)
    else:
        total_score = 0.0
    _ensure_submission_summary(result)
    write_grading_result(result)
    emit_grading_result_marker(result)

    emit_structured_output(result, total_score, warnings)
    return 0


if __name__ == "__main__":
    sys.exit(main())
