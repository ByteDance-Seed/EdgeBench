    #[test]
    fn diff_new_file() {
        let meta = diff_files("a.txt", "", "a.txt", "hello\nworld\n");

        assert_eq!(meta.change_type, ChangeType::New);
        assert!(meta.deletion_lines.is_empty());
        assert_eq!(meta.addition_lines.len(), 2);
        assert_eq!(meta.hunks.len(), 1);
        assert_eq!(meta.hunks[0].addition_lines, 2);
        assert_eq!(meta.hunks[0].deletion_lines, 0);
    }

    #[test]
    fn diff_identical_files() {
        let content = "line1\nline2\nline3\n";
        let meta = diff_files("a.txt", content, "a.txt", content);

        assert_eq!(meta.change_type, ChangeType::Change);
        assert!(meta.hunks.is_empty());
        assert_eq!(meta.split_line_count, 0);
        assert_eq!(meta.unified_line_count, 0);
    }

    #[test]
    fn split_lines_keep_newline_empty() {
        assert!(split_lines_keep_newline("").is_empty());
    }
