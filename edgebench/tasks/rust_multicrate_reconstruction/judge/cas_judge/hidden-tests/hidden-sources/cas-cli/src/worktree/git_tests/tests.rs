#[test]
fn test_git_available() {
    // Git should be available in test environment
    assert!(GitOperations::is_git_available());
}

#[test]
fn test_create_and_remove_worktree() {
    let (temp, repo_path) = create_test_repo();
    let git = GitOperations::new(repo_path);

    let worktree_path = temp.path().join("feature-branch");

    // Create worktree
    git.create_worktree(&worktree_path, "feature-branch", None)
        .unwrap();
    assert!(worktree_path.exists());

    // List worktrees
    let worktrees = git.list_worktrees().unwrap();
    assert!(worktrees.len() >= 2); // Main + new worktree

    // Remove worktree
    git.remove_worktree(&worktree_path, false).unwrap();
    assert!(!worktree_path.exists());
}

#[test]
fn test_worktree_with_submodule_init() {
    // Test that create_worktree calls init_submodules
    let (temp, repo_path) = create_test_repo();
    let git = GitOperations::new(repo_path.clone());

    let worktree_path = temp.path().join("sub-test");

    // Create worktree (should also init submodules if any)
    git.create_worktree(&worktree_path, "sub-test-branch", None)
        .unwrap();

    assert!(worktree_path.exists());

    // Verify we can manually call init_submodules again (idempotent)
    let result = git.init_submodules(&worktree_path);
    assert!(result.is_ok());
}

#[test]
fn test_get_submodule_paths() {
    let (_temp, repo_path) = create_test_repo();
    let git = GitOperations::new(repo_path.clone());

    // No .gitmodules - should return empty vec
    assert!(git.get_submodule_paths().unwrap().is_empty());

    // Create .gitmodules with submodule paths
    std::fs::write(
            repo_path.join(".gitmodules"),
            "[submodule \"vendor/ghostty\"]\n\tpath = vendor/ghostty\n\turl = https://example.com/ghostty.git\n\
             [submodule \"vendor/other\"]\n\tpath = vendor/other\n\turl = https://example.com/other.git\n",
        )
        .unwrap();

    let paths = git.get_submodule_paths().unwrap();
    assert_eq!(paths.len(), 2);
    assert_eq!(paths[0], std::path::PathBuf::from("vendor/ghostty"));
    assert_eq!(paths[1], std::path::PathBuf::from("vendor/other"));
}
