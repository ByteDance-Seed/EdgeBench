import os
import random
import re
from pathlib import Path
import http.server
import socketserver

from invoke import run, task

BP_DIR = Path(__file__).parent

latex_command = 'latexmk -shell-escape -pdf -pdflatex=xelatex -file-line-error -halt-on-error ' + \
  '-interaction=nonstopmode -cd -output-directory=../print print.tex'

@task
def bp(ctx):
    cwd = os.getcwd()
    os.chdir(BP_DIR)
    run('mkdir -p print && cd src && ' + latex_command)
    run('cp print/print.bbl src/web.bbl')
    os.chdir(cwd)

@task
def web(ctx):
    cwd = os.getcwd()
    os.chdir(BP_DIR/'src')
    run('plastex -c plastex.cfg web.tex')
    os.chdir(BP_DIR/'web')

    nonempty_graphs = []
    for file in os.listdir('.'):
        filename = os.fsdecode(file)
        if filename.startswith("dep_graph"):
            with open(filename, 'r') as f:
                s = f.read()
                for line in s.split('\n'):
                    if ".renderDot" in line:
                        if re.search('"[a-zA-Z]', line):
                            # This is a good heuristic for whether a graph has a node or not.
                            nonempty_graphs.append(filename)
            with open(filename, 'w') as f:
                def replace(line):
                    if ".renderDot" in line:
                        # Replace the font with Open Sans.
                        return line.replace('[', '[fontname="Open Sans",')
                    elif "theme-white.css" in line:
                        return line + '\n<link rel="stylesheet" href="styles/extra_styles.css" />'
                    else:
                        return line
                s = '\n'.join(replace(line) for line in s.split('\n'))
                f.write(s)

    for file in os.listdir('.'):
        filename = os.fsdecode(file)
        if filename.endswith(".html"):
            with open(filename, 'r') as f:
                s = f.read()
            with open(filename, 'w') as f:
                # Remove empty dependency graphs.
                to_remove = []
                for match in re.finditer(r'<li ><a href="([a-zA-Z0-9_.]*)">Chapter [a-zA-Z0-9]* graph<\/a><\/li>', s):
                    if match.group(1) not in nonempty_graphs:
                        to_remove.append(match.group(0))
                for item in to_remove:
                    s = s.replace(item, '')

                # Replace "Chapter A" with "Appendix A".
                s = re.sub(r"Chapter ([A-Z])", r"Appendix \1", s)
                f.write(s)

    os.chdir(cwd)

@task
def serve(ctx, port=8080, random_port=False):
    """
    Serve the blueprint website assuming the blueprint website is already built
    """

    class MyTCPServer(socketserver.TCPServer):
        def server_bind(self):
            import socket
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.socket.bind(self.server_address)

    cwd = os.getcwd()
    os.makedirs(BP_DIR/'web', exist_ok=True)
    os.chdir(BP_DIR/'web')

    if random_port:
        port = random.randint(8000, 8100)

    Handler = http.server.SimpleHTTPRequestHandler
    httpd = MyTCPServer(('', port), Handler)

    try:
        (ip, port) = httpd.server_address
        ip = ip or 'localhost'
        print(f'Serving http://{ip}:{port}/ ...')
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()

    os.chdir(cwd)
