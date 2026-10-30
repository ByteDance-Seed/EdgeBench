    #[test]
    fn test_key_to_bytes_ctrl_d() {
        use crossterm::event::{KeyEvent, KeyEventKind, KeyEventState};
        let key = KeyEvent {
            code: KeyCode::Char('d'),
            modifiers: KeyModifiers::CONTROL,
            kind: KeyEventKind::Press,
            state: KeyEventState::empty(),
        };
        assert_eq!(key_to_bytes(&key), vec![0x04]);
    }

    #[test]
    fn test_key_to_bytes_arrow_keys() {
        use crossterm::event::{KeyEvent, KeyEventKind, KeyEventState};
        let key = KeyEvent {
            code: KeyCode::Up,
            modifiers: KeyModifiers::NONE,
            kind: KeyEventKind::Press,
            state: KeyEventState::empty(),
        };
        assert_eq!(key_to_bytes(&key), vec![0x1b, b'[', b'A']);
    }
