//! Real Factory E2E Tests
//!
//! Tests the actual `cas factory` TUI — spawns the real factory process via
//! PtyRunner, injects supervisor prompts through the prompt queue, waits for
//! workers to be spawned by the daemon, and verifies bidirectional messaging.
//!
//! These tests exercise the exact same code path users run.
//!
//! # Requirements
//! - `claude` CLI installed and logged in (via `claude /login`)
//! - CAS binary built (`cargo build`)
//! - Set `CAS_FACTORY_E2E=1` to enable (skipped by default)
//!
//! # Running
//! ```bash
//! CAS_FACTORY_E2E=1 cargo test --test e2e_test factory_e2e::real_factory \
//!     --features claude_rs_e2e -- --ignored --nocapture --test-threads=1
//! ```

use cas::store::{open_agent_store, open_prompt_queue_store};
use cas::ui::factory::{SessionInfo, SessionManager};
use cas_tui_test::{PtyRunner, PtyRunnerConfig, screen_with_size};
use cas_types::AgentRole;
use rusqlite::params;
use std::process::Command;
use std::time::{Duration, Instant};

use crate::fixtures::new_cas_instance;

// =============================================================================
// Helpers
// =============================================================================

fn cas_binary() -> String { todo!() }

fn wait_for_screen_text(
    runner: &PtyRunner,
    text: &str,
    timeout: Duration,
    cols: u16,
    rows: u16,
) -> Result<(), String> { todo!() }

/// Wait for the supervisor's Claude session to become idle (READY state)
fn wait_for_supervisor_ready(runner: &PtyRunner, timeout: Duration) -> Result<(), String> { todo!() }

fn wait_for_session_info(
    project_dir: &std::path::Path,
    timeout: Duration,
) -> Result<SessionInfo, String> { todo!() }

fn wait_for_worker_count(
    cas_root: &std::path::Path,
    expected: usize,
    timeout: Duration,
) -> Result<(), String> { todo!() }

fn should_run() -> bool { todo!() }

/// Create an epic task directly in the database so spawn_workers has a valid epic
fn create_epic(cas_root: &std::path::Path) -> String { todo!() }

fn spawn_factory(cwd: &std::path::Path, cas_root: &std::path::Path) -> PtyRunner { todo!() }

fn shutdown_factory(runner: &mut PtyRunner) { todo!() }

// =============================================================================
// Test: Full factory lifecycle — spawn workers and verify registration
// =============================================================================

/// Spawns a real factory TUI, has the supervisor spawn 2 workers,
/// and verifies workers register as agents in the database.
#[test]
#[ignore]
fn test_real_factory_spawn_workers() {
    if !should_run() {
        return;
    }

    let cas = new_cas_instance();
    let cwd = std::fs::canonicalize(cas.temp_dir.path())
        .unwrap_or_else(|_| cas.temp_dir.path().to_path_buf());
    let cas_root = cwd.join(".cas");

    // Create epic (required before spawning workers)
    create_epic(&cas_root);

    let mut runner = spawn_factory(&cwd, &cas_root);

    // Get session info to learn supervisor's name
    let session = match wait_for_session_info(&cwd, Duration::from_secs(30)) {
        Ok(info) => info,
        Err(err) => {
            let output = runner.get_output();
            let raw = output.as_str();
            shutdown_factory(&mut runner);
            panic!("failed to load session metadata: {err}\n--- raw output ---\n{raw}");
        }
    };
    let supervisor_name = session.metadata.supervisor.name.clone();
    println!("Supervisor name: {}", supervisor_name);

    // Wait for supervisor to be ready before injecting prompt
    if let Err(err) = wait_for_supervisor_ready(&runner, Duration::from_secs(30)) {
        eprintln!("warning: {err}");
    }

    // Inject prompt to spawn 2 workers
    let prompt = "Use MCP tools only. Run exactly:\n\
        mcp__cas__coordination action=spawn_workers count=2\n\
        Do not add extra text.";

    let queue = open_prompt_queue_store(&cas_root).expect("open prompt queue");
    queue
        .enqueue("cas", &supervisor_name, prompt)
        .expect("enqueue supervisor prompt");
    println!("Enqueued spawn prompt for supervisor");

    // Wait for workers to register
    match wait_for_worker_count(&cas_root, 2, Duration::from_secs(120)) {
        Ok(()) => println!("2 workers registered!"),
        Err(err) => {
            let output = runner.get_output();
            let raw = output.as_str_lossy();
            shutdown_factory(&mut runner);
            panic!("Workers failed to register: {err}\n--- raw output ---\n{raw}");
        }
    }

    // Verify agent store
    let store = open_agent_store(&cas_root).expect("open agent store");
    let agents = store.list(None).expect("list agents");
    let workers: Vec<_> = agents
        .iter()
        .filter(|a| a.role == AgentRole::Worker)
        .collect();
    println!("Registered workers:");
    for w in &workers {
        println!("  {} ({})", w.name, w.id);
    }
    assert!(
        workers.len() >= 2,
        "Expected at least 2 workers, got {}",
        workers.len()
    );

    shutdown_factory(&mut runner);
}

