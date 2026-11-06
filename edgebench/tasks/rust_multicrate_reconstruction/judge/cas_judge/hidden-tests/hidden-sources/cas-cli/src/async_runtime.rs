    #[test]
    fn test_progress_basic() {
        let progress = Progress::new(100);
        assert_eq!(progress.current(), 0);
        assert_eq!(progress.total(), 100);
        assert_eq!(progress.percentage(), 0.0);

        progress.set(50);
        assert_eq!(progress.current(), 50);
        assert_eq!(progress.percentage(), 50.0);

        progress.increment();
        assert_eq!(progress.current(), 51);

        progress.increment_by(9);
        assert_eq!(progress.current(), 60);
    }

    #[test]
    fn test_progress_format() {
        let progress = Progress::new(100);
        progress.set(50);

        let status = progress.format("Processing");
        assert!(status.contains("50/100"));
        assert!(status.contains("50%"));
    }

    #[test]
    fn test_batch_processor() {
        let items: Vec<i32> = (1..=10).collect();
        let processor = BatchProcessor::new(items, 3);

        assert_eq!(processor.len(), 10);

        let batches: Vec<_> = processor.batches().collect();
        assert_eq!(batches.len(), 4); // 10 items / 3 per batch = 4 batches
        assert_eq!(batches[0].len(), 3);
        assert_eq!(batches[3].len(), 1); // last batch has 1 item
    }
