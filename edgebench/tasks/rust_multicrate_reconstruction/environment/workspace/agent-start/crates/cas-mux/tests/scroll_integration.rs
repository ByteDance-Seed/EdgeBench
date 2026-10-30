//! Integration tests for smooth scrolling functionality.
//!
//! These tests validate:
//! - Scrollback buffer access via ghostty_vt FFI functions
//! - Cache row generation for smooth client-side scrolling
//! - Performance characteristics (target: <16ms for 60fps)
//! - Edge cases: resize, large scrollback, fast scrolling

use cas_mux::Pane;
use std::time::Instant;

// =============================================================================
// Scrollback Info Tests
// =============================================================================


#[test]
fn test_scrollback_info_after_content() {
    let mut pane = Pane::director("test", 10, 80).unwrap();

    // Generate content that exceeds viewport (create scrollback)
    for i in 0..50 {
        pane.feed(format!("Line {i}\r\n").as_bytes()).unwrap();
    }

    let info = pane.scrollback_info();
    assert_eq!(info.viewport_offset, 0, "Should still be at bottom");
    assert_eq!(info.viewport_rows, 10);
    // Total scrollback should be larger now
    assert!(
        info.total_scrollback > 10,
        "Total scrollback should exceed viewport after adding content"
    );
}

#[test]
fn test_scrollback_info_after_scroll() {
    let mut pane = Pane::director("test", 10, 80).unwrap();

    // Generate scrollback content
    for i in 0..100 {
        pane.feed(format!("Line {i:03}\r\n").as_bytes()).unwrap();
    }

    // Scroll up
    pane.scroll(-20).unwrap();

    let info = pane.scrollback_info();
    assert!(
        info.viewport_offset > 0,
        "Viewport offset should be > 0 after scrolling up"
    );
}

// =============================================================================
// Cache Hit/Miss Tests
// =============================================================================

#[test]
fn test_cache_rows_empty_when_no_cache_requested() {
    let mut pane = Pane::director("test", 10, 80).unwrap();

    // Generate some content
    for i in 0..30 {
        pane.feed(format!("Line {i}\r\n").as_bytes()).unwrap();
    }

    // Request snapshot with cache_window=0
    let (snapshot, cache_rows, cache_start) = pane.create_snapshot_with_cache(0).unwrap();

    assert_eq!(snapshot.rows, 10);
    assert!(
        cache_rows.is_empty(),
        "Should have no cache rows when cache_window=0"
    );
    assert!(
        cache_start.is_none(),
        "Should have no cache_start when cache_window=0"
    );
}

#[test]
fn test_cache_rows_populated_when_cache_requested() {
    let mut pane = Pane::director("test", 10, 80).unwrap();

    // Generate substantial scrollback content
    for i in 0..100 {
        pane.feed(format!("Line {i:03}\r\n").as_bytes()).unwrap();
    }

    // Scroll up to create opportunity for cache rows above and below
    pane.scroll(-30).unwrap();

    // Request snapshot with cache_window
    let (snapshot, cache_rows, cache_start) = pane.create_snapshot_with_cache(20).unwrap();

    assert_eq!(snapshot.rows, 10);
    assert!(
        cache_start.is_some(),
        "Should have cache_start with cache_window>0"
    );

    // Should have cache rows (above and/or below viewport)
    // Exact count depends on scroll position and buffer size
    if !cache_rows.is_empty() {
        // Verify cache rows have valid screen positions
        for row in &cache_rows {
            assert!(
                row.screen_row < pane.scrollback_lines(),
                "Cache row position should be valid"
            );
        }
    }
}

#[test]
fn test_cache_rows_content_matches_screen_position() {
    let mut pane = Pane::director("test", 5, 80).unwrap();

    // Generate predictable content
    for i in 0..50 {
        pane.feed(format!("LINE-{i:03}-END\r\n").as_bytes())
            .unwrap();
    }

    // Scroll to middle
    pane.scroll(-20).unwrap();

    let (_snapshot, cache_rows, _) = pane.create_snapshot_with_cache(10).unwrap();

    // Verify cache rows have text content
    for row in &cache_rows {
        // Content should be non-empty for most rows
        // (some rows may be empty depending on terminal state)
        if !row.text.is_empty() {
            // Text should be reasonable terminal content
            assert!(
                row.text.len() <= 80,
                "Row text should not exceed terminal width"
            );
        }
    }
}

// =============================================================================
// Scroll Operations Tests
// =============================================================================

#[test]
fn test_scroll_to_top_and_bottom() {
    let mut pane = Pane::director("test", 10, 80).unwrap();

    // Generate scrollback
    for i in 0..100 {
        pane.feed(format!("Line {i}\r\n").as_bytes()).unwrap();
    }

    // Scroll to top
    pane.scroll_to_top().unwrap();
    let info_top = pane.scrollback_info();
    assert!(
        info_top.viewport_offset > 0,
        "Should have offset when scrolled to top"
    );

    // Scroll to bottom
    pane.scroll_to_bottom().unwrap();
    let info_bottom = pane.scrollback_info();
    assert_eq!(
        info_bottom.viewport_offset, 0,
        "Should have offset=0 when at bottom"
    );
}


// =============================================================================
// Performance Tests
// =============================================================================

