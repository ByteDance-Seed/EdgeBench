#[test]
fn test_about_screen() {
    let config = PtyRunnerConfig::with_size(80, 24);
    let mut runner = PtyRunner::with_config(config);

    runner.spawn(&test_tui_binary(), &[]).unwrap();
    wait_for_render(&mut runner);

    runner
        .wait_for_text_timeout("Menu", Duration::from_secs(3))
        .unwrap();

    // Navigate to About (third item)
    runner.send_key(Key::Down).unwrap();
    std::thread::sleep(Duration::from_millis(100));
    runner.send_key(Key::Down).unwrap();
    std::thread::sleep(Duration::from_millis(100));
    runner.send_key(Key::Enter).unwrap();
    wait_for_render(&mut runner);

    // Wait for About screen
    runner
        .wait_for_text_timeout("About", Duration::from_secs(3))
        .expect("Should enter About screen");

    // Verify about content
    let output = runner.get_output();
    assert!(
        output.contains("Version") || output.contains("1.0.0"),
        "Should show version info"
    );

    // Use assertion DSL
    let output_str = output.as_str();
    let scr = screen(&output_str);
    scr.assert_contains("TUI").unwrap();

    // Go back
    runner.send_key(Key::Enter).unwrap();
    runner
        .wait_for_text_timeout("Menu", Duration::from_secs(3))
        .expect("Should return to main menu");

    // Clean exit
    runner.send_input("q").unwrap();
}

#[test]
fn test_vt_parser_with_tui() {
    let config = PtyRunnerConfig::with_size(80, 24);
    let mut runner = PtyRunner::with_config(config);

    runner.spawn(&test_tui_binary(), &[]).unwrap();
    wait_for_render(&mut runner);

    runner
        .wait_for_text_timeout("Menu", Duration::from_secs(3))
        .unwrap();

    wait_for_render(&mut runner);

    // Read output and parse through VT parser
    let output = runner.read_available().unwrap();
    let mut parser = VtParser::new(80, 24);
    parser.process(output.as_bytes());

    // Check parsed buffer
    let buffer = parser.buffer();
    assert!(
        buffer.contains_text("TUI") || buffer.contains_text("Menu"),
        "Buffer should contain TUI content"
    );

    // Clean exit
    runner.send_input("q").unwrap();
}
