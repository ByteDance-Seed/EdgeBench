# Agent starter

Edit `analyzer.py` only. The analyzer receives `--input <facts.jsonl>` and must write
`--output <findings.json>` with:

```json
{"findings": [{"case_id": "...", "cwe": "CWE-476", "source_stmt": 12, "sink_stmt": 42, "trace": [12, 18, 42]}]}
```

Do not call external analyzers such as CodeQL, Joern, Infer, Semgrep, clang static analyzer, or cppcheck.
