# ============================================================================
# HTTP Server Framework in Arc
# ============================================================================
# A simplified HTTP server with request parsing, route matching, middleware,
# JSON helpers, and CORS support.
# Demonstrates: closures, pipelines, pattern matching, maps, lists,
# string interpolation, higher-order functions.
# ============================================================================

use regex
use json
use collections
use datetime

# --- HTTP Request Parsing ---

pub fn parse_request(raw) {
    let lines = raw |> split("\r\n")
    let request_line = lines[0]

    let parts = regex.capture("^(GET|POST|PUT|DELETE|PATCH|OPTIONS|HEAD)\\s+(\\S+)\\s+HTTP/(\\S+)", request_line)
    if parts == nil {
        ret {error: "Malformed request line"}
    }

    let method = parts[1]
    let full_path = parts[2]
    let version = parts[3]

    # Parse path and query string
    let path_parts = full_path |> split("?")
    let path = path_parts[0]
    let query = if len(path_parts) > 1 { parse_query(path_parts[1]) } el { {} }

    # Parse headers
    let mut headers = {}
    let mut idx = 1
    for idx in 1..len(lines) {
        let line = lines[idx]
        if line == "" { idx = idx }
        el {
            let kv = regex.capture("^([^:]+):\\s*(.+)$", line)
            if kv != nil {
                headers[lower(kv[1])] = kv[2]
            }
        }
    }

    # Parse body (everything after blank line)
    let mut body = ""
    let mut found_blank = false
    for i in 1..len(lines) {
        if found_blank {
            body = body ++ lines[i]
        } el if lines[i] == "" {
            found_blank = true
        }
    }

    {
        method: method,
        path: path,
        query: query,
        version: version,
        headers: headers,
        body: body,
        params: {},
        raw: raw
    }
}

fn parse_query(qs) {
    let pairs = qs |> split("&")
    let mut params = {}
    for pair in pairs {
        let kv = pair |> split("=")
        if len(kv) == 2 {
            params[kv[0]] = kv[1]
        }
    }
    params
}

# --- HTTP Response Builder ---

pub fn response(status, body, headers) {
    let status_text = match status {
        200 => "OK",
        201 => "Created",
        204 => "No Content",
        301 => "Moved Permanently",
        302 => "Found",
        400 => "Bad Request",
        401 => "Unauthorized",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        500 => "Internal Server Error",
        _ => "Unknown"
    }

    let default_headers = {
        content_type: "text/plain",
        content_length: "{len(body)}",
        server: "Arc-HTTP/1.0"
    }

    let header_str = keys(headers) |> map(k => "{k}: {headers[k]}") |> join("\r\n")
    "HTTP/1.1 {status} {status_text}\r\n{header_str}\r\n\r\n{body}"
}

pub fn json_response(status, data) {
    let body = json.to_json(data)
    response(status, body, {content_type: "application/json"})
}

pub fn html_response(status, html) {
    response(status, html, {content_type: "text/html; charset=utf-8"})
}

pub fn redirect(url, permanent) {
    let status = if permanent { 301 } el { 302 }
    response(status, "", {location: url})
}

pub fn not_found(message) {
    json_response(404, {error: message or "Not Found"})
}

# --- Router ---

pub fn router() => {
    routes: [],
    middleware: [],
    error_handler: err => json_response(500, {error: "{err}"})
}

pub fn add_route(r, method, pattern, handler) {
    let route = {
        method: method |> upper,
        pattern: pattern,
        handler: handler
    }
    let mut router = r
    router.routes = push(router.routes, route)
    router
}

pub fn get_route(r, pattern, handler) => add_route(r, "GET", pattern, handler)
pub fn post_route(r, pattern, handler) => add_route(r, "POST", pattern, handler)
pub fn put_route(r, pattern, handler) => add_route(r, "PUT", pattern, handler)
pub fn delete_route(r, pattern, handler) => add_route(r, "DELETE", pattern, handler)

# --- Middleware ---

pub fn use_middleware(r, middleware_fn) {
    let mut router = r
    router.middleware = push(router.middleware, middleware_fn)
    router
}

pub fn cors_middleware(allowed_origins) => (req, next) => {
    let origin = req.headers.origin or "*"
    if req.method == "OPTIONS" {
        response(204, "", {
            access_control_allow_origin: origin,
            access_control_allow_methods: "GET, POST, PUT, DELETE, OPTIONS",
            access_control_allow_headers: "Content-Type, Authorization"
        })
    } el {
        next(req)
    }
}

pub fn logger_middleware() => (req, next) => {
    let res = next(req)
    print("[LOG] {req.method} {req.path}")
    res
}

pub fn json_body_middleware() => (req, next) => {
    let content_type = req.headers.content_type or ""
    let mut r = req
    if contains(content_type, "json") {
        r.json_body = json.from_json(req.body)
    }
    next(r)
}

# --- Route Matching and Dispatch ---

fn match_route(r, req) {
    find(r.routes, route => route.method == req.method and route.pattern == req.path)
}

fn match_route_prefix(r, req) {
    find(r.routes, route => {
        route.method == req.method and starts(req.path, route.pattern)
    })
}

pub fn dispatch(r, raw_request) {
    let req = parse_request(raw_request)

    if req.error != nil {
        ret json_response(400, {error: req.error})
    }

    # Build handler
    let handler = req => {
        let route = match_route(r, req)
        let route2 = if route == nil { match_route_prefix(r, req) } el { route }
        if route2 == nil {
            not_found("No route for {req.method} {req.path}")
        } el {
            route2.handler(req)
        }
    }

    # Apply middleware (simplified - just chain them)
    let chain = reduce(r.middleware |> reverse, handler, (next, mw) => {
        req => mw(req, next)
    })

    chain(req)
}

# --- Main Demo ---

fn main() {
    print("=== Arc HTTP Server Demo ===\n")

    # In-memory data store
    let mut items = [
        {id: 1, name: "Widget", price: 9.99},
        {id: 2, name: "Gadget", price: 24.99},
        {id: 3, name: "Doohickey", price: 4.99}
    ]
    let mut next_id = 4

    let app = router()
        |> use_middleware(logger_middleware())
        |> use_middleware(cors_middleware(["*"]))
        |> use_middleware(json_body_middleware())
        |> get_route("/", req => html_response(200, "<h1>Welcome to Arc Server</h1>"))
        |> get_route("/api/items", req => json_response(200, {items: items, count: len(items)}))
        |> post_route("/api/items", req => {
            let data = req.json_body or {}
            let item = {
                id: next_id,
                name: data.name or "unnamed",
                price: data.price or 0
            }
            next_id = next_id + 1
            items = push(items, item)
            json_response(201, item)
        })
        |> delete_route("/api/items", req => {
            json_response(200, {deleted: true})
        })
        |> get_route("/health", req => json_response(200, {
            status: "healthy",
            items_count: len(items)
        }))

    # Demo: simulate request dispatch
    print("Simulating requests:\n")

    let test_requests = [
        "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n",
        "GET /api/items HTTP/1.1\r\nHost: localhost\r\n\r\n",
        "POST /api/items HTTP/1.1\r\nHost: localhost\r\nContent-Type: application/json\r\n\r\n\{\"name\":\"Thingamajig\",\"price\":14.99\}",
        "GET /health HTTP/1.1\r\nHost: localhost\r\n\r\n",
        "GET /nonexistent HTTP/1.1\r\nHost: localhost\r\n\r\n"
    ]

    for raw in test_requests {
        let res = dispatch(app, raw)
        let preview = slice(res, 0, 80)
        print("Response: {preview}...\n")
    }
}

main()
