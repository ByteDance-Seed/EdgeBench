    #[test]
    fn test_bullet_list_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            List::bullet(vec![
                ListItem::new("First"),
                ListItem::new("Second"),
                ListItem::new("Third"),
            ])
            .render(&mut fmt)
            .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "- First\n- Second\n- Third\n");
    }

    #[test]
    fn test_nested_list_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            List::bullet(vec![
                ListItem::new("Parent"),
                ListItem::with_children(
                    "Has children",
                    vec![ListItem::new("Child A"), ListItem::new("Child B")],
                ),
            ])
            .render(&mut fmt)
            .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines.len(), 4);
        assert_eq!(lines[0], "- Parent");
        assert_eq!(lines[1], "- Has children");
        assert_eq!(lines[2], "  - Child A");
        assert_eq!(lines[3], "  - Child B");
    }

    #[test]
    fn test_numbered_list_styled() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            List::numbered(vec![ListItem::new("One"), ListItem::new("Two")])
                .render(&mut fmt)
                .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("1."));
        assert!(output.contains("One"));
        assert!(output.contains("2."));
        assert!(output.contains("Two"));
    }

    #[test]
    fn test_four_level_nesting_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            List::bullet(vec![ListItem::with_children(
                "L0",
                vec![ListItem::with_children(
                    "L1",
                    vec![ListItem::with_children("L2", vec![ListItem::new("L3")])],
                )],
            )])
            .render(&mut fmt)
            .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines[0], "- L0");
        assert_eq!(lines[1], "  - L1");
        assert_eq!(lines[2], "    - L2");
        assert_eq!(lines[3], "      - L3");
    }
