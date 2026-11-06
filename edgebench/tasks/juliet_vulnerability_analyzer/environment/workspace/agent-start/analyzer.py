#!/usr/bin/env python3
from __future__ import annotations
import argparse, json
from pathlib import Path
def main() -> None:
    ap=argparse.ArgumentParser(); ap.add_argument('--input',required=True); ap.add_argument('--output',required=True); args=ap.parse_args()
    Path(args.output).parent.mkdir(parents=True,exist_ok=True)
    Path(args.output).write_text(json.dumps({'findings': []}, indent=2)+'\n', encoding='utf-8')
if __name__=='__main__': main()
