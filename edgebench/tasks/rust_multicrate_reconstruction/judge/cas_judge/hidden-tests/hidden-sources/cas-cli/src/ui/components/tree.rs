    #[test]
    fn test_nested_tree() {
        let tree = Tree::new("cas-cli")
            .child(
                Tree::new("src")
                    .child(Tree::leaf("main.rs"))
                    .child(Tree::leaf("lib.rs")),
            )
            .child(Tree::leaf("Cargo.toml"));

        let output = render_plain(&tree);
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines[0], "cas-cli");
        assert_eq!(lines[1], "|-- src");
        assert_eq!(lines[2], "|   |-- main.rs");
        assert_eq!(lines[3], "|   `-- lib.rs");
        assert_eq!(lines[4], "`-- Cargo.toml");
    }

    #[test]
    fn test_styled_output() {
        let theme = ActiveTheme::default_dark();
        let tree = Tree::new("root")
            .child(Tree::leaf("a"))
            .child(Tree::leaf("b"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            tree.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("root"));
        assert!(output.contains("a"));
        assert!(output.contains("b"));
        assert!(output.contains("\x1b["));
        // Unicode tree connectors
        assert!(output.contains("\u{251C}")); // ├
        assert!(output.contains("\u{2514}")); // └
    }
