    #[test]
    fn test_column_empty() {
        let col = Column::new();
        assert!(col.is_empty());
        assert_eq!(col.len(), 0);

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            col.render(&mut fmt).unwrap();
        }
        assert!(buf.is_empty());
    }

    #[test]
    fn test_column_multiple_children_no_spacing() {
        let col = Column::new()
            .child(TextBlock::new("Line 1"))
            .child(TextBlock::new("Line 2"))
            .child(TextBlock::new("Line 3"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            col.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "Line 1\nLine 2\nLine 3\n");
    }

    #[test]
    fn test_row_empty() {
        let row = Row::new();
        assert!(row.is_empty());
        assert_eq!(row.len(), 0);

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            row.render(&mut fmt).unwrap();
        }
        assert!(buf.is_empty());
    }

    #[test]
    fn test_row_default() {
        let row = Row::default();
        assert!(row.is_empty());
        assert_eq!(row.gap, 2);
    }

    #[test]
    fn test_divider_plain_double() {
        let div = Divider::double();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            div.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output.trim_end(), "=".repeat(80));
    }

    #[test]
    fn test_divider_plain_dotted() {
        let div = Divider::dotted();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            div.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output.trim_end(), ".".repeat(80));
    }

    #[test]
    fn test_divider_styled_light() {
        let theme = ActiveTheme::default_dark();
        let div = Divider::new();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            div.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("\x1b[")); // ANSI codes
        assert!(output.contains("\u{2500}")); // ─
    }

    #[test]
    fn test_divider_styled_dotted() {
        let theme = ActiveTheme::default_dark();
        let div = Divider::dotted();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            div.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("\u{2504}")); // ┄
    }

    #[test]
    fn test_divider_custom_width() {
        let div = Divider::new().with_width(40);
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            div.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output.trim_end(), "-".repeat(40));
    }

    #[test]
    fn test_divider_default() {
        let div = Divider::default();
        assert_eq!(div.style, DividerStyle::Light);
        assert_eq!(div.width, None);
    }

    #[test]
    fn test_strip_ansi_with_escapes() {
        // \x1b[38;2;255;0;0m hello \x1b[0m
        assert_eq!(strip_ansi_visible_len("\x1b[38;2;255;0;0mhello\x1b[0m"), 5);
    }
