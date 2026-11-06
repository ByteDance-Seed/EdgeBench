    #[test]
    fn test_watch_event_clone() {
        // Ensure WatchEvent implements Clone
        let event = WatchEvent::Error("test".to_string());
        let cloned = event.clone();
        match cloned {
            WatchEvent::Error(msg) => assert_eq!(msg, "test"),
            _ => panic!("Expected Error variant"),
        }
    }
