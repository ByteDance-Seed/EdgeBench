# Conway's Game of Life
# Demonstrates: nested lists, mutation, comprehensions, pipelines

fn make_grid(rows, cols) {
  [
    [0 for _ in 0..cols]
    for _ in 0..rows
  ]
}

fn set_cell(grid, row, col, value) {
  let mut new_grid = []
  for r in 0..len(grid) {
    if r == row {
      let mut new_row = []
      for c in 0..len(grid[r]) {
        if c == col {
          new_row = push(new_row, value)
        } el {
          new_row = push(new_row, grid[r][c])
        }
      }
      new_grid = push(new_grid, new_row)
    } el {
      new_grid = push(new_grid, grid[r])
    }
  }
  new_grid
}

fn get_cell(grid, row, col) {
  if row < 0 or row >= len(grid) { ret 0 }
  if col < 0 or col >= len(grid[0]) { ret 0 }
  grid[row][col]
}

fn count_neighbors(grid, row, col) {
  let mut count = 0
  for dr in [-1, 0, 1] {
    for dc in [-1, 0, 1] {
      if dr != 0 or dc != 0 {
        count = count + get_cell(grid, row + dr, col + dc)
      }
    }
  }
  count
}

fn step(grid) {
  let rows = len(grid)
  let cols = len(grid[0])
  let mut new_grid = make_grid(rows, cols)
  for r in 0..rows {
    for c in 0..cols {
      let neighbors = count_neighbors(grid, r, c)
      let alive = grid[r][c]
      let new_val = if alive == 1 {
        if neighbors == 2 or neighbors == 3 { 1 } el { 0 }
      } el {
        if neighbors == 3 { 1 } el { 0 }
      }
      new_grid = set_cell(new_grid, r, c, new_val)
    }
  }
  new_grid
}

fn display(grid) {
  for row in grid {
    let line = row |> map(c => if c == 1 { "█" } el { "·" }) |> join("")
    print(line)
  }
  print("")
}

# Initialize with a glider
print("=== Game of Life ===")
let mut grid = make_grid(8, 8)
grid = set_cell(grid, 1, 2, 1)
grid = set_cell(grid, 2, 3, 1)
grid = set_cell(grid, 3, 1, 1)
grid = set_cell(grid, 3, 2, 1)
grid = set_cell(grid, 3, 3, 1)

print("Generation 0:")
display(grid)

for gen in 1..5 {
  grid = step(grid)
  print("Generation {gen}:")
  display(grid)
}
