#[test]
fn test_manager_creation() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let manager = WorktreeManager::new(&repo_path, config).unwrap();
    assert!(!manager.is_enabled());
    assert!(!manager.is_in_worktree());
}

#[test]
fn test_worktree_path_for_worker() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let manager = WorktreeManager::new(&repo_path, config).unwrap();
    let path = manager.worktree_path_for_worker("swift-fox");

    assert!(path.to_string_lossy().contains(".cas/worktrees"));
    assert!(path.to_string_lossy().contains("swift-fox"));
}

#[test]
fn test_create_worker_worktree() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let mut manager = WorktreeManager::new(&repo_path, config).unwrap();

    let worktree = manager.create_for_worker("swift-fox").unwrap();

    assert!(worktree.path.exists());
    assert_eq!(worktree.status, WorktreeStatus::Active);
    assert!(worktree.epic_id.is_none());
    assert_eq!(worktree.branch, "factory/swift-fox");
}

#[test]
fn test_cleanup_workers() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let mut manager = WorktreeManager::new(&repo_path, config).unwrap();

    let path1 = manager
        .ensure_worker_worktree("swift-fox")
        .unwrap()
        .path
        .clone();
    let path2 = manager
        .ensure_worker_worktree("calm-owl")
        .unwrap()
        .path
        .clone();

    assert!(path1.exists());
    assert!(path2.exists());

    let cleaned = manager.cleanup_workers(false).unwrap();

    assert_eq!(cleaned.len(), 2);
    assert!(!path1.exists());
    assert!(!path2.exists());
    assert!(manager.worker_cwds().is_empty());
}

#[test]
fn test_slugify_title() {
    assert_eq!(slugify_title("Add User Auth"), "add-user-auth");
    assert_eq!(slugify_title("CAS v1"), "cas-v1");
    assert_eq!(slugify_title("Fix bug #123"), "fix-bug-123");
    assert_eq!(slugify_title("  Multiple   Spaces  "), "multiple-spaces");
    assert_eq!(
        slugify_title("Special!@#$%^&*()Characters"),
        "special-characters"
    );
    let long_title = "A".repeat(100);
    assert_eq!(slugify_title(&long_title).len(), 50);
}

#[test]
fn test_create_epic_branch() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let manager = WorktreeManager::new(&repo_path, config).unwrap();

    let branch = manager
        .create_epic_branch("Add User Authentication")
        .unwrap();

    assert_eq!(branch, "epic/add-user-authentication");
    assert!(manager.git.branch_exists(&branch).unwrap());
}

#[test]
fn test_cleanup_worker_branches_after_merge() {
    let (_temp, repo_path) = create_test_repo();
    let config = WorktreeConfig::default();

    let mut manager = WorktreeManager::new(&repo_path, config).unwrap();

    let epic_branch = manager.create_epic_branch("Cleanup Test").unwrap();

    let worktree = manager.create_for_worker("cleanup-worker").unwrap();
    let worker_branch = worktree.branch.clone();

    std::fs::write(worktree.path.join("cleanup-file.txt"), "cleanup content").unwrap();
    Command::new("git")
        .args(["add", "cleanup-file.txt"])
        .current_dir(&worktree.path)
        .output()
        .unwrap();
    Command::new("git")
        .args(["commit", "-m", "Cleanup commit"])
        .current_dir(&worktree.path)
        .output()
        .unwrap();

    manager.merge_workers_to_epic(&epic_branch).unwrap();

    assert!(
        manager.git.branch_exists(&worker_branch).unwrap(),
        "Worker branch should exist"
    );

    assert!(
        manager
            .is_branch_merged(&worker_branch, &epic_branch)
            .unwrap(),
        "Worker branch should be merged into epic branch"
    );

    manager.remove_worker("cleanup-worker", true).unwrap();

    assert!(
        !manager.git.branch_exists(&worker_branch).unwrap(),
        "Worker branch should be deleted by remove_worker"
    );
}
