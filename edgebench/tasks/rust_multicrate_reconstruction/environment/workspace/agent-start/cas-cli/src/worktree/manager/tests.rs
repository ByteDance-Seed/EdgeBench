use crate::types::WorktreeStatus;
use crate::worktree::manager::*;
use std::path::PathBuf;
use std::process::Command;
use tempfile::TempDir;

fn create_test_repo() -> (TempDir, PathBuf) { todo!() }


#[test]
fn test_worktree_path_calculation_for_epic() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig {
        base_path: "../{project}-worktrees".to_string(),
        ..Default::default()
    };

    let manager = WorktreeManager::new(&repo_path, config).unwrap();
    let path = manager.worktree_path_for_epic("cas-epic-1234");

    assert!(path.to_string_lossy().contains("-worktrees"));
    assert!(path.to_string_lossy().contains("cas-epic-1234"));
}

#[test]
fn test_branch_name_calculation_for_epic() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig {
        branch_prefix: "cas/".to_string(),
        ..Default::default()
    };

    let manager = WorktreeManager::new(&repo_path, config).unwrap();
    let branch = manager.branch_name_for_epic("cas-epic-1234");

    assert_eq!(branch, "cas/cas-epic-1234");
}

#[test]
fn test_create_worktree_for_epic_disabled() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig {
        enabled: false,
        ..Default::default()
    };

    let manager = WorktreeManager::new(&repo_path, config).unwrap();
    let result = manager.create_for_epic("cas-epic-1234", None);

    assert!(matches!(result, Err(WorktreeError::NotEnabled)));
}

#[test]
fn test_create_and_cleanup_worktree_for_epic() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig {
        enabled: true,
        auto_merge: false,
        cleanup_on_close: true,
        ..Default::default()
    };

    let manager = WorktreeManager::new(&repo_path, config).unwrap();

    let mut worktree = manager
        .create_for_epic("cas-epic-test-123", Some("agent-1"))
        .unwrap();

    assert!(worktree.path.exists());
    assert_eq!(worktree.status, WorktreeStatus::Active);
    assert_eq!(worktree.epic_id, Some("cas-epic-test-123".to_string()));

    manager.abandon(&mut worktree, false).unwrap();

    assert_eq!(worktree.status, WorktreeStatus::Removed);
    assert!(!worktree.path.exists());
}


#[test]
fn test_branch_name_for_worker() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let manager = WorktreeManager::new(&repo_path, config).unwrap();
    let branch = manager.branch_name_for_worker("swift-fox");

    assert_eq!(branch, "factory/swift-fox");
}


#[test]
fn test_ensure_worker_worktree_creates_new() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let mut manager = WorktreeManager::new(&repo_path, config).unwrap();

    let worktree = manager.ensure_worker_worktree("calm-owl").unwrap();

    assert!(worktree.path.exists());
    assert_eq!(worktree.branch, "factory/calm-owl");
}

#[test]
fn test_ensure_worker_worktree_reuses_existing() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let mut manager = WorktreeManager::new(&repo_path, config).unwrap();

    let path1 = manager
        .ensure_worker_worktree("swift-fox")
        .unwrap()
        .path
        .clone();

    let path2 = manager
        .ensure_worker_worktree("swift-fox")
        .unwrap()
        .path
        .clone();

    assert_eq!(path1, path2);
}

#[test]
fn test_worker_cwds() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let mut manager = WorktreeManager::new(&repo_path, config).unwrap();

    manager.ensure_worker_worktree("swift-fox").unwrap();
    manager.ensure_worker_worktree("calm-owl").unwrap();

    let cwds = manager.worker_cwds();

    assert_eq!(cwds.len(), 2);
    assert!(cwds.contains_key("swift-fox"));
    assert!(cwds.contains_key("calm-owl"));
}


#[test]
fn test_remove_single_worker() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let mut manager = WorktreeManager::new(&repo_path, config).unwrap();

    let path1 = manager
        .ensure_worker_worktree("swift-fox")
        .unwrap()
        .path
        .clone();
    manager.ensure_worker_worktree("calm-owl").unwrap();

    manager.remove_worker("swift-fox", false).unwrap();

    assert!(!path1.exists());
    assert_eq!(manager.worker_cwds().len(), 1);
    assert!(manager.worker_cwds().contains_key("calm-owl"));
}



#[test]
fn test_create_epic_branch_idempotent() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let manager = WorktreeManager::new(&repo_path, config).unwrap();

    let branch1 = manager.create_epic_branch("Test Epic").unwrap();
    let branch2 = manager.create_epic_branch("Test Epic").unwrap();

    assert_eq!(branch1, branch2);
    assert_eq!(branch1, "epic/test-epic");
}

#[test]
fn test_merge_workers_to_epic() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let mut manager = WorktreeManager::new(&repo_path, config).unwrap();

    let epic_branch = manager.create_epic_branch("Test Merge").unwrap();

    let worktree = manager.create_for_worker("merge-worker").unwrap();

    std::fs::write(worktree.path.join("worker-file.txt"), "worker content").unwrap();
    Command::new("git")
        .args(["add", "worker-file.txt"])
        .current_dir(&worktree.path)
        .output()
        .unwrap();
    Command::new("git")
        .args(["commit", "-m", "Worker commit"])
        .current_dir(&worktree.path)
        .output()
        .unwrap();

    let results = manager.merge_workers_to_epic(&epic_branch).unwrap();

    assert_eq!(results.len(), 1);
    assert!(results[0].1, "Merge should succeed");

    manager.git.checkout(&epic_branch).unwrap();
    assert!(repo_path.join("worker-file.txt").exists());
}


#[test]
fn test_is_branch_merged() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let manager = WorktreeManager::new(&repo_path, config).unwrap();

    let current = manager.git.current_branch().unwrap();
    Command::new("git")
        .args(["checkout", "-b", "test-merged"])
        .current_dir(&repo_path)
        .output()
        .unwrap();
    std::fs::write(repo_path.join("merged-file.txt"), "merged").unwrap();
    Command::new("git")
        .args(["add", "merged-file.txt"])
        .current_dir(&repo_path)
        .output()
        .unwrap();
    Command::new("git")
        .args(["commit", "-m", "Merged commit"])
        .current_dir(&repo_path)
        .output()
        .unwrap();
    Command::new("git")
        .args(["checkout", &current])
        .current_dir(&repo_path)
        .output()
        .unwrap();
    Command::new("git")
        .args(["merge", "test-merged", "--no-ff", "-m", "Merge test-merged"])
        .current_dir(&repo_path)
        .output()
        .unwrap();

    assert!(manager.is_branch_merged("test-merged", &current).unwrap());

    Command::new("git")
        .args(["checkout", "-b", "test-unmerged"])
        .current_dir(&repo_path)
        .output()
        .unwrap();
    std::fs::write(repo_path.join("unmerged-file.txt"), "unmerged").unwrap();
    Command::new("git")
        .args(["add", "unmerged-file.txt"])
        .current_dir(&repo_path)
        .output()
        .unwrap();
    Command::new("git")
        .args(["commit", "-m", "Unmerged commit"])
        .current_dir(&repo_path)
        .output()
        .unwrap();
    Command::new("git")
        .args(["checkout", &current])
        .current_dir(&repo_path)
        .output()
        .unwrap();

    assert!(!manager.is_branch_merged("test-unmerged", &current).unwrap());
}
