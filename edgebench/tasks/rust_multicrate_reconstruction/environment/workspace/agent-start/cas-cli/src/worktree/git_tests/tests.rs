use crate::worktree::git::*;
use tempfile::TempDir;

fn create_test_repo() -> (TempDir, PathBuf) { todo!() }


#[test]
fn test_detect_repo_root() {
    let (_temp, repo_path) = create_test_repo();

    let detected = GitOperations::detect_repo_root(&repo_path).unwrap();
    // Canonicalize both paths to handle macOS /var -> /private/var symlinks
    let detected_canon = detected.canonicalize().unwrap_or(detected);
    let repo_canon = repo_path.canonicalize().unwrap_or(repo_path);
    assert_eq!(detected_canon, repo_canon);
}

#[test]
fn test_current_branch() {
    let (_temp, repo_path) = create_test_repo();
    let git = GitOperations::new(repo_path);

    let branch = git.current_branch().unwrap();
    // Default branch is usually "main" or "master"
    assert!(branch == "main" || branch == "master");
}


#[test]
fn test_branch_exists() {
    let (_temp, repo_path) = create_test_repo();
    let git = GitOperations::new(repo_path);

    let current = git.current_branch().unwrap();
    assert!(git.branch_exists(&current).unwrap());
    assert!(!git.branch_exists("nonexistent-branch").unwrap());
}

#[test]
fn test_get_context() {
    let (_temp, repo_path) = create_test_repo();

    let context = GitOperations::get_context(&repo_path).unwrap();
    assert!(context.branch.is_some());
    assert!(!context.is_worktree); // Main checkout is not a worktree
}

#[test]
fn test_init_submodules_no_submodules() {
    // Test that init_submodules succeeds when there are no submodules
    let (_temp, repo_path) = create_test_repo();
    let git = GitOperations::new(repo_path.clone());

    // Should succeed silently when no .gitmodules exists
    let result = git.init_submodules(&repo_path);
    assert!(result.is_ok());
}

#[test]
fn test_init_submodules_with_gitmodules() {
    // Test that init_submodules runs when .gitmodules exists
    let (temp, repo_path) = create_test_repo();
    let git = GitOperations::new(repo_path.clone());

    // Create a .gitmodules file (simulating a repo with submodules)
    std::fs::write(
        repo_path.join(".gitmodules"),
        "[submodule \"vendor/test\"]\n\tpath = vendor/test\n\turl = https://example.com/test.git\n",
    )
    .unwrap();

    // Create a worktree
    let worktree_path = temp.path().join("test-worktree");
    git.create_worktree(&worktree_path, "test-branch", None)
        .unwrap();

    // The worktree should exist (submodule init may fail due to network,
    // but the worktree creation should still succeed)
    assert!(worktree_path.exists());
}



#[test]
fn test_mark_config_skip_worktree() {
    let (temp, repo_path) = create_test_repo();
    let git = GitOperations::new(repo_path.clone());

    // Create .claude directory with tracked files
    std::fs::create_dir_all(repo_path.join(".claude/rules")).unwrap();
    std::fs::write(repo_path.join(".claude/rules/test.md"), "test rule").unwrap();
    std::fs::write(repo_path.join("CLAUDE.md"), "# Claude").unwrap();

    Command::new("git")
        .args(["add", ".claude/", "CLAUDE.md"])
        .current_dir(&repo_path)
        .output()
        .unwrap();
    Command::new("git")
        .args(["commit", "-m", "Add config files"])
        .current_dir(&repo_path)
        .output()
        .unwrap();

    // Create a worktree
    let worktree_path = temp.path().join("test-skip-wt");
    git.create_worktree(&worktree_path, "test-skip-branch", None)
        .unwrap();

    // Mark skip-worktree
    git.mark_config_skip_worktree(&worktree_path).unwrap();

    // Modify a tracked file in the worktree
    std::fs::write(
        worktree_path.join(".claude/rules/test.md"),
        "modified rule content",
    )
    .unwrap();

    // The modification should NOT show up in git status
    let output = Command::new("git")
        .args(["status", "--porcelain"])
        .current_dir(&worktree_path)
        .output()
        .unwrap();

    let status = String::from_utf8_lossy(&output.stdout);
    assert!(
        !status.contains(".claude/rules/test.md"),
        "skip-worktree file should not appear in git status, got: {status}"
    );
}

#[test]
fn test_mark_config_skip_worktree_no_files() {
    let (_temp, repo_path) = create_test_repo();
    let git = GitOperations::new(repo_path.clone());

    // No .claude files tracked - should succeed silently
    let result = git.mark_config_skip_worktree(&repo_path);
    assert!(result.is_ok());
}

#[test]
fn test_fix_symlinked_submodules() {
    let (_temp, repo_path) = create_test_repo();
    let git = GitOperations::new(repo_path.clone());

    // Create .gitmodules
    std::fs::write(
        repo_path.join(".gitmodules"),
        "[submodule \"vendor/test\"]\n\tpath = vendor/test\n\turl = https://example.com/test.git\n",
    )
    .unwrap();

    // Create vendor directory
    std::fs::create_dir_all(repo_path.join("vendor")).unwrap();

    // Create a symlink for the submodule (simulating the workaround)
    let symlink_path = repo_path.join("vendor/test");
    let target = repo_path.join(".git"); // Just point to something that exists
    #[cfg(unix)]
    std::os::unix::fs::symlink(&target, &symlink_path).unwrap();
    #[cfg(windows)]
    std::os::windows::fs::symlink_dir(&target, &symlink_path).unwrap();

    assert!(symlink_path.is_symlink());

    // Fix should remove the symlink
    git.fix_symlinked_submodules(&repo_path).unwrap();

    // Symlink should be gone (submodule init may or may not succeed, but symlink is removed)
    assert!(!symlink_path.is_symlink());
}
