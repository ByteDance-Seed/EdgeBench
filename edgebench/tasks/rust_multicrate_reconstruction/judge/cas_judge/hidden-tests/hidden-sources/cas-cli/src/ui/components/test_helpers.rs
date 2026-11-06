    #[test]
    fn test_strip_ansi_codes_empty() {
        assert_eq!(strip_ansi_codes(""), "");
    }

    #[test]
    fn test_test_formatter_dark() {
        let mut tf = TestFormatter::dark();
        tf.fmt().heading("Test").unwrap();
        let output = tf.output();
        assert!(output.contains("Test"));
        // Styled output should have ANSI codes
        assert!(output.contains('\x1b'));
    }
