import os
import random
from pathlib import Path
import http.server
import socketserver

from invoke import run, task

BP_DIR = Path(__file__).parent

@task
def print_bp(ctx):
    cwd = os.getcwd()
    os.chdir(BP_DIR)
    os.makedirs("print", exist_ok=True)
    run('cd src && xelatex -output-directory=../print print.tex')
    os.chdir(cwd)

@task
def bp(ctx):
    cwd = os.getcwd()
    os.chdir(BP_DIR)
    os.makedirs("print", exist_ok=True)
    run('cd src && xelatex -output-directory=../print print.tex')
    run('cd src && xelatex -output-directory=../print print.tex')
    os.chdir(cwd)

@task
def web(ctx):
    cwd = os.getcwd()
    os.chdir(BP_DIR/'src')
    run('plastex -c plastex.cfg web.tex')
    os.chdir(cwd)

@task
def serve(ctx, random_port=False):
    cwd = os.getcwd()
    os.chdir(BP_DIR/'web')
    Handler = http.server.SimpleHTTPRequestHandler
    if random_port:
        port = random.randint(8000, 8100)
        print("Serving on port " + str(port))
    else:
        port = 8000
    httpd = socketserver.TCPServer(("", port), Handler)
    httpd.serve_forever()
    os.chdir(cwd)
