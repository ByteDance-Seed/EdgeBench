# ============================================================================
# REST API Client Library in Arc
# ============================================================================
# Full-featured HTTP client with base URL, auth headers, request/response
# interceptors via pipeline, retry logic, pagination, rate limiting, and
# response caching.
# Demonstrates: closures, pipelines, pattern matching, maps, lists, mutation,
# string interpolation, higher-order functions, error handling, destructuring
# ============================================================================

use http
use json
use datetime
use error
use crypto
use collections

# --- Client Builder ---

pub fn create(base_url) => {
    base_url: base_url,
    headers: {},
    timeout: 30000,
    retries: 3,
    retry_delay: 1000,
    interceptors: {request: [], response: []},
    cache: {enabled: false, store: {}, ttl: 300},
    rate_limit: {enabled: false, max_requests: 100, window_ms: 60000, timestamps: []},
    auth: nil,
    debug: false
}

# --- Configuration (Builder Pattern) ---

pub fn with_header(client, name, value) {
    client.headers[name] = value
    client
}

pub fn with_timeout(client, ms) {
    client.timeout = ms
    client
}

pub fn with_retries(client, count, delay_ms) {
    client.retries = count
    client.retry_delay = delay_ms
    client
}

pub fn with_debug(client, enabled) {
    client.debug = enabled
    client
}

# --- Authentication ---

pub fn with_bearer_token(client, token) {
    client.auth = {kind: "bearer", token: token}
    client.headers["Authorization"] = "Bearer {token}"
    client
}

pub fn with_basic_auth(client, username, password) {
    let encoded = crypto.base64_encode("{username}:{password}")
    client.auth = {kind: "basic", username: username}
    client.headers["Authorization"] = "Basic {encoded}"
    client
}

pub fn with_api_key(client, key, header_name) {
    let name = header_name or "X-API-Key"
    client.auth = {kind: "api_key", header: name}
    client.headers[name] = key
    client
}

# --- Interceptors ---

pub fn add_request_interceptor(client, interceptor) {
    client.interceptors.request = client.interceptors.request ++ [interceptor]
    client
}

pub fn add_response_interceptor(client, interceptor) {
    client.interceptors.response = client.interceptors.response ++ [interceptor]
    client
}

fn apply_request_interceptors(client, request) {
    let mut req = request
    for interceptor in client.interceptors.request {
        req = interceptor(req)
    }
    req
}

fn apply_response_interceptors(client, response) {
    let mut resp = response
    for interceptor in client.interceptors.response {
        resp = interceptor(resp)
    }
    resp
}

# --- Rate Limiting ---

pub fn with_rate_limit(client, max_requests, window_ms) {
    client.rate_limit = {
        enabled: true,
        max_requests: max_requests,
        window_ms: window_ms,
        timestamps: []
    }
    client
}

fn check_rate_limit(client) {
    if not client.rate_limit.enabled { ret true }

    let now = datetime.now()
    let window_start = now - client.rate_limit.window_ms

    # Remove old timestamps
    client.rate_limit.timestamps = client.rate_limit.timestamps
        |> filter(ts => ts > window_start)

    if len(client.rate_limit.timestamps) >= client.rate_limit.max_requests {
        ret false
    }

    client.rate_limit.timestamps = client.rate_limit.timestamps ++ [now]
    true
}

# --- Caching ---

pub fn with_cache(client, ttl_seconds) {
    client.cache = {
        enabled: true,
        store: {},
        ttl: ttl_seconds
    }
    client
}

fn cache_key(method, url, params) {
    let raw = "{method}:{url}:{json.to_json(params or {})}"
    crypto.sha256(raw)
}

fn get_cached(client, key) {
    if not client.cache.enabled { ret nil }
    let entry = client.cache.store[key]
    if entry == nil { ret nil }

    let now = datetime.now()
    if now - entry.timestamp > client.cache.ttl * 1000 {
        # Expired
        client.cache.store[key] = nil
        ret nil
    }
    entry.data
}

fn set_cached(client, key, data) {
    if not client.cache.enabled { ret }
    client.cache.store[key] = {
        data: data,
        timestamp: datetime.now()
    }
}

pub fn clear_cache(client) {
    client.cache.store = {}
    client
}

# --- Core Request ---

