use std::fs;
use std::path::{Path, PathBuf};

fn repo_root() -> PathBuf { todo!() }

fn load(path: &Path) -> String { todo!() }

#[test]
fn codex_factory_skills_use_cs_prefix_only() {
    let root = repo_root();
    let skills_dir = root.join(".codex/skills");
    if !skills_dir.exists() {
        return;
    }

    let entries = fs::read_dir(&skills_dir).expect("read .codex/skills");
    for entry in entries.flatten() {
        let name = entry.file_name().to_string_lossy().to_string();
        if !name.starts_with("cas-factory-") {
            continue;
        }
        let skill_path = entry.path().join("SKILL.md");
        if !skill_path.exists() {
            continue;
        }

        let content = load(&skill_path);
        let has_mcp_examples = content.contains("mcp__cs__") || content.contains("mcp__cas__");
        if has_mcp_examples {
            assert!(
                content.contains("mcp__cs__"),
                "{} should include mcp__cs__ examples",
                skill_path.display()
            );
        }
        assert!(
            !content.contains("mcp__cas__"),
            "{} still contains legacy mcp__cas__ references",
            skill_path.display()
        );
        assert!(
            !content.contains("action=prompt"),
            "{} still contains legacy action=prompt usage",
            skill_path.display()
        );
    }
}

#[test]
fn codex_builtin_supervisor_guide_includes_core_workflow() {
    let root = repo_root();
    let guide = root.join("cas-cli/src/builtins/codex/skills/cas-supervisor.md");
    let content = load(&guide);

    assert!(
        content.contains("spawn_workers"),
        "supervisor guide should include spawn_workers"
    );
    assert!(
        content.contains("Never implement tasks yourself"),
        "supervisor guide should include hard rule about not implementing"
    );
    assert!(
        content.contains("mcp__cs__"),
        "codex supervisor guide should use mcp__cs__ prefix"
    );
}

#[test]
fn codex_worker_runtime_instruction_allows_close_then_escalate() {
    let root = repo_root();
    let pty_rs = root.join("crates/cas-pty/src/pty.rs");
    let content = load(&pty_rs);

    assert!(
        content.contains("close with `mcp__cs__task action=close"),
        "runtime worker instruction should instruct workers to close tasks"
    );
    assert!(
        !content.contains("DO NOT close the task yourself"),
        "runtime worker instruction should not forbid close universally"
    );
}
