    #[test]
    fn test_spinner_tick_advances_frame() {
        let mut spinner = Spinner::new("test");
        assert_eq!(spinner.frame_index, 0);

        spinner.update(SpinnerMsg::Tick);
        assert_eq!(spinner.frame_index, 1);

        spinner.update(SpinnerMsg::Tick);
        assert_eq!(spinner.frame_index, 2);
    }

    #[test]
    fn test_spinner_fail() {
        let mut spinner = Spinner::new("Loading");
        let action = spinner.update(SpinnerMsg::Fail("Network error".to_string()));

        assert!(matches!(action, Action::Quit));
        assert!(spinner.is_finished());
        assert!(!spinner.output()); // false = failed
    }

    #[test]
    fn test_spinner_stop() {
        let mut spinner = Spinner::new("Loading");
        let action = spinner.update(SpinnerMsg::Stop);
        assert!(matches!(action, Action::Quit));
    }

    #[test]
    fn test_spinner_view_spinning_plain() {
        let spinner = Spinner::new("Loading data");
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            spinner.view(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "  Working... Loading data\n");
    }
