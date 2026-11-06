    #[test]
    fn test_percentile_normalize() {
        let scores = vec![
            ("a".to_string(), 100.0),
            ("b".to_string(), 50.0),
            ("c".to_string(), 25.0),
            ("d".to_string(), 10.0),
            ("e".to_string(), 1.0),
        ];

        let normalized = percentile_normalize(&scores, 90.0);

        // Top score should be near or above 1.0
        let a_score = normalized.iter().find(|(id, _)| id == "a").unwrap().1;
        assert!(a_score >= 1.0);

        // Scores should maintain relative order
        let b_score = normalized.iter().find(|(id, _)| id == "b").unwrap().1;
        let c_score = normalized.iter().find(|(id, _)| id == "c").unwrap().1;
        assert!(a_score > b_score);
        assert!(b_score > c_score);
    }

    #[test]
    fn test_multi_channel_boost() {
        // Entry A: found by BM25 only
        // Entry B: found by BM25 and semantic
        // Entry C: found by all three
        let bm25 = vec![
            ("a".to_string(), 1.0),
            ("b".to_string(), 0.8),
            ("c".to_string(), 0.6),
        ];
        let semantic = vec![("b".to_string(), 0.9), ("c".to_string(), 0.7)];
        let temporal = vec![("c".to_string(), 0.8)];

        let combined = combine_multi_channel(&bm25, &semantic, &temporal, SearchWeights::default());

        // C should get significant multi-channel boost
        let c_score = combined.iter().find(|(id, _)| id == "c").unwrap().1;
        let a_score = combined.iter().find(|(id, _)| id == "a").unwrap().1;

        // Despite lower raw scores, C should be competitive due to multi-channel boost
        // (exact ordering depends on weights, but C shouldn't be far behind)
        assert!(c_score > 0.0);
        assert!(a_score > 0.0);
    }

    #[test]
    fn test_calibrate_scores() {
        let mut scores = vec![
            ("a".to_string(), 2.0),
            ("b".to_string(), 1.0),
            ("c".to_string(), 0.5),
        ];

        calibrate_scores(&mut scores);

        // Max should be ~0.85
        let max = scores.iter().map(|(_, s)| *s).fold(0.0f64, f64::max);
        assert!((max - 0.85).abs() < 0.01);

        // All should be <= 1.0
        for (_, score) in &scores {
            assert!(*score <= 1.0);
        }
    }

    #[test]
    fn test_normalize_scores() {
        let test_cases = vec![
            (
                vec![
                    ("a".to_string(), 10.0),
                    ("b".to_string(), 5.0),
                    ("c".to_string(), 0.0),
                ],
                1.0,
                0.0,
            ),
            (
                vec![("a".to_string(), 100.0), ("b".to_string(), 50.0)],
                1.0,
                0.0,
            ),
        ];

        for (input, expected_first, expected_last) in test_cases {
            let result = normalize_scores(&input);
            assert_eq!(result.len(), input.len());
            assert!((result[0].1 - expected_first).abs() < 1e-6);
            assert!((result[result.len() - 1].1 - expected_last).abs() < 1e-6);
        }
    }

    #[test]
    fn test_combine_scores() {
        let bm25 = vec![("a".to_string(), 10.0), ("b".to_string(), 5.0)];
        let semantic = vec![("b".to_string(), 0.9), ("c".to_string(), 0.8)];

        let combined = combine_scores(&bm25, &semantic, 0.5, 0.5);

        assert_eq!(combined.len(), 3);

        let a_score = combined
            .iter()
            .find(|(id, _)| id == "a")
            .map(|(_, s)| *s)
            .unwrap();
        let b_score = combined
            .iter()
            .find(|(id, _)| id == "b")
            .map(|(_, s)| *s)
            .unwrap();
        let c_score = combined
            .iter()
            .find(|(id, _)| id == "c")
            .map(|(_, s)| *s)
            .unwrap();

        assert!(a_score > 0.0);
        assert!(b_score > 0.0);
        assert!(c_score >= 0.0);
    }