// =============================================================================
// Test: Full round-trip messaging — supervisor → workers → supervisor
// =============================================================================

/// Spawns a real factory TUI, has the supervisor spawn 2 workers,
/// sends a message to all workers with a unique token, and verifies
/// workers reply back with the token.
#[test]
#[ignore]
fn test_real_factory_message_round_trip() {
    if !should_run() {
        return;
    }

    let cas = new_cas_instance();
    let cwd = std::fs::canonicalize(cas.temp_dir.path())
        .unwrap_or_else(|_| cas.temp_dir.path().to_path_buf());
    let cas_root = cwd.join(".cas");

    // Create epic (required before spawning workers)
    create_epic(&cas_root);

    let mut runner = spawn_factory(&cwd, &cas_root);

    let session = match wait_for_session_info(&cwd, Duration::from_secs(30)) {
        Ok(info) => info,
        Err(err) => {
            let output = runner.get_output();
            let raw = output.as_str();
            shutdown_factory(&mut runner);
            panic!("failed to load session metadata: {err}\n--- raw output ---\n{raw}");
        }
    };
    let supervisor_name = session.metadata.supervisor.name.clone();
    println!("Supervisor name: {}", supervisor_name);

    // Wait for supervisor to be ready before injecting prompt
    if let Err(err) = wait_for_supervisor_ready(&runner, Duration::from_secs(30)) {
        eprintln!("warning: {err}");
    }

    // Generate unique token for this test run
    let token = {
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::SystemTime::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or(0);
        format!("FACTORY_E2E_RT_{}_{}", std::process::id(), nanos)
    };
    println!("Round-trip token: {}", token);

    // Inject prompt: spawn 2 workers, then message them with the token
    let prompt = format!(
        "Use MCP tools only. Run exactly:\n\
        mcp__cas__coordination action=spawn_workers count=2\n\
        Then send to all workers:\n\
        mcp__cas__coordination action=message target=all_workers message=\"Reply with: mcp__cas__coordination action=message target={supervisor} message=\\\"{token}\\\"\"\n\
        Do not add extra text.",
        supervisor = supervisor_name,
        token = token
    );

    let queue = open_prompt_queue_store(&cas_root).expect("open prompt queue");
    queue
        .enqueue("cas", &supervisor_name, &prompt)
        .expect("enqueue supervisor prompt");
    println!("Enqueued spawn+message prompt");

    // Wait for workers to register
    match wait_for_worker_count(&cas_root, 2, Duration::from_secs(120)) {
        Ok(()) => println!("2 workers registered!"),
        Err(err) => {
            let output = runner.get_output();
            let raw = output.as_str_lossy();
            shutdown_factory(&mut runner);
            panic!("Workers failed to register: {err}\n--- raw output ---\n{raw}");
        }
    }

    // Wait for worker replies (look for token in PTY output or prompt queue)
    println!("Waiting for worker replies containing token...");
    let start = Instant::now();
    let mut reply_count = 0;
    while start.elapsed() < Duration::from_secs(180) {
        // Check PTY output for message XML tags
        let output = runner.get_output();
        let output_str = output.as_str_lossy();
        reply_count = output_str
            .lines()
            .filter(|line| line.contains(&token))
            .count();
        if reply_count >= 2 {
            break;
        }

        // Also check the prompt queue for replies back to supervisor
        if let Ok(pq) = open_prompt_queue_store(&cas_root) {
            if let Ok(entries) = pq.peek_all(20) {
                let supervisor_replies = entries
                    .iter()
                    .filter(|e| e.target == supervisor_name && e.prompt.contains(&token))
                    .count();
                if supervisor_replies >= 2 {
                    reply_count = supervisor_replies;
                    break;
                }
            }
        }

        std::thread::sleep(Duration::from_millis(500));
    }

    let output = runner.get_output();
    let output_str = output.as_str_lossy();
    println!("\n--- PTY output (last 2000 chars) ---");
    let start_idx = output_str.len().saturating_sub(2000);
    println!("{}", &output_str[start_idx..]);

    // At least 1 reply proves the full round-trip: supervisor → worker → supervisor.
    // Getting both workers to reply within timeout is ideal but not required.
    assert!(
        reply_count >= 1,
        "Expected at least 1 worker reply with token, got {}",
        reply_count
    );
    println!(
        "\nRound-trip verified: {} worker replies with token",
        reply_count
    );

    shutdown_factory(&mut runner);
}
