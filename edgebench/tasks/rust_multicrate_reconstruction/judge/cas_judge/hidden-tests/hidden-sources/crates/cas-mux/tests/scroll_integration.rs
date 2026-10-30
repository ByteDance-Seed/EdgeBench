#[test]
fn test_scrollback_info_initial_state() {
    let pane = Pane::director("test", 24, 80).unwrap();
    let info = pane.scrollback_info();

    // At initial state, should be at bottom with viewport_rows matching terminal size
    assert_eq!(info.viewport_offset, 0, "Should start at bottom");
    assert_eq!(info.viewport_rows, 24, "Should match terminal rows");
    assert!(
        info.total_scrollback >= info.viewport_rows as u32,
        "Total scrollback should be at least viewport rows"
    );
}

#[test]
fn test_scroll_incremental() {
    let mut pane = Pane::director("test", 10, 80).unwrap();

    // Generate scrollback
    for i in 0..100 {
        pane.feed(format!("Line {i}\r\n").as_bytes()).unwrap();
    }

    // Start at bottom
    let info1 = pane.scrollback_info();
    assert_eq!(info1.viewport_offset, 0);

    // Scroll up by 5 lines
    pane.scroll(-5).unwrap();
    let info2 = pane.scrollback_info();
    assert!(
        info2.viewport_offset >= 5,
        "Should scroll up by at least 5 lines"
    );

    // Scroll down by 3 lines
    pane.scroll(3).unwrap();
    let info3 = pane.scrollback_info();
    assert!(
        info3.viewport_offset < info2.viewport_offset,
        "Should scroll down (reduce offset)"
    );
}

#[test]
fn test_resize_during_scroll() {
    let mut pane = Pane::director("test", 24, 80).unwrap();

    // Generate content
    for i in 0..100 {
        pane.feed(format!("Line {i}\r\n").as_bytes()).unwrap();
    }

    // Scroll up
    pane.scroll(-30).unwrap();
    let info_before = pane.scrollback_info();
    assert!(info_before.viewport_offset > 0);

    // Resize terminal
    pane.resize(48, 120).unwrap();

    // Should still be able to get scrollback info and snapshots
    let info_after = pane.scrollback_info();
    assert_eq!(info_after.viewport_rows, 48, "Should reflect new row count");

    // Snapshot should work after resize
    let result = pane.create_snapshot_with_cache(10);
    assert!(result.is_ok(), "Snapshot should succeed after resize");
}

#[test]
fn test_empty_terminal_scrollback() {
    let pane = Pane::director("test", 24, 80).unwrap();

    // Empty terminal should still provide valid scrollback info
    let info = pane.scrollback_info();
    assert_eq!(info.viewport_rows, 24);
    assert_eq!(info.viewport_offset, 0);

    // Snapshot of empty terminal should work
    let result = pane.create_snapshot_with_cache(10);
    assert!(result.is_ok());
}

#[test]
fn test_rapid_scroll_operations() {
    let mut pane = Pane::director("test", 24, 80).unwrap();

    // Generate content
    for i in 0..500 {
        pane.feed(format!("Line {i}\r\n").as_bytes()).unwrap();
    }

    // Rapid scroll operations (simulating fast mouse wheel)
    let start = Instant::now();
    for _ in 0..100 {
        pane.scroll(-1).unwrap();
        let _ = pane.scrollback_info();
    }
    let elapsed = start.elapsed();

    let avg_ms = elapsed.as_millis() as f64 / 100.0;
    println!("Average scroll + info time: {avg_ms:.2}ms");

    // Should be fast enough for smooth scrolling
    assert!(
        avg_ms < 5.0,
        "Scroll operations should be < 5ms each (got {avg_ms:.2}ms)"
    );
}
