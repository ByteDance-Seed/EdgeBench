    #[test]
    fn test_error_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            StatusLine::error("failed").render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "[ERROR] failed\n");
    }

    #[test]
    fn test_info_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            StatusLine::info("note this").render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "[INFO] note this\n");
    }

    #[test]
    fn test_success_styled() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            StatusLine::success("ok").render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("\x1b["));
        assert!(output.contains("ok"));
    }

    #[test]
    fn test_status_group_styled() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            StatusGroup::new()
                .push(StatusLine::info("a"))
                .push(StatusLine::warning("b"))
                .render(&mut fmt)
                .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("a"));
        assert!(output.contains("b"));
        assert!(output.contains("\x1b["));
    }

    #[test]
    fn test_new_with_status() {
        let line = StatusLine::new(Status::Warning, "watch out");
        assert_eq!(line.status, Status::Warning);
        assert_eq!(line.message, "watch out");
    }
