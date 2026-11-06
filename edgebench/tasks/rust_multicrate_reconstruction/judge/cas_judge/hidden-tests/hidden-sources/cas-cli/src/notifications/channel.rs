    #[test]
    fn test_channel_notifier_dropped_receiver() {
        let (notifier, receiver) = ChannelNotifier::new();
        drop(receiver);

        // Should not panic when receiver is dropped
        let event =
            NotificationEvent::new(NotificationEventType::TaskCreated, "task-123", "Test task");
        notifier.notify(event);
    }
