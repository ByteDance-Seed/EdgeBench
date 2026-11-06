    #[test]
    fn file_header_renders() {
        let diff = test_diff();
        let area = Rect::new(0, 0, 60, 1);
        let mut buf = Buffer::empty(area);
        FileHeader::new(&diff).render(area, &mut buf);

        let content: String = buf
            .content()
            .iter()
            .map(|c| c.symbol().chars().next().unwrap_or(' '))
            .collect();
        assert!(
            content.contains("src/main.rs"),
            "header should contain filename"
        );
        assert!(
            content.contains("Modified"),
            "header should show change type"
        );
        assert!(content.contains("+1"), "header should show additions");
        assert!(content.contains("-1"), "header should show deletions");
    }

    #[test]
    fn scroll_state_navigation() {
        let mut state = DiffViewState {
            scroll_offset: 5,
            selected_hunk: None,
            viewport_height: 10,
        };

        state.scroll_up(3);
        assert_eq!(state.scroll_offset, 2);

        state.scroll_up(10);
        assert_eq!(state.scroll_offset, 0, "should not go below 0");

        state.scroll_down(15, 20);
        assert_eq!(state.scroll_offset, 15);

        state.scroll_down(10, 20);
        assert_eq!(state.scroll_offset, 19, "should clamp to max-1");
    }

    #[test]
    fn empty_diff_renders_without_panic() {
        let diff = FileDiffMetadata {
            name: "empty.rs".into(),
            prev_name: None,
            change_type: ChangeType::Change,
            hunks: vec![],
            split_line_count: 0,
            unified_line_count: 0,
            is_partial: true,
            deletion_lines: vec![],
            addition_lines: vec![],
        };

        let area = Rect::new(0, 0, 40, 5);
        let mut buf = Buffer::empty(area);
        let mut state = DiffViewState::default();

        DiffWidget::new(&diff, DiffStyle::Unified).render(area, &mut buf, &mut state);
        // Should not panic
    }
