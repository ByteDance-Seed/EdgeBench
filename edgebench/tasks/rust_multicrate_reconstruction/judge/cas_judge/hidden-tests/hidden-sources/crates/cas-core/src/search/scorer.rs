    #[test]
    fn test_search_weights_sum_to_one() {
        for query_type in [
            QueryType::Exact,
            QueryType::Technical,
            QueryType::Temporal,
            QueryType::Keyword,
            QueryType::Conceptual,
            QueryType::Balanced,
        ] {
            let weights = SearchWeights::for_query_type(query_type).normalized();
            let sum = weights.bm25 + weights.semantic + weights.temporal;
            assert!(
                (sum - 1.0).abs() < 1e-6,
                "Weights for {query_type:?} sum to {sum}"
            );
        }
    }

    #[test]
    fn test_rrf_with_magnitude() {
        let ranking1 = vec![
            ("a".to_string(), 10.0), // Clear #1
            ("b".to_string(), 2.0),
        ];
        let ranking2 = vec![
            ("b".to_string(), 0.9), // Clear #1 in this ranking
            ("a".to_string(), 0.1),
        ];

        let combined = rrf_with_magnitude(&[ranking1, ranking2], 60.0);

        // Both should be present
        assert_eq!(combined.len(), 2);

        // Both appeared in both rankings
        let a_score = combined.iter().find(|(id, _)| id == "a").unwrap().1;
        let b_score = combined.iter().find(|(id, _)| id == "b").unwrap().1;
        assert!(a_score > 0.0);
        assert!(b_score > 0.0);
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
    fn test_normalize_scores_empty() {
        let result = normalize_scores(&[]);
        assert!(result.is_empty());
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
