    #[test]
    fn test_grep_simple_pattern() {
        let dir = TempDir::new().unwrap();
        let file_path = dir.path().join("test.rs");
        fs::write(&file_path, "fn main() {\n    println!(\"hello\");\n}\n").unwrap();

        let grep = GrepSearch::new(dir.path());
        let results = grep
            .search(&GrepOptions {
                pattern: "println".to_string(),
                ..Default::default()
            })
            .unwrap();

        assert_eq!(results.len(), 1);
        assert_eq!(results[0].line_number, 2);
        assert!(results[0].line_content.contains("println"));
    }

    #[test]
    fn test_grep_limit() {
        let dir = TempDir::new().unwrap();
        let file_path = dir.path().join("test.txt");
        fs::write(&file_path, "match\nmatch\nmatch\nmatch\nmatch\n").unwrap();

        let grep = GrepSearch::new(dir.path());
        let results = grep
            .search(&GrepOptions {
                pattern: "match".to_string(),
                limit: 3,
                ..Default::default()
            })
            .unwrap();

        assert_eq!(results.len(), 3);
    }

    #[test]
    fn test_grep_options_default() {
        let opts = GrepOptions::default();
        assert!(opts.pattern.is_empty());
        assert!(opts.glob.is_none());
        assert_eq!(opts.before_context, 0);
        assert_eq!(opts.after_context, 0);
        assert!(!opts.case_insensitive);
        assert_eq!(opts.limit, 100);
    }
