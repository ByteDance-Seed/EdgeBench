# Mini Blockchain
# Demonstrates: maps, mutation, hashing, pipelines

fn hash_block(block) {
  let data = str(block.index) ++ block.prev_hash ++ str(block.timestamp) ++ str(block.data)
  # Simple hash simulation using crypto builtin
  crypto_hash("sha256", data)
}

fn new_block(index, data, prev_hash) {
  let block = {
    index: index,
    timestamp: time_ms(),
    data: data,
    prev_hash: prev_hash,
    hash: ""
  }
  block.hash = hash_block(block)
  block
}

fn genesis_block() => new_block(0, "Genesis Block", "0")

fn add_block(chain, data) {
  let prev = last(chain)
  let block = new_block(len(chain), data, prev.hash)
  push(chain, block)
}

fn is_valid(chain) {
  if len(chain) <= 1 { ret true }
  let mut i = 1
  for _ in 1..len(chain) {
    if i >= len(chain) { ret true }
    let current = chain[i]
    let previous = chain[i - 1]
    if current.prev_hash != previous.hash {
      ret false
    }
    i = i + 1
  }
  true
}

# Build a chain
print("=== Mini Blockchain ===")
let mut chain = [genesis_block()]

chain = add_block(chain, "Alice sends 10 to Bob")
chain = add_block(chain, "Bob sends 5 to Charlie")
chain = add_block(chain, "Charlie sends 3 to Alice")

for block in chain {
  print("Block {block.index}:")
  print("  Data: {block.data}")
  print("  Hash: {slice(block.hash, 0, 16)}...")
  print("  Prev: {slice(block.prev_hash, 0, 16)}...")
}

print("")
print("Chain valid: {is_valid(chain)}")
print("Chain length: {len(chain)}")
