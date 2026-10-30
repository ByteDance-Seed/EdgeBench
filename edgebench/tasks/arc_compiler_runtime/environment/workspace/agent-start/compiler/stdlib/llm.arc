# Arc Standard Library: llm module
# Multi-provider LLM API integration
# Makes it natural for AI agents to call other AI agents.

use json
use os

# --- Provider registry ---

pub fn providers() {
  [
    {name: "openai", base_url: "https://api.openai.com/v1", env_key: "OPENAI_API_KEY"},
    {name: "anthropic", base_url: "https://api.anthropic.com/v1", env_key: "ANTHROPIC_API_KEY"}
  ]
}

fn _provider_config(provider) {
  let all = providers()
  let mut found = nil
  for p in all {
    if p.name == provider { found = p }
  }
  if found == nil { error_new("llm", "Unknown LLM provider: " ++ provider) }
  found
}

fn _api_key(provider) {
  let config = _provider_config(provider)
  let key = os.get_env(config.env_key)
  if key == nil { error_new("llm", "Missing API key: set " ++ config.env_key ++ " environment variable") }
  key
}

# --- OpenAI payload construction ---

fn _openai_chat_payload(model, messages, options) {
  let mut payload = {}
  payload["model"] = model
  payload["messages"] = messages
  if options != nil {
    let ks = keys(options)
    for k in ks {
      payload[k] = options[k]
    }
  }
  payload
}

fn _openai_headers(api_key) {
  let mut h = {}
  h["Authorization"] = "Bearer " ++ api_key
  h["Content-Type"] = "application/json"
  h
}

# --- Anthropic payload construction ---

fn _anthropic_chat_payload(model, messages, options) {
  # Anthropic expects system message separate from messages
  let mut system_msg = nil
  let mut user_msgs = []
  for m in messages {
    if m.role == "system" {
      system_msg = m.content
    } el {
      user_msgs = push(user_msgs, m)
    }
  }
  let mut payload = {}
  payload["model"] = model
  payload["messages"] = user_msgs
  if system_msg != nil { payload["system"] = system_msg }
  payload["max_tokens"] = if options != nil and options["max_tokens"] != nil { options["max_tokens"] } el { 1024 }
  if options != nil {
    let ks = keys(options)
    for k in ks {
      if k != "max_tokens" { payload[k] = options[k] }
    }
  }
  payload
}

fn _anthropic_headers(api_key) {
  let mut h = {}
  h["x-api-key"] = api_key
  h["anthropic-version"] = "2023-06-01"
  h["Content-Type"] = "application/json"
  h
}

# --- Core API ---

# Send a chat completion request
# provider: "openai" | "anthropic"
# model: e.g. "gpt-4o", "claude-sonnet-4-20250514"
# messages: [{role: "user", content: "Hello"}]
# options: {temperature: 0.7, max_tokens: 1024} (optional)
pub fn chat(provider, model, messages, options) {
  let key = _api_key(provider)

  if provider == "openai" {
    let payload = _openai_chat_payload(model, messages, options)
    let body = json.to_json(payload)
    let headers = _openai_headers(key)
    let resp = @POST "https://api.openai.com/v1/chat/completions" {data: body, headers: headers}
    if resp.ok and resp.status == 200 {
      let data = resp.data
      {ok: true, content: data.choices[0].message.content, usage: data.usage, raw: data}
    } el {
      {ok: false, error: resp.data, status: resp.status}
    }
  } el if provider == "anthropic" {
    let payload = _anthropic_chat_payload(model, messages, options)
    let body = json.to_json(payload)
    let headers = _anthropic_headers(key)
    let resp = @POST "https://api.anthropic.com/v1/messages" {data: body, headers: headers}
    if resp.ok and resp.status == 200 {
      let data = resp.data
      let content = if type_of(data.content) == "list" and len(data.content) > 0 {
        data.content[0].text
      } el { nil }
      {ok: true, content: content, usage: data.usage, raw: data}
    } el {
      {ok: false, error: resp.data, status: resp.status}
    }
  } el {
    error_new("llm", "Unsupported provider: " ++ provider)
  }
}

# Simple text completion (wraps chat with a single user message)
pub fn complete(provider, model, prompt, options) {
  let messages = [{role: "user", content: prompt}]
  chat(provider, model, messages, options)
}

# Streaming chat — calls callback with each chunk
# Note: true streaming requires SSE parsing; this simulates via full response
pub fn stream(provider, model, messages, callback) {
  # For now, do a regular call and invoke callback with the full response
  # True SSE streaming would require async I/O support in the runtime
  let result = chat(provider, model, messages, nil)
  if result.ok {
    callback(result.content)
  }
  result
}

# List available models for a provider
pub fn models(provider) {
  let key = _api_key(provider)

  if provider == "openai" {
    let headers = _openai_headers(key)
    let resp = @GET "https://api.openai.com/v1/models" {headers: headers}
    if resp.ok and resp.status == 200 {
      map(resp.data.data, m => m.id)
    } el {
      []
    }
  } el if provider == "anthropic" {
    # Anthropic doesn't have a public models endpoint; return known models
    [
      "claude-sonnet-4-20250514",
      "claude-opus-4-20250514",
      "claude-haiku-35-20241022",
      "claude-sonnet-3-5-20241022"
    ]
  } el {
    []
  }
}

# Estimate API cost in USD
# Pricing approximate as of 2025
pub fn estimate_cost(model, input_tokens, output_tokens) {
  let pricing = _model_pricing(model)
  let input_cost = (input_tokens / 1000000.0) * pricing.input
  let output_cost = (output_tokens / 1000000.0) * pricing.output
  {input_cost: input_cost, output_cost: output_cost, total: input_cost + output_cost, currency: "USD"}
}

fn _model_pricing(model) {
  # Prices per million tokens (input, output)
  if starts(model, "gpt-4o-mini") { {input: 0.15, output: 0.60} }
  el if starts(model, "gpt-4o") { {input: 2.50, output: 10.00} }
  el if starts(model, "gpt-4-turbo") { {input: 10.00, output: 30.00} }
  el if starts(model, "gpt-3.5") { {input: 0.50, output: 1.50} }
  el if contains(model, "opus") { {input: 15.00, output: 75.00} }
  el if contains(model, "sonnet") { {input: 3.00, output: 15.00} }
  el if contains(model, "haiku") { {input: 0.80, output: 4.00} }
  el { {input: 1.00, output: 3.00} }  # fallback estimate
}
