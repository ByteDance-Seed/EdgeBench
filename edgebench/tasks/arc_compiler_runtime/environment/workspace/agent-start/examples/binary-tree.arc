# Binary Search Tree
# Demonstrates: recursion, pattern matching, maps as structs, pipelines

# Tree nodes are maps: {value: n, left: node, right: node}

fn new_node(value) => {value: value, left: nil, right: nil}

fn insert(node, value) {
  if node == nil { ret new_node(value) }
  if value < node.value {
    {value: node.value, left: insert(node.left, value), right: node.right}
  } el if value > node.value {
    {value: node.value, left: node.left, right: insert(node.right, value)}
  } el {
    node
  }
}

fn search(node, value) {
  if node == nil { ret false }
  if value == node.value { ret true }
  if value < node.value { search(node.left, value) }
  el { search(node.right, value) }
}

fn inorder(node) {
  if node == nil { ret [] }
  inorder(node.left) ++ [node.value] ++ inorder(node.right)
}

fn tree_size(node) {
  if node == nil { ret 0 }
  1 + tree_size(node.left) + tree_size(node.right)
}

fn tree_height(node) {
  if node == nil { ret 0 }
  let lh = tree_height(node.left)
  let rh = tree_height(node.right)
  1 + max(lh, rh)
}

fn tree_min(node) {
  if node == nil { ret nil }
  if node.left == nil { ret node.value }
  tree_min(node.left)
}

fn tree_max(node) {
  if node == nil { ret nil }
  if node.right == nil { ret node.value }
  tree_max(node.right)
}

# Build a tree
let values = [5, 3, 7, 1, 4, 6, 8, 2, 9]
let mut tree = nil
for v in values {
  tree = insert(tree, v)
}

print("=== Binary Search Tree ===")
print("Inserted: {values}")
print("In-order: {inorder(tree)}")
print("Size: {tree_size(tree)}")
print("Height: {tree_height(tree)}")
print("Min: {tree_min(tree)}")
print("Max: {tree_max(tree)}")
print("Search 4: {search(tree, 4)}")
print("Search 10: {search(tree, 10)}")

# Insert more values
for v in [0, 10, 5] {
  tree = insert(tree, v)
}
print("After adding [0, 10, 5]: {inorder(tree)}")
print("New size: {tree_size(tree)}")
