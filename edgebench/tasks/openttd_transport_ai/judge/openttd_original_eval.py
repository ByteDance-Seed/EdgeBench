#!/usr/bin/env python3
"""
eval_script.py - OpenTTD AI 评测脚本

使用 OpenTTDLab 在多个随机 seed 地图上运行 AI 脚本 20 年游戏时间，
从 savegame 中提取公司市值，计算平均得分。

评分指标：old_economy[0]["company_value"]（游戏内置公司市值，每季度结算）
取值方式：每个 seed 取所有月度存档中最后一个 company_value > 0 的值
         （即游戏结束前最近一次季度结算的公司市值）

公司市值 = 车辆价值(1.5x购入价) + 基建价值(车站/道路/铁路) + 净资产(现金-贷款)
这是 OpenTTD 官方衡量公司经营好坏的综合指标。

用法:
    python eval_script.py <ai_folder> [--seeds N] [--ai-name NAME]

示例:
    python eval_script.py ./my_ai
    python eval_script.py ./my_ai --seeds 10
"""

import argparse
import os
import re
import sys
from collections import defaultdict

import httpx
from openttdlab import run_experiments, local_folder


# ===================== 配置 =====================

OPENTTD_VERSION = "13.4"   # 13.x 使用 autosave 模式，兼容性好
OPENGFX_VERSION = "7.1"
GAME_YEARS = 20
DEFAULT_SEEDS = 10

# ===================== 网络 =====================

PROXY = os.environ.get("https_proxy") or os.environ.get("HTTPS_PROXY")


def get_http_client():
    """构造 httpx Client，自动处理代理。"""
    kwargs = dict(
        timeout=httpx.Timeout(120.0, connect=60.0),
        transport=httpx.HTTPTransport(retries=3),
    )
    if PROXY:
        kwargs["proxy"] = PROXY
    return httpx.Client(**kwargs)


# ===================== 评测 =====================

def extract_company_value(saves):
    """
    从一个 seed 的所有月度存档中提取公司市值。

    策略：取最后一个 old_economy[0]["company_value"] > 0 的值。
    原因：company_value 只在季度结算时写入 old_economy，
         非结算月份该值为 0 或 1。取"最后一个有效值"等价于
         取游戏结束前最近一次季度结算的公司市值。
    """
    last_valid_cv = 0
    last_valid_date = None

    for save in saves:
        plyr = save["chunks"].get("PLYR", {}).get("0", {})
        old_eco = plyr.get("old_economy", [])
        if old_eco:
            cv = old_eco[0].get("company_value", 0)
            if cv > 1:  # 0 和 1 都是无效值
                last_valid_cv = cv
                last_valid_date = save["date"]

    # 从最终存档取现金和贷款
    final = saves[-1]
    plyr = final["chunks"].get("PLYR", {}).get("0", {})
    money = plyr.get("money", 0)
    loan = plyr.get("current_loan", 0)
    error = final.get("error", False)
    final_date = final["date"]

    return {
        "company_value": last_valid_cv,
        "cv_date": last_valid_date,
        "money": money,
        "loan": loan,
        "net_worth": money - loan,
        "error": error,
        "final_date": final_date,
    }


