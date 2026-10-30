    #[test]
    fn test_find_cas_root_from_worktree() {
        let _guard = ENV_MUTEX.lock().unwrap();
        let original_cas_root = std::env::var("CAS_ROOT").ok();
        unsafe { std::env::remove_var("CAS_ROOT") };

        // Simulate a git worktree structure:
        // /main_repo/.cas/       <- CAS directory
        // /main_repo/.git/       <- Main git directory
        // /main_repo/.git/worktrees/wt1/  <- Worktree git data
        // /worktrees/wt1/.git    <- File pointing to main repo
        let temp = TempDir::new().unwrap();
        let main_repo = temp.path().join("main_repo");
        let worktree = temp.path().join("worktrees/wt1");

        // Create main repo with .cas
        std::fs::create_dir_all(&main_repo).unwrap();
        init_cas_dir(&main_repo).unwrap();

        // Create main repo's .git directory and worktrees subdir
        let git_dir = main_repo.join(".git");
        std::fs::create_dir_all(&git_dir).unwrap();
        let worktree_git_data = git_dir.join("worktrees/wt1");
        std::fs::create_dir_all(&worktree_git_data).unwrap();

        // Create worktree directory with .git file pointing to main repo
        std::fs::create_dir_all(&worktree).unwrap();
        let git_file_content = format!("gitdir: {}", worktree_git_data.display());
        std::fs::write(worktree.join(".git"), git_file_content).unwrap();

        // Should find .cas from worktree by following the git pointer
        let found = find_cas_root_from(&worktree).unwrap();
        assert_eq!(found, main_repo.join(".cas"));

        // Should also work from a subdirectory of the worktree
        let worktree_subdir = worktree.join("src/subdir");
        std::fs::create_dir_all(&worktree_subdir).unwrap();
        let found = find_cas_root_from(&worktree_subdir).unwrap();
        assert_eq!(found, main_repo.join(".cas"));

        match original_cas_root {
            Some(val) => unsafe { std::env::set_var("CAS_ROOT", val) },
            None => unsafe { std::env::remove_var("CAS_ROOT") },
        }
    }

    #[test]
    #[ignore] // Uses global state (CAS_ROOT env var, CWD) - run with: cargo test -- --ignored
    fn test_cas_root_env_var_invalid_path() {
        let _guard = ENV_MUTEX.lock().unwrap();

        let temp = TempDir::new().unwrap();
        // Canonicalize to handle macOS /var -> /private/var symlinks
        let temp_path = temp
            .path()
            .canonicalize()
            .expect("Failed to canonicalize temp path");

        // Create a real .cas dir to fall back to
        init_cas_dir(&temp_path).unwrap();

        // Save original env var and cwd
        let original_cas_root = std::env::var("CAS_ROOT").ok();
        let original_cwd = std::env::current_dir().ok();

        // Set CAS_ROOT to non-existent path
        unsafe { std::env::set_var("CAS_ROOT", "/nonexistent/path/that/does/not/exist") };
        std::env::set_current_dir(&temp_path).expect("Failed to change to temp dir");

        // Should fall back to directory walk and find the real .cas
        let found = find_cas_root().unwrap();
        assert_eq!(found, temp_path.join(".cas"));

        // Restore original state
        if let Some(cwd) = original_cwd {
            let _ = std::env::set_current_dir(cwd);
        }
        match original_cas_root {
            Some(val) => unsafe { std::env::set_var("CAS_ROOT", val) },
            None => unsafe { std::env::remove_var("CAS_ROOT") },
        }
    }
