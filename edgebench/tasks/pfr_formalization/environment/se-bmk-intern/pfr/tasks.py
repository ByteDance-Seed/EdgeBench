import os
import shutil
import subprocess
from pathlib import Path
from invoke import run, task
import json
import re

from blueprint.tasks import web, bp, print_bp, serve

ROOT = Path(__file__).parent
BP_DIR = ROOT/'blueprint'
PROJ = 'PFR'

@task(bp, web)
def all(ctx):
    shutil.rmtree(ROOT/'docs'/'blueprint', ignore_errors=True)
    shutil.copytree(ROOT/'blueprint'/'web', ROOT/'docs'/'blueprint')
    shutil.copy2(ROOT/'blueprint'/'print'/'print.pdf', ROOT/'docs'/'blueprint.pdf')

@task(web)
def html(ctx):
    shutil.rmtree(ROOT/'docs'/'blueprint', ignore_errors=True)
    shutil.copytree(ROOT/'blueprint'/'web', ROOT/'docs'/'blueprint')

@task(all)
def dev(ctx):
    """
    Serve the blueprint website, rebuild PDF and the website on file changes
    """

    from watchfiles import run_process, DefaultFilter

    def callback(changes):
        print('Changes detected:', changes)
        bp(ctx)
        web(ctx)

    run_process(BP_DIR/'src', target='inv serve', callback=callback,
        watch_filter=DefaultFilter(
            ignore_entity_patterns=(
                '.*\.aux$',
                '.*\.log$',
                '.*\.fls$',
                '.*\.fdb_latexmk$',
                '.*\.bbl$',
                '.*\.paux$',
                '.*\.pdf$',
                '.*\.out$',
                '.*\.blg$',
                '.*\.synctex.*$',
            )
        ))

@task
def check(ctx):
    """
    Check for broken references in blueprint to Lean declarations
    """

    broken_decls = []

    DECLS_FILE = ROOT/'.lake/build/doc/declarations/declaration-data.bmp'
    if not DECLS_FILE.exists():
        print('[ERROR] Declarations file not found. Please run `lake -Kenv=dev build %s:docs` first.' % PROJ)
        exit(1)

    DEP_GRAPH_FILE = BP_DIR/'web/dep_graph_document.html'
    if not DEP_GRAPH_FILE.exists():
        print('[ERROR] Dependency graph file not found. Please run `inv all` (or only `inv web`) first.')
        exit(1)

    with open(DECLS_FILE) as f:
        lean_decls = json.load(f)['declarations']

    with open(DEP_GRAPH_FILE) as f:
        lean_decl_regex = re.compile(r'lean_decl.*href=".*/find/#doc/([^"]+)"')
        for line in f:
            match = lean_decl_regex.search(line)
            if match and match.lastindex == 1:
                blueprint_decl = match[1]
                if blueprint_decl not in lean_decls:
                    broken_decls.append(blueprint_decl)

    if broken_decls:
        print('[WARN] The following Lean declarations are referenced in the blueprint but not in Lean:\n')
        for decl in broken_decls:
            print(decl)
        exit(1)
    else:
        print('[OK] All Lean declarations referenced in the blueprint exist.')