def run_eval(ai_folder: str, ai_name: str, num_seeds: int):
    """运行评测，返回平均公司市值和各 seed 详情。"""
    print(f"评测配置:")
    print(f"  AI 文件夹:  {ai_folder}")
    print(f"  AI 名称:    {ai_name}")
    print(f"  OpenTTD:    {OPENTTD_VERSION}")
    print(f"  游戏年数:   {GAME_YEARS}")
    print(f"  Seed 数量:  {num_seeds}")
    print()

    results = run_experiments(
        openttd_version=OPENTTD_VERSION,
        opengfx_version=OPENGFX_VERSION,
        get_http_client=get_http_client,
        experiments=(
            {
                "seed": seed,
                "ais": (local_folder(ai_folder, ai_name=ai_name),),
                "days": 365 * GAME_YEARS,
            }
            for seed in range(num_seeds)
        ),
        max_workers=min(num_seeds, os.cpu_count() or 4),
    )

    # 按 seed 分组（autosave 模式每个 seed 产生 ~240 个月度存档）
    by_seed = defaultdict(list)
    for result in results:
        seed = result["experiment"]["seed"]
        by_seed[seed].append(result)

    # 提取各 seed 结果
    seed_results = []
    header = f"{'Seed':>4}  {'Company Value':>15}  {'CV Date':>12}  {'Money':>12}  {'Loan':>10}  {'Net Worth':>12}  {'Error':>5}"
    print(header)
    print("-" * len(header))

    for seed in sorted(by_seed.keys()):
        info = extract_company_value(by_seed[seed])
        info["seed"] = seed
        seed_results.append(info)

        cv_date_str = str(info["cv_date"])[:10] if info["cv_date"] else "N/A"
        err_str = "YES" if info["error"] else ""
        print(
            f"{seed:>4}  {info['company_value']:>15,}  {cv_date_str:>12}  "
            f"{info['money']:>12,}  {info['loan']:>10,}  {info['net_worth']:>12,}  {err_str:>5}"
        )

    print("-" * len(header))

    # 汇总
    values = [r["company_value"] for r in seed_results]
    errors = sum(1 for r in seed_results if r["error"])

    avg_cv = sum(values) / len(values) if values else 0
    min_cv = min(values) if values else 0
    max_cv = max(values) if values else 0
    median_cv = sorted(values)[len(values) // 2] if values else 0

    print()
    print(f"汇总:")
    print(f"  平均公司市值:   {avg_cv:>15,.0f}")
    print(f"  中位数公司市值: {median_cv:>15,}")
    print(f"  最小公司市值:   {min_cv:>15,}")
    print(f"  最大公司市值:   {max_cv:>15,}")
    print(f"  脚本报错:       {errors}/{len(seed_results)} seeds")
    print()
    print(f"  *** 最终得分（平均公司市值）: {avg_cv:,.0f} ***")

    return avg_cv, seed_results


# ===================== AI 名称自动检测 =====================

def detect_ai_name(ai_folder: str) -> str:
    """从 info.nut 中自动检测 AI 名称（CreateInstance 返回值）。"""
    info_path = os.path.join(ai_folder, "info.nut")
    if not os.path.exists(info_path):
        print(f"警告: 未找到 {info_path}，请通过 --ai-name 指定 AI 名称")
        return "MyAI"

    with open(info_path, "r") as f:
        content = f.read()

    match = re.search(r'CreateInstance\(\)\s*\{\s*return\s*"([^"]+)"', content)
    if match:
        return match.group(1)

    match = re.search(r'GetName\(\)\s*\{\s*return\s*"([^"]+)"', content)
    if match:
        return match.group(1)

    print("警告: 无法从 info.nut 自动检测 AI 名称，使用默认值 'MyAI'")
    return "MyAI"


# ===================== 入口 =====================

def main():
    parser = argparse.ArgumentParser(
        description="OpenTTD AI 评测脚本 - 运行 AI 并计算平均公司市值"
    )
    parser.add_argument("ai_folder", help="AI 脚本文件夹路径（含 info.nut + main.nut）")
    parser.add_argument("--ai-name", default=None, help="AI 名称（默认自动检测）")
    parser.add_argument("--seeds", type=int, default=DEFAULT_SEEDS, help=f"Seed 数量（默认 {DEFAULT_SEEDS}）")

    args = parser.parse_args()

    if not os.path.isdir(args.ai_folder):
        print(f"错误: AI 文件夹不存在: {args.ai_folder}", file=sys.stderr)
        sys.exit(1)
    for f in ["info.nut", "main.nut"]:
        if not os.path.exists(os.path.join(args.ai_folder, f)):
            print(f"错误: 缺少 {os.path.join(args.ai_folder, f)}", file=sys.stderr)
            sys.exit(1)

    ai_name = args.ai_name or detect_ai_name(args.ai_folder)
    print(f"检测到 AI 名称: {ai_name}\n")

    score, _ = run_eval(args.ai_folder, ai_name, args.seeds)
    sys.exit(0 if score > 0 else 1)


if __name__ == "__main__":
    main()
