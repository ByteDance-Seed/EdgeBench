# Roguelike Dungeon Crawler (Text-based)
# Demonstrates: maps, mutation, random generation, game logic

fn new_dungeon(width, height) {
  let mut grid = []
  for r in 0..height {
    let mut row = []
    for c in 0..width {
      let is_wall = r == 0 or r == height - 1 or c == 0 or c == width - 1
      let ch = if is_wall { "#" } el { "." }
      row = push(row, ch)
    }
    grid = push(grid, row)
  }
  grid
}

fn place_items(grid, count, char, seed) {
  let h = len(grid)
  let w = len(grid[0])
  let mut s = seed
  let mut items = []
  for i in 0..count {
    s = (s * 1103515245 + 12345) % 2147483648
    let r = (abs(s) % (h - 2)) + 1
    s = (s * 1103515245 + 12345) % 2147483648
    let c = (abs(s) % (w - 2)) + 1
    if grid[r][c] == "." {
      grid[r][c] = char
      items = push(items, [r, c])
    }
  }
  items
}

fn display_dungeon(grid, player) {
  for r in 0..len(grid) {
    let mut row = ""
    for c in 0..len(grid[r]) {
      if r == player[0] and c == player[1] {
        row = row ++ "@"
      } el {
        row = row ++ grid[r][c]
      }
    }
    print(row)
  }
}

# Create dungeon
print("=== Roguelike Dungeon ===")
let mut grid = new_dungeon(20, 10)

# Place monsters and treasure
let monsters = place_items(grid, 3, "M", 42)
let treasure = place_items(grid, 5, "$", 137)

# Player starts at (1,1)
let mut player = [1, 1]
let mut hp = 100
let mut gold = 0

fn try_move(grid, player, dr, dc) {
  let nr = player[0] + dr
  let nc = player[1] + dc
  let cell = grid[nr][nc]
  match cell {
    "#" => print("  Blocked by wall!"),
    "M" => {
      hp = hp - 20
      grid[nr][nc] = "."
      player[0] = nr
      player[1] = nc
      print("  Monster! -20 HP (HP: {hp})")
    },
    "$" => {
      gold = gold + 10
      grid[nr][nc] = "."
      player[0] = nr
      player[1] = nc
      print("  Treasure! +10 gold (Gold: {gold})")
    },
    _ => {
      player[0] = nr
      player[1] = nc
    }
  }
}

# Simulate some moves
let moves = [[0, 1], [0, 1], [1, 0], [1, 0], [0, 1], [0, 1], [1, 0], [0, 1]]
print("Starting dungeon crawl...")
print("HP: {hp}, Gold: {gold}")
print("")

for m in moves {
  if hp <= 0 { ret nil }
  try_move(grid, player, m[0], m[1])
}

print("")
display_dungeon(grid, player)
print("")
print("Final stats - HP: {hp}, Gold: {gold}")
