//! Integration test for `cas bridge serve` helper HTTP server.

use std::io::{BufRead, BufReader};

#[test]
fn bridge_server_smoke() {
    let cas_bin = assert_cmd::cargo::cargo_bin!("cas");
    let mut child = std::process::Command::new(cas_bin)
        .args(["bridge", "serve", "--json", "--port", "0"])
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

    // Health
    let health = ureq::get(&format!("{base_url}/v1/health"))
        .set("Authorization", &format!("Bearer {token}"))
        .call()
        .unwrap()
        .into_json::<serde_json::Value>()
        .unwrap();
    assert_eq!(health["schema_version"], 1);
    assert_eq!(health["ok"], true);

    // Shutdown
    let shutdown = ureq::post(&format!("{base_url}/v1/shutdown"))
        .set("Authorization", &format!("Bearer {token}"))
        .call()
        .unwrap()
        .into_json::<serde_json::Value>()
        .unwrap();
    assert_eq!(shutdown["ok"], true);

    let status = child.wait().expect("wait failed");
    assert!(status.success());
}
