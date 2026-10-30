    #[test]
    fn test_component_update_cycle() {
        let mut counter = Counter { count: 0 };

        // Increment
        let action = counter.update(CounterMsg::Increment);
        assert!(matches!(action, Action::None));
        assert_eq!(counter.count, 1);

        // Decrement
        counter.update(CounterMsg::Decrement);
        assert_eq!(counter.count, 0);

        // Quit
        let action = counter.update(CounterMsg::Quit);
        assert!(matches!(action, Action::Quit));
        assert_eq!(counter.output(), 0);
    }

    #[test]
    fn test_renderable_output() {
        let msg = StaticMessage {
            text: "Hello, CAS!".to_string(),
        };
        let mut buf = Vec::new();
        let mut fmt = Formatter::plain(&mut buf);

        msg.render(&mut fmt).unwrap();
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Hello, CAS!"));
    }
