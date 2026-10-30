use crate::pty_runner::*;

#[test]
fn test_config_default() {
    let config = PtyRunnerConfig::default();
    assert_eq!(config.cols, 80);
    assert_eq!(config.rows, 24);
    assert!(config.clear_env);
    assert!(config.env.contains_key("TERM"));
}


#[test]
fn test_output_buffer() {
    let mut buf = OutputBuffer::default();
    assert!(buf.is_empty());

    buf.append(b"Hello ");
    buf.append(b"World");
    assert_eq!(buf.as_str(), "Hello World");
    assert!(buf.contains("World"));
    assert_eq!(buf.len(), 11);

    buf.clear();
    assert!(buf.is_empty());
}



#[test]
fn test_spawn_with_env() {
    let config = PtyRunnerConfig::default().env("TEST_VAR", "test_value");
    let mut runner = PtyRunner::with_config(config);

    runner
        .spawn("sh", &["-c", "echo $TEST_VAR"])
        .expect("spawn failed");

    std::thread::sleep(std::time::Duration::from_millis(100));

    let output = runner.read_available().expect("read failed");
    assert!(
        output.contains("test_value"),
        "output was: {}",
        output.as_str()
    );
}

#[test]
fn test_send_input() {
    let mut runner = PtyRunner::new();
    runner.spawn("cat", &[]).expect("spawn failed");

    runner.send_input("test input\n").expect("send failed");
    std::thread::sleep(std::time::Duration::from_millis(100));

    let output = runner.read_available().expect("read failed");
    assert!(
        output.contains("test input"),
        "output was: {}",
        output.as_str()
    );

    runner.send_key(Key::CtrlD).expect("send key failed");
}

#[test]
fn test_terminal_size() {
    let config = PtyRunnerConfig::with_size(100, 50);
    let runner = PtyRunner::with_config(config);
    assert_eq!(runner.size(), (100, 50));
}
