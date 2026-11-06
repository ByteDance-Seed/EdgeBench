    #[test]
    fn unified_iteration_produces_correct_sequence() {
        let diff = simple_diff();
        let props = IterateOverDiffProps::new(&diff, DiffStyle::Unified);
        let mut events = Vec::new();
        iterate_over_diff(&props, |e| {
            events.push(e);
            false
        });

        // 3 context + 2 deletions + 2 additions + 3 context = 10 events
        assert_eq!(events.len(), 10, "unified should emit 10 events");

        // First 3 are context
        for i in 0..3 {
            assert!(
                matches!(&events[i], DiffLineEvent::Context { .. }),
                "event {i} should be Context"
            );
        }

        // Next 4 are changes (2 del + 2 add in unified)
        for i in 3..7 {
            assert!(
                matches!(&events[i], DiffLineEvent::Change { .. }),
                "event {i} should be Change"
            );
        }

        // In unified mode, first 2 changes have deletion_line only
        if let DiffLineEvent::Change {
            deletion_line,
            addition_line,
            ..
        } = &events[3]
        {
            assert!(deletion_line.is_some(), "first change should have deletion");
            assert!(
                addition_line.is_none(),
                "first change should not have addition in unified"
            );
        }

        // Last 2 changes have addition_line only
        if let DiffLineEvent::Change {
            deletion_line,
            addition_line,
            ..
        } = &events[5]
        {
            assert!(
                deletion_line.is_none(),
                "third change should not have deletion in unified"
            );
            assert!(addition_line.is_some(), "third change should have addition");
        }

        // Last 3 are context
        for i in 7..10 {
            assert!(
                matches!(&events[i], DiffLineEvent::Context { .. }),
                "event {i} should be Context"
            );
        }
    }

    #[test]
    fn expanded_region_with_expansion_map() {
        let mut map = HashMap::new();
        map.insert(
            0,
            HunkExpansionRegion {
                from_start: 3,
                from_end: 2,
            },
        );
        let result = get_expanded_region(false, 20, Some(&map), false, 0, 1);
        assert_eq!(result.from_start, 3);
        assert_eq!(result.from_end, 2);
        assert_eq!(result.collapsed_lines, 15);
    }
