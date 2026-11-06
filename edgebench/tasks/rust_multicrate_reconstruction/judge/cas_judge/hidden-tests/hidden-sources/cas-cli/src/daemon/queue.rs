    #[test]
    fn test_queue_push_pop() {
        let queue = TaskQueue::new();

        queue.push(MaintenanceTask::new(TaskType::PruneEntries));
        queue.push(MaintenanceTask::new(TaskType::GenerateEmbeddings));
        queue.push(MaintenanceTask::new(TaskType::ApplyDecay));

        // Should pop in priority order
        assert_eq!(queue.pop().unwrap().task_type, TaskType::GenerateEmbeddings);
        assert_eq!(queue.pop().unwrap().task_type, TaskType::ApplyDecay);
        assert_eq!(queue.pop().unwrap().task_type, TaskType::PruneEntries);
        assert!(queue.pop().is_none());
    }

    #[test]
    fn test_queue_max_size() {
        let queue = TaskQueue::with_max_size(2);

        assert!(queue.push(MaintenanceTask::new(TaskType::GenerateEmbeddings)));
        assert!(queue.push(MaintenanceTask::new(TaskType::ApplyDecay)));
        assert!(!queue.push(MaintenanceTask::new(TaskType::PruneEntries))); // Should fail

        assert_eq!(queue.len(), 2);
    }

    #[test]
    fn test_queue_remove_type() {
        let queue = TaskQueue::new();

        queue.push(MaintenanceTask::new(TaskType::GenerateEmbeddings));
        queue.push(MaintenanceTask::new(TaskType::ApplyDecay));
        queue.push(MaintenanceTask::new(TaskType::GenerateEmbeddings));

        queue.remove_type(TaskType::GenerateEmbeddings);

        assert_eq!(queue.len(), 1);
        assert!(!queue.contains(TaskType::GenerateEmbeddings));
        assert!(queue.contains(TaskType::ApplyDecay));
    }

    #[test]
    fn test_with_batch_size() {
        let task = MaintenanceTask::new(TaskType::GenerateEmbeddings).with_batch_size(50);
        assert_eq!(task.batch_size, Some(50));
    }
