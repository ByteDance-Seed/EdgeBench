    #[test]
    fn test_heading_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.heading("Tasks").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "--- Tasks ---\n");
    }

    #[test]
    fn test_heading_styled() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            fmt.heading("Tasks").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Tasks"));
        assert!(output.contains("\x1b["));
    }

    #[test]
    fn test_error_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.error("failed").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "[ERROR] failed\n");
    }

    #[test]
    fn test_info_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.info("note").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "[INFO] note\n");
    }

    #[test]
    fn test_bullet_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.bullet("first item").unwrap();
            fmt.bullet("second item").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "  - first item\n  - second item\n");
    }

    #[test]
    fn test_progress_zero_total() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.progress(0, 0).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "\n");
    }

    #[test]
    fn test_to_crossterm_color_indexed() {
        let color = to_crossterm_color(RatatuiColor::Indexed(42));
        assert_eq!(color, CrosstermColor::AnsiValue(42));
    }

    #[test]
    fn test_terminal_width_returns_reasonable_value() {
        let width = terminal_width();
        assert!(
            width >= 20,
            "Terminal width should be at least 20: got {width}"
        );
        assert!(
            width <= 1000,
            "Terminal width should be at most 1000: got {width}"
        );
    }

    #[test]
    fn test_formatter_styled_accessors() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        let fmt = Formatter::styled(&mut buf, theme);

        assert_eq!(fmt.mode(), OutputMode::Styled);
        assert!(fmt.is_styled());
    }

    #[test]
    fn test_write_raw_always_plain() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            fmt.write_raw("no escape").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "no escape");
    }