fn build_url(client, path, params) {
    let mut url = "{client.base_url}{path}"

    if params != nil and len(keys(params)) > 0 {
        let query = keys(params)
            |> map(k => "{k}={params[k]}")
            |> join("&")
        url = "{url}?{query}"
    }
    url
}

fn do_request(client, method, path, options) {
    let params = options.params or nil
    let body = options.body or nil
    let extra_headers = options.headers or {}

    # Rate limit check
    if not check_rate_limit(client) {
        ret {
            ok: false,
            status: 429,
            error: "Rate limit exceeded",
            data: nil,
            headers: {}
        }
    }

    # Check cache for GET requests
    if method == "GET" {
        let ck = cache_key(method, path, params)
        let cached = get_cached(client, ck)
        if cached != nil {
            if client.debug { print("[CACHE HIT] {method} {path}") }
            ret {ok: true, status: 200, data: cached, headers: {}, cached: true}
        }
    }

    let url = build_url(client, path, params)

    # Merge headers
    let mut headers = {}
    for k in keys(client.headers) {
        headers[k] = client.headers[k]
    }
    for k in keys(extra_headers) {
        headers[k] = extra_headers[k]
    }
    headers["Content-Type"] = headers["Content-Type"] or "application/json"
    headers["Accept"] = headers["Accept"] or "application/json"

    # Build request object
    let mut request = {
        method: method,
        url: url,
        headers: headers,
        body: if body != nil { json.to_json(body) } el { nil },
        timeout: client.timeout
    }

    # Apply request interceptors
    request = apply_request_interceptors(client, request)

    if client.debug {
        print("[{method}] {url}")
        if body != nil { print("[BODY] {json.to_json(body)}") }
    }

    # Execute with retries
    let mut last_error = nil
    for attempt in 0..client.retries {
        let result = error.try(() => http.request(request))

        if result.ok == true {
            let response = result.value
            let mut resp = {
                ok: response.status >= 200 and response.status < 300,
                status: response.status,
                data: parse_response(response),
                headers: response.headers or {},
                cached: false
            }

            resp = apply_response_interceptors(client, resp)

            if client.debug {
                print("[{response.status}] bytes")
            }

            if method == "GET" and resp.ok {
                let ck = cache_key(method, path, params)
                set_cached(client, ck, resp.data)
            }

            if response.status >= 500 and attempt < client.retries - 1 {
                if client.debug { print("[RETRY] Attempt {attempt + 1}/{client.retries}") }
                sleep(client.retry_delay * (attempt + 1))
            } el {
                ret resp
            }
        } el {
            last_error = result.error
            if client.debug {
                print("[ERROR] Attempt {attempt + 1}: {last_error}")
            }
            if attempt < client.retries - 1 {
                sleep(client.retry_delay * (attempt + 1))
            }
        }
    }

    {ok: false, status: 0, error: "Request failed after {client.retries} retries: {last_error}", data: nil}
}

fn parse_response(response) {
    let ct = response.headers["Content-Type"]
    if ct != nil and contains(ct, "json") {
        let decoded = error.try(() => json.from_json(response.body))
        if decoded.ok == true { decoded.value } el { response.body }
    } el {
        response.body
    }
}

fn sleep(ms) {
    # Placeholder for actual sleep
    let _ = ms
}

# --- HTTP Methods ---

pub fn get(client, path, params) =>
    do_request(client, "GET", path, {params: params})

pub fn post(client, path, body) =>
    do_request(client, "POST", path, {body: body})

pub fn put(client, path, body) =>
    do_request(client, "PUT", path, {body: body})

pub fn patch(client, path, body) =>
    do_request(client, "PATCH", path, {body: body})

pub fn delete(client, path) =>
    do_request(client, "DELETE", path, {})

# --- Pagination ---

pub fn paginate(client, path, page_param, per_page, max_pages) {
    let mut all_data = []
    let mut page = 1

    loop {
        if page > max_pages { break }

        let params = {}
        params[page_param] = page
        params["per_page"] = per_page

        let resp = get(client, path, params)
        if not resp.ok { break }

        let data = if resp.data.items != nil { resp.data.items }
            el if resp.data.data != nil { resp.data.data }
            el if resp.data.results != nil { resp.data.results }
            el if is_list(resp.data) { resp.data }
            el { [] }

        if len(data) == 0 { break }

        all_data = all_data ++ data
        page = page + 1

        # Check if we got fewer than requested
        if len(data) < per_page { break }
    }

    {data: all_data, pages: page - 1, total: len(all_data)}
}

