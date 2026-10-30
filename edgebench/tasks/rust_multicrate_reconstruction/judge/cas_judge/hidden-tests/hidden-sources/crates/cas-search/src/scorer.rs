    #[test]
    fn test_apply_multi_channel_boost() {
        let scores = vec![
            ("a".into(), 0.8, 1usize), // 1 channel
            ("b".into(), 0.6, 2),      // 2 channels
            ("c".into(), 0.5, 3),      // 3 channels
        ];

        let boosted = apply_multi_channel_boost(&scores, 0.15);

        let a = boosted.iter().find(|(id, _)| id == "a").unwrap().1;
        let b = boosted.iter().find(|(id, _)| id == "b").unwrap().1;
        let c = boosted.iter().find(|(id, _)| id == "c").unwrap().1;

        // a: 0.8 * 1.0 = 0.8
        assert!((a - 0.8).abs() < 1e-6);
        // b: 0.6 * 1.15 = 0.69
        assert!((b - 0.69).abs() < 1e-6);
        // c: 0.5 * 1.30 = 0.65
        assert!((c - 0.65).abs() < 1e-6);
    }

    #[test]
    fn test_reciprocal_rank_fusion() {
        let ranking1 = vec![("a".into(), 10.0), ("b".into(), 5.0)];
        let ranking2 = vec![("b".into(), 0.9), ("a".into(), 0.5)];

        let combined = reciprocal_rank_fusion(&[ranking1, ranking2], 60.0);

        assert_eq!(combined.len(), 2);

        // Both should have positive scores
        for (_, score) in &combined {
            assert!(*score > 0.0);
        }
    }

    #[test]
    fn test_reciprocal_rank_fusion_empty() {
        let combined = reciprocal_rank_fusion(&[], 60.0);
        assert!(combined.is_empty());
    }
