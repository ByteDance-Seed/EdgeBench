# Todo App
# Demonstrates: maps, mutation, pipelines, pattern matching

fn new_todo(id, title) => {id: id, title: title, done: false}

fn toggle(todo) => {
  id: todo.id,
  title: todo.title,
  done: not todo.done
}

fn format_todo(todo) {
  let status = if todo.done { "[x]" } el { "[ ]" }
  "{status} {todo.id}. {todo.title}"
}

# Build a todo list
let mut todos = []
let mut next_id = 1

fn add_todo(title) {
  let todo = new_todo(next_id, title)
  todos = push(todos, todo)
  next_id = next_id + 1
  todo
}

fn complete_todo(id) {
  todos = todos |> map(t => if t.id == id { toggle(t) } el { t })
}

fn remove_todo(id) {
  todos = todos |> filter(t => t.id != id)
}

fn show_todos() {
  print("--- Todo List ---")
  if len(todos) == 0 {
    print("  (empty)")
  } el {
    for t in todos {
      print("  {format_todo(t)}")
    }
  }
  let done_count = todos |> filter(t => t.done) |> len
  print("  {done_count}/{len(todos)} completed")
  print("")
}

# Usage
print("=== Todo App ===")
add_todo("Buy groceries")
add_todo("Write Arc examples")
add_todo("Review pull requests")
add_todo("Walk the dog")
show_todos()

complete_todo(1)
complete_todo(3)
print("After completing #1 and #3:")
show_todos()

remove_todo(2)
print("After removing #2:")
show_todos()

add_todo("Deploy v0.5.6")
print("After adding new task:")
show_todos()
