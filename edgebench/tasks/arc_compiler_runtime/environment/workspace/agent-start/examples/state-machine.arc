# State Machine
# Demonstrates: maps, closures, pattern matching, mutation

fn new_machine(initial) => {
  state: initial,
  transitions: {},
  history: [initial]
}

fn add_transition(machine, from, event, to, action) {
  let key = from ++ ":" ++ event
  machine.transitions[key] = {to: to, action: action}
}

fn send_event(machine, event) {
  let key = machine.state ++ ":" ++ event
  let transition = machine.transitions[key]
  if transition == nil {
    print("  No transition from '{machine.state}' on '{event}'")
    ret machine.state
  }
  let old_state = machine.state
  machine.state = transition.to
  machine.history = push(machine.history, transition.to)
  if transition.action != nil {
    transition.action(old_state, event, transition.to)
  }
  machine.state
}

# Traffic light state machine
print("=== State Machine: Traffic Light ===")
let mut light = new_machine("red")

let log_transition = (from, event, to) => {
  print("  {from} --({event})--> {to}")
}

add_transition(light, "red", "timer", "green", log_transition)
add_transition(light, "green", "timer", "yellow", log_transition)
add_transition(light, "yellow", "timer", "red", log_transition)
add_transition(light, "red", "emergency", "red", (f, e, t) => print("  EMERGENCY: staying red"))

# Run through cycles
let events = ["timer", "timer", "timer", "timer", "emergency", "timer"]
for event in events {
  send_event(light, event)
}

print("History: {light.history}")

# Door state machine
print("\n=== State Machine: Door ===")
let mut door = new_machine("locked")

add_transition(door, "locked", "unlock", "closed", log_transition)
add_transition(door, "closed", "open", "opened", log_transition)
add_transition(door, "opened", "close", "closed", log_transition)
add_transition(door, "closed", "lock", "locked", log_transition)

let door_events = ["unlock", "open", "close", "lock", "open"]
for event in door_events {
  send_event(door, event)
}
print("Door history: {door.history}")
