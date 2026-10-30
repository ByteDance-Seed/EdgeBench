# Copyright (c) 2026 ByteDance Ltd. and/or its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Minimal run viewer: score curves, submissions and token usage.

Trajectories are not rendered here: ``sforge replay`` opens a run's archived
sessions in the agent's own UI (``claude --resume`` / ``codex resume``).
Everything is read from ``<log_dir>/runs`` on each request.
"""

from __future__ import annotations

import json
import time
from dataclasses import dataclass, field
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, HTMLResponse
from jinja2 import Environment
from markupsafe import Markup

_env = Environment(autoescape=True)


@dataclass
class Submission:
    round: str
    at: float | None
    score: float | None
    score_0_100: float | None
    valid: bool
    summary: str | None
    error: str | None


@dataclass
class TaskRun:
    run_id: str
    task: str
    path: Path
    started: float | None
    final: dict | None
    submissions: list[Submission] = field(default_factory=list)

    @property
    def finished(self) -> bool:
        return self.final is not None

    @property
    def best(self) -> float | None:
        if self.final:
            return self.final.get("best_score_0_100")
        scores = [s.score_0_100 for s in self.submissions if s.valid and s.score_0_100 is not None]
        return max(scores) if scores else None

    @property
    def usage(self) -> dict:
        if self.final and self.final.get("usage"):
            return self.final["usage"]
        return _usage_from_log(self.path / "llm_requests.jsonl")


def _read_json(path: Path) -> dict | None:
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return None


def _usage_from_log(path: Path) -> dict:
    totals = {"requests": 0, "errors": 0, "input_tokens": 0, "cache_read_tokens": 0,
              "cache_write_tokens": 0, "output_tokens": 0, "by_model": {}}
    try:
        lines = path.read_text().splitlines()
    except OSError:
        return totals
    for line in lines:
        try:
            r = json.loads(line)
        except ValueError:
            continue
        totals["requests"] += 1
        totals["errors"] += r.get("status", 0) >= 400
        for k in ("input_tokens", "cache_read_tokens", "cache_write_tokens", "output_tokens"):
            totals[k] += (r.get("usage") or {}).get(k, 0)
    return totals


def load_task_run(path: Path) -> TaskRun:
    started = None
    try:
        started = float((path / "started_at").read_text().split()[1])
    except (OSError, IndexError, ValueError):
        pass
    subs = []
    for rep in (path / "submissions").glob("*/report.json"):
        d = _read_json(rep) or {}
        subs.append(Submission(
            round=rep.parent.name, at=d.get("submitted_at"), score=d.get("score"),
            score_0_100=d.get("score_0_100"), valid=bool(d.get("valid")),
            summary=d.get("summary"), error=d.get("error"),
        ))
    subs.sort(key=lambda s: s.at or 0)
    return TaskRun(path.parent.name, path.name, path, started,
                   _read_json(path / "final_result.json"), subs)


def scan(runs_dir: Path) -> list[TaskRun]:
    out = [load_task_run(p.parent) for p in runs_dir.glob("*/*/run_agent.log")]
    return sorted(out, key=lambda r: r.started or 0, reverse=True)


def score_chart(tr: TaskRun, width: int = 760, height: int = 260) -> str:
    """Inline SVG: valid submissions (dots) and best-so-far (step line), 0-100 vs minutes."""
    pts = [(s.at, s.score_0_100) for s in tr.submissions
           if s.valid and s.score_0_100 is not None and s.at]
    if not pts:
        return "<p>No scored submissions yet.</p>"
    t0 = tr.started or pts[0][0]
    span = max(max(t for t, _ in pts) - t0, 60)
    pad = 36

    def xy(t, y):
        return (pad + (t - t0) / span * (width - 2 * pad),
                height - pad - y / 100 * (height - 2 * pad))

    best, step, dots = None, [], []
    for t, y in pts:
        x, py = xy(t, y)
        dots.append(f'<circle cx="{x:.1f}" cy="{py:.1f}" r="3"><title>{y:.2f}</title></circle>')
        best = y if best is None else max(best, y)
        bx, by = xy(t, best)
        if step:
            step.append(f"{bx:.1f},{step[-1].split(',')[1]}")
        step.append(f"{bx:.1f},{by:.1f}")
    grid = "".join(
        f'<line x1="{pad}" x2="{width - pad}" y1="{xy(t0, v)[1]:.1f}" y2="{xy(t0, v)[1]:.1f}" class="grid"/>'
        f'<text x="4" y="{xy(t0, v)[1] + 4:.1f}">{v}</text>'
        for v in (0, 25, 50, 75, 100)
    )
    return (
        f'<svg viewBox="0 0 {width} {height}" class="chart">{grid}'
        f'<polyline points="{" ".join(step)}" class="best"/>{"".join(dots)}'
        f'<text x="{width - pad}" y="{height - 8}" text-anchor="end">{span / 60:.0f} min</text></svg>'
    )


_BASE = """<!doctype html><html><head><meta charset="utf-8"><title>{{ title }}</title>
<style>
body{font:14px system-ui,sans-serif;margin:24px;color:#222}
table{border-collapse:collapse}td,th{padding:4px 10px;border-bottom:1px solid #ddd;text-align:left}
th{background:#f5f5f5}.num{text-align:right;font-variant-numeric:tabular-nums}
.chart{width:100%;max-width:760px;background:#fafafa}.chart .grid{stroke:#e5e5e5}
.chart .best{fill:none;stroke:#2b6cb0;stroke-width:2}.chart circle{fill:#dd6b20}
.chart text{font-size:11px;fill:#888}code{background:#f0f0f0;padding:2px 4px}
.muted{color:#888}
</style></head><body>{{ body }}</body></html>"""

_INDEX = _env.from_string("""
<h2>SForge runs</h2>
<table><tr><th>run</th><th>task</th><th>agent</th><th>model</th><th>status</th>
<th class="num">best (0-100)</th><th class="num">subs</th><th class="num">in / cached / out tokens</th><th>started</th></tr>
{% for r in runs %}{% set u = r.usage %}
<tr><td><a href="/run/{{ r.run_id }}/{{ r.task }}">{{ r.run_id }}</a></td><td>{{ r.task }}</td>
<td>{{ (r.final or {}).get('agent', '') }}</td><td>{{ (r.final or {}).get('model', '') }}</td>
<td>{{ 'done' if r.finished else 'running' }}</td>
<td class="num">{{ '%.2f'|format(r.best) if r.best is not none else '-' }}</td>
<td class="num">{{ r.submissions|length }}</td>
<td class="num">{{ u.input_tokens }} / {{ u.cache_read_tokens }} / {{ u.output_tokens }}</td>
<td>{{ fmt_time(r.started) }}</td></tr>{% endfor %}</table>""")

_DETAIL = _env.from_string("""
<p><a href="/">all runs</a></p>
<h2>{{ r.task }} <span class="muted">/ {{ r.run_id }}</span></h2>
<p>{{ f.get('agent', '?') }} · {{ f.get('model', '?') }} · {{ 'done' if r.finished else 'running' }}
{% if f %} · {{ '%.0f'|format(f.get('runtime_seconds', 0) / 60) }} min{% endif %}
· best {{ '%.2f'|format(r.best) if r.best is not none else '-' }}</p>
{{ chart|safe }}
<h3>Submissions</h3>
<table><tr><th>round</th><th class="num">t (min)</th><th class="num">raw score</th><th class="num">0-100</th><th>valid</th><th>summary</th><th></th></tr>
{% for s in r.submissions %}<tr><td>{{ s.round }}</td>
<td class="num">{{ '%.1f'|format((s.at - r.started) / 60) if s.at and r.started else '-' }}</td>
<td class="num">{{ s.score if s.score is not none else '-' }}</td>
<td class="num">{{ '%.2f'|format(s.score_0_100) if s.score_0_100 is not none else '-' }}</td>
<td>{{ 'yes' if s.valid else 'no' }}</td><td>{{ s.error or s.summary or '' }}</td>
<td><a href="/run/{{ r.run_id }}/{{ r.task }}/file/submissions/{{ s.round }}/judge_output.txt">judge output</a></td></tr>{% endfor %}</table>
<h3>Token usage</h3>
<table><tr><th>model</th><th class="num">input</th><th class="num">cache read</th><th class="num">cache write</th><th class="num">output</th></tr>
{% for m, u in (usage.get('by_model') or {}).items() %}<tr><td>{{ m }}</td><td class="num">{{ u.input_tokens }}</td>
<td class="num">{{ u.cache_read_tokens }}</td><td class="num">{{ u.cache_write_tokens }}</td><td class="num">{{ u.output_tokens }}</td></tr>{% endfor %}
<tr><th>total ({{ usage.requests }} requests, {{ usage.errors }} errors)</th><th class="num">{{ usage.input_tokens }}</th>
<th class="num">{{ usage.cache_read_tokens }}</th><th class="num">{{ usage.cache_write_tokens }}</th><th class="num">{{ usage.output_tokens }}</th></tr></table>
<h3>Trajectory</h3>
{% if has_sessions %}<p>Open it in the agent's own UI: <code>sforge replay --run-id {{ r.run_id }} --task {{ r.task }}</code></p>
{% else %}<p class="muted">No session files archived.</p>{% endif %}
<h3>Files</h3><p>{% for name in files %}<a href="/run/{{ r.run_id }}/{{ r.task }}/file/{{ name }}">{{ name }}</a> · {% endfor %}</p>""")


def _page(title: str, body: str) -> HTMLResponse:
    return HTMLResponse(_env.from_string(_BASE).render(title=title, body=Markup(body)))


def _fmt_time(ts: float | None) -> str:
    return time.strftime("%Y-%m-%d %H:%M", time.localtime(ts)) if ts else "-"


def create_app(runs_dir: Path) -> FastAPI:
    app = FastAPI(title="SForge viewer")
    runs_dir = runs_dir.resolve()

    def _task_dir(run_id: str, task: str) -> Path:
        path = (runs_dir / run_id / task).resolve()
        if path.parent.parent != runs_dir or not (path / "run_agent.log").exists():
            raise HTTPException(404, "run not found")
        return path

    @app.get("/", response_class=HTMLResponse)
    def index():
        return _page("SForge runs", _INDEX.render(runs=scan(runs_dir), fmt_time=_fmt_time))

    @app.get("/run/{run_id}/{task}", response_class=HTMLResponse)
    def detail(run_id: str, task: str):
        tr = load_task_run(_task_dir(run_id, task))
        files = [n for n in ("agent_output.txt", "run_agent.log", "agent_prompt.md",
                             "final_result.json", "llm_requests.jsonl", "final_archive.tar.gz")
                 if (tr.path / n).exists()]
        return _page(f"{task} / {run_id}", _DETAIL.render(
            r=tr, f=tr.final or {}, usage=tr.usage, chart=score_chart(tr), files=files,
            has_sessions=(tr.path / "sessions").is_dir(),
        ))

    @app.get("/run/{run_id}/{task}/file/{name:path}")
    def file(run_id: str, task: str, name: str):
        base = _task_dir(run_id, task)
        path = (base / name).resolve()
        if base not in path.parents or not path.is_file():
            raise HTTPException(404, "file not found")
        media = None if path.suffix in (".gz", ".tar") else "text/plain; charset=utf-8"
        return FileResponse(path, media_type=media)

    return app
