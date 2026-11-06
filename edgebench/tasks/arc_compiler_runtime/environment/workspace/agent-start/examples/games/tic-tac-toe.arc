# Tic-Tac-Toe
# Demonstrates: lists, mutation, pattern matching, game logic

fn new_board() => [" ", " ", " ", " ", " ", " ", " ", " ", " "]

fn display_board(b) {
  print(" {b[0]} | {b[1]} | {b[2]} ")
  print("-----------")
  print(" {b[3]} | {b[4]} | {b[5]} ")
  print("-----------")
  print(" {b[6]} | {b[7]} | {b[8]} ")
  print("")
}

fn check_winner(b) {
  let lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6]
  ]
  for line in lines {
    let a = b[line[0]]
    let bb = b[line[1]]
    let c = b[line[2]]
    if a != " " and a == bb and bb == c {
      ret a
    }
  }
  nil
}

fn is_full(b) {
  let empty = b |> filter(c => c == " ")
  len(empty) == 0
}

fn make_move(b, pos, player) {
  if pos < 0 or pos > 8 { ret Err("Invalid position") }
  if b[pos] != " " { ret Err("Position occupied") }
  b[pos] = player
  Ok(b)
}

fn find_best_move(b, player) {
  # Simple AI: try center, corners, then edges
  let priority = [4, 0, 2, 6, 8, 1, 3, 5, 7]
  for pos in priority {
    if b[pos] == " " { ret pos }
  }
  -1
}

# Play a sample game
fn play_game() {
  print("=== Tic-Tac-Toe ===")
  let mut board = new_board()
  let players = ["X", "O"]

  for turn in 0..9 {
    let player = players[turn % 2]
    let pos = find_best_move(board, player)
    if pos < 0 { ret nil }
    let result = make_move(board, pos, player)
    if is_err(result) {
      print("Error: {unwrap_err(result)}")
    }

    let winner = check_winner(board)
    if winner != nil {
      display_board(board)
      print("{winner} wins!")
      ret nil
    }
    if is_full(board) {
      display_board(board)
      print("Draw!")
      ret nil
    }
  }

  display_board(board)
  print("Game over!")
}

play_game()
