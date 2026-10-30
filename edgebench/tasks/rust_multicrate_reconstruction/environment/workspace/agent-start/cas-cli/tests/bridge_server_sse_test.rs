//! Integration test for the bridge server SSE session events endpoint.

use std::io::{BufRead, BufReader, Read, Write};
use std::net::TcpStream;
use std::time::Duration;

use tempfile::TempDir;

use cas::ui::factory::{SessionManager, create_metadata};

fn cas_bin() -> std::path::PathBuf { todo!() }

#[test]
fn bridge_server_sse_emits_heartbeat() {
    let home = TempDir::new().unwrap();
    let project = TempDir::new().unwrap();

    // Ensure in-process helpers (SessionManager/create_metadata) use the temp HOME too.
    unsafe { std::env::set_var("HOME", home.path()) };

    // Initialize CAS in the project (creates .cas/)
    std::process::Command::new(cas_bin())
        .current_dir(project.path())
        .env("HOME", home.path())
        .env_remove("CAS_ROOT")
        .args(["init", "--yes"])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .expect("failed to run cas init");
    // Failing init leads to confusing hangs later in the test.
    assert!(
        project.path().join(".cas").exists(),
        "expected project to be initialized with .cas/"
    );

    // Create a fake running session metadata entry under this HOME
    let session_name = "factory-test-sse";
    let workers = vec!["worker-a".to_string()];
    let metadata = create_metadata(
        session_name,
        std::process::id(), // is_running=true
        "supervisor-x",
        &workers,
        None,
        Some(project.path().to_string_lossy().as_ref()),
        None,
    );
    let manager = SessionManager::new();
    manager.save_metadata(&metadata).unwrap();

    // Make it attachable by creating the socket file path referenced in metadata.
    let sock_path = std::path::Path::new(&metadata.socket_path);
    if let Some(parent) = sock_path.parent() {
        std::fs::create_dir_all(parent).unwrap();
    }
    std::fs::write(sock_path, b"").unwrap();

    // Start the bridge server with the same temp HOME.
    let mut child = std::process::Command::new(cas_bin())
        .args(["bridge", "serve", "--json", "--port", "0"])
        .env("HOME", home.path())
        .env_remove("CAS_ROOT")
        .env("CAS_SKIP_FACTORY_TOOLING", "1")
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .spawn()
        .expect("failed to start bridge server");

    let stdout = child.stdout.take().expect("missing stdout");
    let mut reader = BufReader::new(stdout);
    let mut line = String::new();
    reader
        .read_line(&mut line)
        .expect("failed to read serve json");
    let info: serde_json::Value = serde_json::from_str(&line).expect("invalid serve json");

    let base_url = info["base_url"].as_str().unwrap().to_string();
    let token = info["token"].as_str().unwrap().to_string();

    let url = format!(
        "/v1/sessions/{session_name}/events?include_status=false&poll_ms=50&heartbeat_ms=250"
    );

    let agent = ureq::AgentBuilder::new()
        .timeout_connect(Duration::from_secs(2))
        .timeout_read(Duration::from_secs(2))
        .build();

    // Use a raw HTTP/1.1 request here because tiny_http cannot stream chunked
    // responses to HTTP/1.0 clients.
    let base = base_url
        .strip_prefix("http://")
        .expect("expected http:// base_url");
    let (host, port_str) = base.split_once(':').expect("expected host:port");
    let port: u16 = port_str.parse().expect("invalid port");

    let mut s = TcpStream::connect((host, port)).expect("connect failed");
    s.set_read_timeout(Some(Duration::from_secs(3)))
        .expect("set_read_timeout failed");

    let req = format!(
        "GET {url} HTTP/1.1\r\nHost: {host}:{port}\r\nAuthorization: Bearer {token}\r\nAccept: text/event-stream\r\nConnection: close\r\n\r\n"
    );
    s.write_all(req.as_bytes()).expect("write failed");

    let start = std::time::Instant::now();
    let mut out = String::new();
    let mut buf = [0u8; 2048];
    while start.elapsed() < Duration::from_secs(3) {
        match s.read(&mut buf) {
            Ok(0) => break,
            Ok(n) => {
                out.push_str(&String::from_utf8_lossy(&buf[..n]));
                if out.contains(": connected") {
                    break;
                }
            }
            Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => continue,
            Err(e) => panic!("read failed: {e:?}"),
        }
    }

    assert!(out.contains("HTTP/1.1 200"), "unexpected response: {out:?}");
    assert!(
        out.to_ascii_lowercase().contains("text/event-stream"),
        "missing content-type: {out:?}"
    );
    assert!(
        out.contains(": connected"),
        "expected initial connected comment frame: {out:?}"
    );

    // Shutdown
    let _ = agent
        .post(&format!("{base_url}/v1/shutdown"))
        .set("Authorization", &format!("Bearer {token}"))
        .call()
        .unwrap();

    // Avoid a hanging test if the server fails to terminate.
    for _ in 0..50 {
        if let Some(status) = child.try_wait().expect("try_wait failed") {
            assert!(status.success());
            return;
        }
        std::thread::sleep(Duration::from_millis(100));
    }

    let _ = child.kill();
    panic!("bridge server did not exit after shutdown");
}
