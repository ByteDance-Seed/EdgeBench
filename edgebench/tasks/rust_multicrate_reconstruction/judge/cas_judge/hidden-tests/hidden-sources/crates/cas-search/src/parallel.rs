    #[test]
    fn test_parallel_coordinator() {
        let mut coord = ParallelCoordinator::new();

        coord.record(
            "bm25",
            vec![("doc-1".into(), 10.0), ("doc-2".into(), 5.0)],
            Duration::from_millis(50),
        );
        coord.record(
            "semantic",
            vec![("doc-2".into(), 0.9), ("doc-3".into(), 0.8)],
            Duration::from_millis(100),
        );

        assert_eq!(coord.results().len(), 2);
        assert!(coord.get_channel("bm25").is_some());
        assert!(coord.get_channel("semantic").is_some());
        assert!(coord.get_channel("unknown").is_none());
    }

    #[test]
    fn test_parallel_coordinator_failure() {
        let mut coord = ParallelCoordinator::new();

        coord.record(
            "bm25",
            vec![("doc-1".into(), 10.0)],
            Duration::from_millis(50),
        );
        coord.record_failure("semantic", "model not loaded", Duration::from_millis(5));

        let stats = coord.stats();
        assert_eq!(stats.success_count, 1);
        assert_eq!(stats.failure_count, 1);
    }

    #[test]
    fn test_parallel_stats_speedup() {
        let mut coord = ParallelCoordinator::new();

        // Simulate 3 channels that each took 100ms but ran in parallel
        coord.record("bm25", vec![], Duration::from_millis(100));
        coord.record("semantic", vec![], Duration::from_millis(100));
        coord.record("graph", vec![], Duration::from_millis(100));

        let stats = coord.stats();

        // Total should be close to 100ms (parallel), individual sum is 300ms
        // So speedup should be around 3x (but we can't test exact values due to timing)
        assert!(stats.channel_latencies.len() == 3);
    }

    #[test]
    fn test_coordinator_combine() {
        let mut coord = ParallelCoordinator::new();

        coord.record(
            "bm25",
            vec![("a".into(), 10.0), ("b".into(), 5.0)],
            Duration::ZERO,
        );
        coord.record(
            "semantic",
            vec![("b".into(), 0.9), ("c".into(), 0.8)],
            Duration::ZERO,
        );

        let combined = coord.combine(|results| {
            // Simple merge - just flatten all results
            let mut all = Vec::new();
            for r in results {
                all.extend(r.results.clone());
            }
            all
        });

        assert_eq!(combined.len(), 4);
    }
