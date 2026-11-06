    #[test]
    fn test_styled_output() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            KeyValue::new()
                .add("Name", "CAS")
                .add("Version", "0.7.0")
                .render(&mut fmt)
                .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Name"));
        assert!(output.contains("CAS"));
        assert!(output.contains("\x1b["));
    }

    #[test]
    fn test_colored_value_plain_ignores_color() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            KeyValue::new()
                .add_colored("Status", "Active", RatatuiColor::Green)
                .render(&mut fmt)
                .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "Status: Active\n");
        assert!(!output.contains("\x1b["));
    }

    #[test]
    fn test_single_entry_no_padding() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            KeyValue::new()
                .add("Key", "Value")
                .render(&mut fmt)
                .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "Key: Value\n");
    }
