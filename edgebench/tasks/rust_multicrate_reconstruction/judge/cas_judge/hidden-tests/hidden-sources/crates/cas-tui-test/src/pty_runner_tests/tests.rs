#[test]
fn test_config_builder() {
    let config = PtyRunnerConfig::with_size(120, 40)
        .env("FOO", "bar")
        .cwd("/tmp")
        .inherit_env();

    assert_eq!(config.cols, 120);
    assert_eq!(config.rows, 40);
    assert_eq!(config.env.get("FOO"), Some(&"bar".to_string()));
    assert_eq!(config.cwd, Some(PathBuf::from("/tmp")));
    assert!(!config.clear_env);
}

#[test]
fn test_key_bytes() {
    assert_eq!(Key::Enter.as_bytes(), b"\r");
    assert_eq!(Key::CtrlC.as_bytes(), b"\x03");
    assert_eq!(Key::Up.as_bytes(), b"\x1b[A");
}

#[test]
fn test_spawn_echo() {
    let mut runner = PtyRunner::new();
    runner.spawn("echo", &["hello"]).expect("spawn failed");

    // Give the process time to complete
    std::thread::sleep(std::time::Duration::from_millis(100));

    let output = runner.read_available().expect("read failed");
    assert!(output.contains("hello"), "output was: {}", output.as_str());
}
