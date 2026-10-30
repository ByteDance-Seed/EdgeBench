    #[test]
    fn blame_command_uses_separator_before_file_path() {
        let cmd = build_git_blame_command("--help");
        let args: Vec<String> = cmd
            .get_args()
            .map(|arg| arg.to_string_lossy().to_string())
            .collect();

        assert_eq!(args, vec!["blame", "--porcelain", "--", "--help"]);
    }

    #[test]
    fn parse_blame_file_spec_parses_single_line() {
        let (path, line_start, line_end) = parse_blame_file_spec("src/main.rs:42");
        assert_eq!(path, "src/main.rs");
        assert_eq!(line_start, Some(42));
        assert_eq!(line_end, Some(42));
    }
