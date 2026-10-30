# Chat Protocol
# Demonstrates: maps, mutation, pattern matching, pipelines, closures

let mut rooms = {}
let mut users = {}

fn register_user(name) {
  users[name] = {name: name, rooms: [], online: true}
  Ok(name)
}

fn create_room(name) {
  rooms[name] = {name: name, members: [], messages: []}
  Ok(name)
}

fn join_room(user, room) {
  if users[user] == nil { ret Err("Unknown user: {user}") }
  if rooms[room] == nil { ret Err("Unknown room: {room}") }
  rooms[room].members = push(rooms[room].members, user)
  users[user].rooms = push(users[user].rooms, room)
  send_system(room, "{user} joined the room")
  Ok(true)
}

fn send_message(user, room, text) {
  if rooms[room] == nil { ret Err("Unknown room") }
  let msg = {from: user, text: text, time: time_ms(), kind: "message"}
  rooms[room].messages = push(rooms[room].messages, msg)
  Ok(msg)
}

fn send_system(room, text) {
  let msg = {from: "system", text: text, time: time_ms(), kind: "system"}
  rooms[room].messages = push(rooms[room].messages, msg)
}

fn get_messages(room, limit = 10) {
  if rooms[room] == nil { ret [] }
  let msgs = rooms[room].messages
  let start = if len(msgs) > limit { len(msgs) - limit } el { 0 }
  drop(msgs, start)
}

fn display_messages(room) {
  let msgs = get_messages(room, 20)
  print("--- #{room} ---")
  for msg in msgs {
    let prefix = if msg.kind == "system" { "***" } el { msg.from }
    print("  [{prefix}] {msg.text}")
  }
  print("")
}

# Demo
print("=== Chat Protocol ===")

create_room("general")
create_room("random")

register_user("Alice")
register_user("Bob")
register_user("Charlie")

join_room("Alice", "general")
join_room("Bob", "general")
join_room("Charlie", "general")
join_room("Alice", "random")

send_message("Alice", "general", "Hey everyone!")
send_message("Bob", "general", "Hi Alice! How are you?")
send_message("Alice", "general", "Great! Working on some Arc code")
send_message("Charlie", "general", "Arc is awesome!")
send_message("Bob", "general", "Agreed. The pipeline syntax is clean")
send_message("Alice", "random", "Anyone here?")

display_messages("general")
display_messages("random")

print("Alice's rooms: {users["Alice"].rooms}")
print("General members: {rooms["general"].members}")
print("Total messages in general: {len(rooms["general"].messages)}")
