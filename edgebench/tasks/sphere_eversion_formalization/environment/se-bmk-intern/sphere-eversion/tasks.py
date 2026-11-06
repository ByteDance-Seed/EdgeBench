import os
import shutil
from pathlib import Path
from invoke import run, task

from blueprint.tasks import web, bp, print, serve

ROOT = Path(__file__).parent

@task
def doc(ctx):
    cwd = os.getcwd()
    os.chdir(ROOT/'docs_src')
    for path in (ROOT/'docs_src').glob('*.md'):
        run(f'pandoc -t html --mathjax -f markdown+tex_math_dollars+raw_tex {path.name} --template template.html -o ../docs/{path.with_suffix(".html").name}')
    os.chdir(cwd)

@task(doc, bp, web)
def all(ctx):
    shutil.rmtree(ROOT/'docs'/'blueprint', ignore_errors=True)
    shutil.copytree(ROOT/'blueprint'/'web', ROOT/'docs'/'blueprint')
    shutil.copy2(ROOT/'blueprint'/'print'/'print.pdf', ROOT/'docs'/'blueprint.pdf')

@task(doc, web)
def html(ctx):
    shutil.rmtree(ROOT/'docs'/'blueprint', ignore_errors=True)
    shutil.copytree(ROOT/'blueprint'/'web', ROOT/'docs'/'blueprint')
