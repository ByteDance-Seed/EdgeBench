    #[test]
    fn test_multi_parser_supported_languages() {
        let parser = MultiLanguageParser::new().unwrap();
        let langs = parser.supported_languages();
        assert!(langs.contains(&Language::Rust));
        assert!(langs.contains(&Language::TypeScript));
        assert!(langs.contains(&Language::JavaScript));
        assert!(langs.contains(&Language::Python));
        assert!(langs.contains(&Language::Go));
        assert!(langs.contains(&Language::Elixir));
    }
