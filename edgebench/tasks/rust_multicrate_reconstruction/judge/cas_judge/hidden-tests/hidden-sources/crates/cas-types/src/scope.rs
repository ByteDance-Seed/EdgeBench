    #[test]
    fn test_scope_display() {
        assert_eq!(Scope::Global.to_string(), "global");
        assert_eq!(Scope::Project.to_string(), "project");
    }

    #[test]
    fn test_scope_filter_from_str() {
        assert_eq!(ScopeFilter::from_str("all").unwrap(), ScopeFilter::All);
        assert_eq!(ScopeFilter::from_str("both").unwrap(), ScopeFilter::All);
        assert_eq!(
            ScopeFilter::from_str("global").unwrap(),
            ScopeFilter::Global
        );
        assert_eq!(
            ScopeFilter::from_str("project").unwrap(),
            ScopeFilter::Project
        );
    }
