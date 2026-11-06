    #[test]
    fn ignores_non_image_paste_content() {
        assert!(!contains_dropped_image_path("hello world\n/tmp/readme.md"));
    }

    #[test]
    fn key_to_bytes_encodes_ctrl_digit_five_as_group_separator() {
        let key = KeyEvent {
            code: KeyCode::Char('5'),
            modifiers: KeyModifiers::CONTROL,
            kind: KeyEventKind::Press,
            state: KeyEventState::empty(),
        };
        assert_eq!(key_to_bytes(&key), vec![0x1d]);
    }
