    #[test]
    fn parse_line_type_context() {
        let result = parse_line_type(" hello world").unwrap();
        assert_eq!(result.line_type, HunkLineType::Context);
        assert_eq!(result.line, "hello world");
    }

    #[test]
    fn parse_line_type_addition() {
        let result = parse_line_type("+new line").unwrap();
        assert_eq!(result.line_type, HunkLineType::Addition);
        assert_eq!(result.line, "new line");
    }

    #[test]
    fn parse_line_type_deletion() {
        let result = parse_line_type("-old line").unwrap();
        assert_eq!(result.line_type, HunkLineType::Deletion);
        assert_eq!(result.line, "old line");
    }

    #[test]
    fn parse_line_type_metadata() {
        let result = parse_line_type("\\ No newline at end of file").unwrap();
        assert_eq!(result.line_type, HunkLineType::Metadata);
        assert_eq!(result.line, " No newline at end of file");
    }

    #[test]
    fn parse_line_type_invalid() {
        assert!(parse_line_type("no prefix").is_none());
        assert!(parse_line_type("").is_none());
    }

    #[test]
    fn addition_and_deletion_lines_partial() {
        let patches = parse_patch_files(SIMPLE_GIT_DIFF);
        let file = &patches[0].files[0];
        assert!(file.is_partial);

        // Deletion lines: context lines + deletion lines
        // "fn main() {\n", "    println!(\"hello\");\n", "    let x = 1;\n",
        // "    let y = 2;\n", "}\n"
        assert_eq!(file.deletion_lines.len(), 5);

        // Addition lines: context lines + addition lines
        // "fn main() {\n", "    println!(\"hello world\");\n",
        // "    println!(\"goodbye\");\n", "    let x = 1;\n",
        // "    let y = 2;\n", "}\n"
        assert_eq!(file.addition_lines.len(), 6);
    }

    #[test]
    fn parse_new_file() {
        let patches = parse_patch_files(NEW_FILE_DIFF);
        let file = &patches[0].files[0];
        assert_eq!(file.name, "src/new.rs");
        assert_eq!(file.change_type, ChangeType::New);
        assert!(file.prev_name.is_none());
        assert_eq!(file.hunks.len(), 1);
        assert_eq!(file.hunks[0].addition_lines, 3);
        assert_eq!(file.hunks[0].deletion_lines, 0);
    }

    #[test]
    fn parse_multi_file_diff() {
        let patches = parse_patch_files(MULTI_FILE_DIFF);
        assert_eq!(patches.len(), 1);
        assert_eq!(patches[0].files.len(), 2);
        assert_eq!(patches[0].files[0].name, "src/a.rs");
        assert_eq!(patches[0].files[1].name, "src/b.rs");
    }

    #[test]
    fn parse_multi_commit_patch() {
        let patches = parse_patch_files(MULTI_COMMIT_PATCH);
        assert_eq!(patches.len(), 2);

        assert!(patches[0].patch_metadata.is_some());
        assert_eq!(patches[0].files.len(), 1);
        assert_eq!(patches[0].files[0].name, "a.rs");

        assert!(patches[1].patch_metadata.is_some());
        assert_eq!(patches[1].files.len(), 1);
        assert_eq!(patches[1].files[0].name, "b.rs");
    }
