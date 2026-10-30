# Graph Algorithms
# Demonstrates: maps, recursion, mutation, pipelines

fn new_graph() => {nodes: [], edges: {}}

fn add_node(g, name) {
  g.nodes = push(g.nodes, name)
  g.edges[name] = []
}

fn add_edge(g, from, to, weight = 1) {
  let existing = if g.edges[from] != nil { g.edges[from] } el { [] }
  g.edges[from] = push(existing, {to: to, weight: weight})
}

fn neighbors(g, node) {
  if g.edges[node] == nil { [] }
  el { g.edges[node] |> map(e => e.to) }
}

# BFS
fn bfs(g, start) {
  let mut visited = []
  let mut queue = [start]
  for _ in 0..(len(g.nodes) * 2) {
    if len(queue) == 0 { ret visited }
    let current = head(queue)
    queue = tail(queue)
    if contains(visited, current) {
      # skip
    } el {
      visited = push(visited, current)
      let nbrs = neighbors(g, current)
      for n in nbrs {
        if not contains(visited, n) {
          queue = push(queue, n)
        }
      }
    }
  }
  visited
}

# DFS
fn dfs(g, start) {
  let mut visited = []
  let mut stack = [start]
  for _ in 0..(len(g.nodes) * 2) {
    if len(stack) == 0 { ret visited }
    let current = last(stack)
    stack = take(stack, len(stack) - 1)
    if contains(visited, current) {
      # skip
    } el {
      visited = push(visited, current)
      let nbrs = neighbors(g, current)
      for n in reverse(nbrs) {
        if not contains(visited, n) {
          stack = push(stack, n)
        }
      }
    }
  }
  visited
}

# Has path
fn has_path(g, from, to) {
  let reachable = bfs(g, from)
  contains(reachable, to)
}

# Demo
print("=== Graph Algorithms ===")
let mut g = new_graph()

for name in ["A", "B", "C", "D", "E", "F"] {
  add_node(g, name)
}

add_edge(g, "A", "B")
add_edge(g, "A", "C")
add_edge(g, "B", "D")
add_edge(g, "C", "D")
add_edge(g, "D", "E")
add_edge(g, "B", "E")
add_edge(g, "F", "F")

print("BFS from A: {bfs(g, "A")}")
print("DFS from A: {dfs(g, "A")}")
print("Path A->E: {has_path(g, "A", "E")}")
print("Path A->F: {has_path(g, "A", "F")}")
print("Neighbors of A: {neighbors(g, "A")}")
print("Neighbors of D: {neighbors(g, "D")}")

