from copy import deepcopy
import os

from mathlibtools.lib import LeanProject, Path
import networkx as nx

proj = LeanProject.from_path(Path('.'))
graph = proj.import_graph
loops = deepcopy(graph)
local = deepcopy(graph)
globa = deepcopy(graph)

files = list(graph.nodes)

for name in files:
    if not name.startswith('loops.'):
        loops.remove_node(name)
    if not name.startswith('local.'):
        local.remove_node(name)
    if not name.startswith('global.'):
        globa.remove_node(name)

nx.nx_pydot.write_dot(loops, 'loops.dot')
nx.nx_pydot.write_dot(local, 'local.dot')
nx.nx_pydot.write_dot(globa, 'global.dot')
for name in ['loops', 'local', 'global']:
    os.system(f'dot {name}.dot -Tpdf > {name}.pdf')

