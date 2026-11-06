# Snake Game (Text-based simulation)
# Demonstrates: mutation, game loops, list operations

fn new_game(width, height) => {
  width: width,
  height: height,
  snake: [[5, 5], [5, 4], [5, 3]],
  food: [3, 7],
  direction: [0, 1],
  score: 0,
  alive: true
}

fn move_snake(game) {
  let head_r = game.snake[0][0] + game.direction[0]
  let head_c = game.snake[0][1] + game.direction[1]

  # Check walls
  if head_r < 0 or head_r >= game.height or head_c < 0 or head_c >= game.width {
    game.alive = false
    ret nil
  }

  # Check self collision
  for seg in game.snake {
    if seg[0] == head_r and seg[1] == head_c {
      game.alive = false
      ret nil
    }
  }

  # Move: add new head
  let mut new_snake = [[head_r, head_c]]
  for seg in game.snake {
    new_snake = push(new_snake, seg)
  }

  # Check food
  if head_r == game.food[0] and head_c == game.food[1] {
    game.score = game.score + 1
    # New food position (simple deterministic)
    game.food = [(game.food[0] + 3) % game.height, (game.food[1] + 7) % game.width]
    game.snake = new_snake
  } el {
    # Remove tail
    game.snake = take(new_snake, len(new_snake) - 1)
  }
}

fn display_game(game) {
  for r in 0..game.height {
    let mut row = ""
    for c in 0..game.width {
      let mut ch = "."
      if r == game.food[0] and c == game.food[1] { ch = "*" }
      for i in 0..len(game.snake) {
        let seg = game.snake[i]
        if seg[0] == r and seg[1] == c {
          ch = if i == 0 { "@" } el { "o" }
        }
      }
      row = row ++ ch
    }
    print(row)
  }
  print("Score: {game.score}")
  print("")
}

# Simulate a game
print("=== Snake Game ===")
let mut game = new_game(10, 10)

# Pre-programmed moves: right, right, down, down, left
let moves = [[0, 1], [0, 1], [1, 0], [1, 0], [0, -1], [0, -1], [-1, 0], [0, 1], [0, 1], [1, 0]]

for m in moves {
  if not game.alive { ret nil }
  game.direction = m
  move_snake(game)
}

display_game(game)

if game.alive {
  print("Snake is alive! Length: {len(game.snake)}")
} el {
  print("Game Over!")
}

