# Arc Standard Library: prompt module
# Template management, token counting, and context windowing for AI agents

## Template filling — replace <<var>> placeholders with values from a map
## Example: template("Hello <<name>>", {name: "World"}) => "Hello World"
pub fn template(tmpl, vars) {
  __native("prompt.template", tmpl, vars)
}

## Estimate token count (~4 chars per token)
pub fn token_count(text) {
  __native("prompt.token_count", text)
}

## Truncate text to fit within a token limit
pub fn token_truncate(text, max_tokens) {
  __native("prompt.token_truncate", text, max_tokens)
}

## Fit as many messages as possible within a token budget (keeps newest)
## Each message should be a map with at least a "content" key
pub fn context_window(messages, max_tokens) {
  __native("prompt.context_window", messages, max_tokens)
}

## Split text into chunks that fit within token limits
pub fn chunk(text, max_tokens) {
  __native("prompt.chunk", text, max_tokens)
}

## Format a system prompt
pub fn system_prompt(role, instructions) {
  {role: "system", content: "You are " ++ role ++ ". " ++ instructions}
}

## Format a user message
pub fn user_message(text) {
  {role: "user", content: text}
}

## Format an assistant message
pub fn assistant_message(text) {
  {role: "assistant", content: text}
}

## Format a list of messages into a chat string
pub fn format_chat(messages) {
  messages |> map(m => "[" ++ m.role ++ "]: " ++ m.content) |> fold("", (acc, line) => if acc == "" { line } el { acc ++ "\n" ++ line })
}
