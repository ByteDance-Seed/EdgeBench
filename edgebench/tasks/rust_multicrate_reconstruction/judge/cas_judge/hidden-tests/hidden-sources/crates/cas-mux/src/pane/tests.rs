    #[test]
    fn test_pane_feed_and_dump() {
        let mut pane = Pane::director("test", 24, 80).expect("create pane");
        pane.feed(b"Hello, World!").expect("feed");
        let content = pane.dump_viewport().expect("dump viewport");
        assert!(content.contains("Hello, World!"));
    }

    #[test]
    fn test_scrollback_info() {
        let pane = Pane::director("test", 24, 80).expect("create pane");
        let info = pane.scrollback_info();

        assert_eq!(info.viewport_offset, 0);
        assert_eq!(info.viewport_rows, 24);
        assert!(info.total_scrollback >= info.viewport_rows as u32);
    }

    #[test]
    fn test_create_snapshot_with_cache() {
        let mut pane = Pane::director("test", 5, 80).expect("create pane");

        for i in 0..30 {
            pane.feed(format!("Line {i}\r\n").as_bytes())
                .expect("feed line");
        }

        pane.scroll(-10).expect("scroll up");

        let (snapshot, cache_rows, cache_start) = pane
            .create_snapshot_with_cache(20)
            .expect("snapshot with cache");
        assert_eq!(snapshot.rows, 5);
        assert!(cache_start.is_some());

        for row in &cache_rows {
            assert!(row.screen_row < pane.scrollback_lines());
        }
    }
