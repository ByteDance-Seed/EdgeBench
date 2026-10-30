# Learn Arc: Async & Tool Calls
# Extracted from Tutorial 4 — @GET/@POST, parallel fetch, Result handling

# --- Tool Calls ---
let user = @GET "api/users/42"
let created = @POST "api/users" {name: "Alice", role: "admin"}
@PUT "api/users/42" {name: "Alice", role: "superadmin"}
@DELETE "api/users/42"

# --- Parallel Fetch ---
let [users, posts, stats] = fetch [
  @GET "api/users",
  @GET "api/posts?limit=10",
  @GET "api/stats/today"
]

# --- Dashboard with parallel fetch ---
fn load_dashboard(user_id) {
  let [profile, notifications, feed, weather] = fetch [
    @GET "api/users/{user_id}",
    @GET "api/notifications?unread=true",
    @GET "api/feed?limit=20",
    @GET "api/weather?city=NYC"
  ]

  {
    greeting: "Welcome back, {profile.name}!",
    unread: len(notifications),
    top_stories: feed |> take(5) |> map(s => s.title),
    weather: weather.summary
  }
}

# --- Error Handling with Result ---
use result

let user_result = @GET "api/users/1"
if result.result_is_ok(user_result) {
  let u = result.result_unwrap(user_result)
  print("Found: {u.name}")
} el {
  print("Error fetching user")
}

# --- Nil coalescing ---
let name = user.name or "Anonymous"
let port = 8080

# --- Complete API Client ---
let BASE = "api.todos.example.com/v1"

fn get_todos(user_id) {
  @GET "{BASE}/users/{user_id}/todos"
}

fn create_todo(user_id, title) {
  @POST "{BASE}/users/{user_id}/todos" {
    title: title,
    completed: false
  }
}

fn toggle_todo(user_id, todo_id) {
  let todo = @GET "{BASE}/todos/{todo_id}"
  @PUT "{BASE}/todos/{todo_id}" {
    completed: not todo.completed
  }
}

fn todo_summary(user_id) {
  let todos = get_todos(user_id)
  let completed = todos |> filter(t => t.completed)
  let pending = todos |> filter(t => not t.completed)

  {
    total: len(todos),
    done: len(completed),
    pending_count: len(pending),
    next: pending |> take(3) |> map(t => t.title),
    progress: "{len(completed) * 100 / len(todos)}%"
  }
}

fn main() {
  let summary = todo_summary("user_123")
  print("Progress: {summary.progress}")
  print("Next up:")
  for title in summary.next {
    print("  * {title}")
  }
}

# --- Custom Tools ---
let llm_summary = @llm "Summarize this article"
let files = @shell "ls -la"
let db_users = @db "SELECT * FROM users WHERE active = true"
