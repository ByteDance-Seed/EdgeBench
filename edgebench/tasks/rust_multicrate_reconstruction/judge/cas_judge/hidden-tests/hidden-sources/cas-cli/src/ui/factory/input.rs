    #[test]
    fn test_layout_sizes_default() {
        let sizes = LayoutSizes::default();
        assert_eq!(sizes.workers, 50);
        assert_eq!(sizes.supervisor, 30);
        assert_eq!(sizes.sidecar, 20);
    }