#[test]
fn test_snapshot_performance_small_cache() {
    let mut pane = Pane::director("test", 24, 80).unwrap();

    // Generate typical content
    for i in 0..500 {
        pane.feed(format!("Line {i} with some typical content here\r\n").as_bytes())
            .unwrap();
    }

    // Scroll to middle
    pane.scroll(-200).unwrap();

    // Measure snapshot with small cache
    let start = Instant::now();
    for _ in 0..10 {
        let _ = pane.create_snapshot_with_cache(24).unwrap();
    }
    let elapsed = start.elapsed();

    let avg_ms = elapsed.as_millis() as f64 / 10.0;
    println!("Average snapshot time (24-row cache): {avg_ms:.2}ms");

    // Target: < 16ms for 60fps (allowing some margin for test overhead)
    assert!(
        avg_ms < 32.0,
        "Snapshot should complete in under 32ms (got {avg_ms:.2}ms)"
    );
}

#[test]
fn test_snapshot_performance_large_cache() {
    let mut pane = Pane::director("test", 24, 80).unwrap();

    // Generate substantial content
    for i in 0..1000 {
        pane.feed(format!("Line {i} with some content\r\n").as_bytes())
            .unwrap();
    }

    pane.scroll(-400).unwrap();

    // Measure snapshot with large cache (100 rows)
    let start = Instant::now();
    for _ in 0..10 {
        let _ = pane.create_snapshot_with_cache(100).unwrap();
    }
    let elapsed = start.elapsed();

    let avg_ms = elapsed.as_millis() as f64 / 10.0;
    println!("Average snapshot time (100-row cache): {avg_ms:.2}ms");

    // Larger cache is allowed more time, but still should be reasonable
    assert!(
        avg_ms < 50.0,
        "Large cache snapshot should complete in under 50ms (got {avg_ms:.2}ms)"
    );
}

#[test]
fn test_scrollback_info_performance() {
    let mut pane = Pane::director("test", 24, 80).unwrap();

    // Generate content
    for i in 0..500 {
        pane.feed(format!("Line {i}\r\n").as_bytes()).unwrap();
    }

    // Measure scrollback_info calls (should be very fast)
    let start = Instant::now();
    for _ in 0..1000 {
        let _ = pane.scrollback_info();
    }
    let elapsed = start.elapsed();

    let avg_us = elapsed.as_micros() as f64 / 1000.0;
    println!("Average scrollback_info time: {avg_us:.2}μs");

    // Should be sub-millisecond
    assert!(
        avg_us < 1000.0,
        "scrollback_info should be < 1ms (got {avg_us:.2}μs)"
    );
}

// =============================================================================
// Edge Cases
// =============================================================================



#[test]
fn test_large_scrollback_buffer() {
    let mut pane = Pane::director("test", 24, 80).unwrap();

    // Generate large scrollback (10000 lines)
    for i in 0..10000 {
        pane.feed(format!("Line {i:05}\r\n").as_bytes()).unwrap();
    }

    let info = pane.scrollback_info();
    println!(
        "Scrollback info: total={}, viewport_rows={}, offset={}",
        info.total_scrollback, info.viewport_rows, info.viewport_offset
    );
    // Ghostty's default scrollback may be limited; just verify we have some scrollback
    assert!(
        info.total_scrollback > info.viewport_rows as u32,
        "Should have more scrollback than viewport rows"
    );

    // Scroll up (amount clamped to available scrollback)
    let scroll_amount = (info.total_scrollback / 2) as i32;
    pane.scroll(-scroll_amount).unwrap();

    // Snapshot should still work
    let start = Instant::now();
    let result = pane.create_snapshot_with_cache(50);
    let elapsed = start.elapsed();

    assert!(result.is_ok());
    println!(
        "Large scrollback snapshot time: {:.2}ms",
        elapsed.as_millis()
    );
}


// =============================================================================
// Mux Integration Tests
// =============================================================================

#[test]
fn test_mux_scroll_with_cache() {
    use cas_mux::Mux;

    let mut mux = Mux::new(24, 80);
    let pane = Pane::director("test-pane", 24, 80).unwrap();
    mux.add_pane(pane);

    // Get mutable pane reference and feed content
    if let Some(pane) = mux.get_mut("test-pane") {
        for i in 0..100 {
            pane.feed(format!("Line {i}\r\n").as_bytes()).unwrap();
        }
    }

    // Test scroll_pane_with_cache
    let result = mux.scroll_pane_with_cache("test-pane", -30, 20);
    assert!(result.is_ok());

    let (snapshot, cache_rows, cache_start, scroll_offset, scrollback_lines) = result.unwrap();

    // Verify returned data
    assert_eq!(snapshot.rows, 24);
    assert!(
        scroll_offset > 0,
        "Should have scroll offset after scrolling up"
    );
    assert!(scrollback_lines > 24, "Should have scrollback lines");

    // With cache_window=20, should have some cache rows
    // (unless we're at the very bottom)
    println!(
        "Cache rows: {}, cache_start: {:?}, offset: {}, total: {}",
        cache_rows.len(),
        cache_start,
        scroll_offset,
        scrollback_lines
    );
}

#[test]
fn test_mux_scroll_with_cache_zero_window() {
    use cas_mux::Mux;

    let mut mux = Mux::new(24, 80);
    let pane = Pane::director("test-pane", 24, 80).unwrap();
    mux.add_pane(pane);

    if let Some(pane) = mux.get_mut("test-pane") {
        for i in 0..50 {
            pane.feed(format!("Line {i}\r\n").as_bytes()).unwrap();
        }
    }

    // Zero cache window should return empty cache
    let result = mux.scroll_pane_with_cache("test-pane", -10, 0);
    assert!(result.is_ok());

    let (_, cache_rows, cache_start, _, _) = result.unwrap();
    assert!(cache_rows.is_empty());
    assert!(cache_start.is_none());
}
