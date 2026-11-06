    #[test]
    fn test_cell_attrs() {
        let attrs = CellAttrs::none().with_bold().with_underline();
        assert!(attrs.bold);
        assert!(attrs.underline);
        assert!(!attrs.italic);
    }
