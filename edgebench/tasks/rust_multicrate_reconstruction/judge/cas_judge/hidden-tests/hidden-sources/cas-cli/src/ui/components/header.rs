    #[test]
    fn test_h1_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            Header::h1("Tasks").render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "=== Tasks ===\n");
    }

    #[test]
    fn test_h1_with_icon_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            Header::h1("Tasks")
                .with_icon("📋")
                .render(&mut fmt)
                .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "=== 📋 Tasks ===\n");
    }

    #[test]
    fn test_h1_styled() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            Header::h1("Tasks").render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Tasks"));
        assert!(output.contains("\x1b["));
    }