fn is_list(v) => type_of(v) == "list"
fn type_of(v) => match v {
    nil => "nil",
    true => "bool",
    false => "bool",
    _ => "other"
}

# --- Batch Requests ---

pub fn batch(client, requests) {
    requests |> map(req => {
        if req.method == "GET" { get(client, req.path, req.params) }
        el if req.method == "POST" { post(client, req.path, req.body) }
        el if req.method == "PUT" { put(client, req.path, req.body) }
        el if req.method == "DELETE" { delete(client, req.path) }
        el { {ok: false, error: "Unknown method"} }
    })
}

# --- Resource CRUD Helper ---

pub fn resource(client, base_path) => {
    list: (params) => get(client, base_path, params),
    get_one: (id) => get(client, "{base_path}/{id}", nil),
    create_one: (data) => post(client, base_path, data),
    update: (id, data) => put(client, "{base_path}/{id}", data),
    remove: (id) => delete(client, "{base_path}/{id}"),
    search: (query) => get(client, "{base_path}/search", {q: query})
}

# --- Demo ---

pub fn run() {
    print("=== REST API Client Demo ===\n")

    # Create client with full configuration
    let client = create("https://api.example.com/v1")
        |> with_bearer_token("eyJhbGciOiJIUzI1NiJ9.test-token")
        |> with_header("User-Agent", "Arc-HTTP-Client/1.0")
        |> with_timeout(10000)
        |> with_retries(3, 500)
        |> with_rate_limit(100, 60000)
        |> with_cache(300)
        |> with_debug(true)
        |> add_request_interceptor(req => {
            print("  [Interceptor] Adding request ID")
            req.headers["X-Request-ID"] = crypto.sha256("{datetime.now()}")
            req
        })
        |> add_response_interceptor(resp => {
            print("  [Interceptor] Response status: {resp.status}")
            resp
        })

    print("Client configured:")
    print("  Base URL: {client.base_url}")
    print("  Auth: {client.auth.kind}")
    print("  Timeout: {client.timeout}ms")
    print("  Retries: {client.retries}")
    print("  Cache TTL: {client.cache.ttl}s")
    print("  Rate limit: {client.rate_limit.max_requests}/min")

    # Resource helper
    print("\n--- Resource CRUD ---")
    let users = resource(client, "/users")
    print("Users resource created for /users")
    print("  .list()    => GET /users")
    print("  .get_one(1) => GET /users/1")
    print("  .create_one(\{name: 'Arc'\}) => POST /users")
    print("  .update(1, \{name: 'Updated'\}) => PUT /users/1")
    print("  .remove(1)  => DELETE /users/1")

    # Batch requests
    print("\n--- Batch Request ---")
    let batch_reqs = [
        {method: "GET", path: "/users", params: {limit: 10}},
        {method: "GET", path: "/posts", params: {limit: 5}},
        {method: "POST", path: "/events", body: {kind: "page_view", page: "/home"}}
    ]
    print("Batch of {len(batch_reqs)} requests prepared")

    # Pagination
    print("\n--- Pagination ---")
    print("paginate(client, '/users', 'page', 25, 10)")
    print("  Fetches up to 10 pages of 25 items each")

    # Cache demo
    print("\n--- Cache ---")
    let ck = cache_key("GET", "/users", {limit: 10})
    set_cached(client, ck, [{id: 1, name: "Test User"}])
    let cached = get_cached(client, ck)
    print("Cached data: {cached}")
    print("Clear cache:")
    let _ = clear_cache(client)
    print("  Cache cleared")

    # Interceptor pipeline demo
    print("\n--- Interceptor Pipeline ---")
    let logging_client = create("https://api.example.com")
        |> add_request_interceptor(req => {
            req.headers["X-Timestamp"] = "{datetime.now()}"
            req
        })
        |> add_request_interceptor(req => {
            req.headers["X-Correlation-ID"] = "corr-{datetime.now()}"
            req
        })
        |> add_response_interceptor(resp => {
            if not resp.ok {
                print("  ⚠ Request failed with status {resp.status}")
            }
            resp
        })
    print("Logging client with {len(logging_client.interceptors.request)} request interceptors")
    print("  and {len(logging_client.interceptors.response)} response interceptors")

    print("\n✓ API Client demo complete!")
}

run()
