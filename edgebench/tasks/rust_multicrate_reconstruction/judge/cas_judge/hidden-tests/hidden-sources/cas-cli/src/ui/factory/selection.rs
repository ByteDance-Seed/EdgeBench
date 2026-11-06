    #[test]
    fn test_selection_contains_multi_line() {
        let sel = Selection {
            pane_name: "test".to_string(),
            start: (5, 10),
            end: (7, 5),
            is_active: false,
            scroll_offset: 0,
        };

        // First line: col >= 10
        assert!(!sel.contains(5, 9));
        assert!(sel.contains(5, 10));
        assert!(sel.contains(5, 100));

        // Middle line: all columns
        assert!(sel.contains(6, 0));
        assert!(sel.contains(6, 50));

        // Last line: col <= 5
        assert!(sel.contains(7, 0));
        assert!(sel.contains(7, 5));
        assert!(!sel.contains(7, 6));
    }

    #[test]
    fn test_apply_selection_with_scroll_delta() {
        let line = Line::from(vec![Span::raw("Hello World")]);
        let sel = Selection {
            pane_name: "test".to_string(),
            start: (2, 0),
            end: (2, 4),
            is_active: false,
            scroll_offset: 0,
        };

        // Selection at row 2 with scroll_delta=3 means it now appears at viewport row 5
        let highlighted = apply_selection_to_line(line.clone(), 5, &sel, 3);
        assert_eq!(highlighted.spans.len(), 2); // Should highlight at adjusted row

        // Row 2 should no longer be highlighted (selection moved to row 5)
        let not_highlighted = apply_selection_to_line(line, 2, &sel, 3);
        assert_eq!(not_highlighted.spans.len(), 1); // No highlight
    }
