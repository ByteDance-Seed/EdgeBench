    #[test]
    fn test_input_sequence_builder() {
        let seq = input().text("hello").enter().wait_ms(100).key(Key::CtrlC);

        assert_eq!(seq.actions().len(), 4);
        assert!(matches!(&seq.actions()[0], InputAction::Text(s) if s == "hello"));
        assert!(matches!(&seq.actions()[1], InputAction::Key(Key::Enter)));
        assert!(matches!(&seq.actions()[2], InputAction::Wait(_)));
        assert!(matches!(&seq.actions()[3], InputAction::Key(Key::CtrlC)));
    }

    #[test]
    fn test_execute_on_runner() {
        let mut runner = PtyRunner::new();
        runner.spawn("cat", &[]).expect("spawn failed");

        let seq = input().text("test").enter();
        seq.execute(&mut runner).expect("execute failed");

        std::thread::sleep(Duration::from_millis(50));
        let output = runner.read_available().expect("read failed");
        assert!(output.contains("test"), "output: {}", output.as_str());

        runner.send_key(Key::CtrlD).expect("ctrl-d failed");
    }
