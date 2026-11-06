    #[test]
    fn test_newline() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"Line 1\r\nLine 2");
        assert_eq!(parser.buffer().row_text(0), "Line 1");
        assert_eq!(parser.buffer().row_text(1), "Line 2");
    }

    #[test]
    fn test_cursor_up_down() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"\x1b[10;10H"); // Move to row 10
        parser.process(b"\x1b[3A"); // Up 3
        assert_eq!(parser.buffer().cursor().row, 6);
        parser.process(b"\x1b[2B"); // Down 2
        assert_eq!(parser.buffer().cursor().row, 8);
    }

    #[test]
    fn test_clear_screen() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"Some text here");
        parser.process(b"\x1b[2J"); // Clear screen
        assert_eq!(parser.buffer().row_text(0), "");
    }

    #[test]
    fn test_256_color() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"\x1b[38;5;196mRed");
        let cell = parser.buffer().get_cell(0, 0).unwrap();
        assert_eq!(cell.fg, Color::Indexed(196));
    }

    #[test]
    fn test_rgb_color() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"\x1b[38;2;255;128;64mOrange");
        let cell = parser.buffer().get_cell(0, 0).unwrap();
        assert_eq!(cell.fg, Color::Rgb(255, 128, 64));
    }

    #[test]
    fn test_save_restore_cursor() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"\x1b[5;10H"); // Move to row 5, col 10
        parser.process(b"\x1b[s"); // Save
        parser.process(b"\x1b[1;1H"); // Move to origin
        parser.process(b"\x1b[u"); // Restore
        assert_eq!(parser.buffer().cursor().row, 4);
        assert_eq!(parser.buffer().cursor().col, 9);
    }

    #[test]
    fn test_contains_text() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"Welcome to the app!\r\nPress any key...");
        assert!(parser.buffer().contains_text("Welcome"));
        assert!(parser.buffer().contains_text("Press"));
        assert!(!parser.buffer().contains_text("Goodbye"));
    }
