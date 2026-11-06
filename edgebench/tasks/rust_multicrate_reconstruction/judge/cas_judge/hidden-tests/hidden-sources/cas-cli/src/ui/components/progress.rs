    #[test]
    fn test_progress_bar_percentage_zero_total() {
        let bar = ProgressBar::new(0);
        assert_eq!(bar.percentage(), 100);
    }

    #[test]
    fn test_progress_bar_view_styled() {
        use crate::ui::theme::ActiveTheme;

        let mut bar = ProgressBar::new(10).with_message("Pushing");
        bar.update(ProgressBarMsg::Set(5));

        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            bar.view(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Pushing"));
        assert!(output.contains("5/10"));
        assert!(output.contains("50%"));
        assert!(output.contains("\x1b[")); // ANSI codes
    }

    #[test]
    fn test_progress_bar_view_plain_milestone() {
        let mut bar = ProgressBar::new(100).with_message("Syncing");
        bar.update(ProgressBarMsg::Set(50));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            bar.view(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("50%"));
        assert!(output.contains("Syncing"));
    }

    #[test]
    fn test_progress_bar_view_plain_finished() {
        let mut bar = ProgressBar::new(100).with_message("Syncing");
        bar.update(ProgressBarMsg::Finish);

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            bar.view(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("100%"));
        assert!(output.contains("Complete"));
    }

    #[test]
    fn test_progress_bar_view_plain_no_message_finished() {
        let mut bar = ProgressBar::new(100);
        bar.update(ProgressBarMsg::Finish);

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            bar.view(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("100% Complete"));
    }

    #[test]
    fn test_format_eta_minutes() {
        let eta = std::time::Duration::from_secs(125);
        assert_eq!(ProgressBar::format_eta(eta), "2m5s");
    }

    #[test]
    fn test_format_eta_hours() {
        let eta = std::time::Duration::from_secs(3665);
        assert_eq!(ProgressBar::format_eta(eta), "1h1m");
    }
