    #[test]
    fn test_visibility_default() {
        assert_eq!(Visibility::default(), Visibility::Private);
    }

    #[test]
    fn test_visibility_from_str() {
        assert_eq!(Visibility::from_str("private").unwrap(), Visibility::Private);
        assert_eq!(Visibility::from_str("priv").unwrap(), Visibility::Private);
        assert_eq!(Visibility::from_str("team").unwrap(), Visibility::Team);
        assert_eq!(Visibility::from_str("organization").unwrap(), Visibility::Organization);
        assert_eq!(Visibility::from_str("org").unwrap(), Visibility::Organization);
        assert_eq!(Visibility::from_str("public").unwrap(), Visibility::Public);
        assert_eq!(Visibility::from_str("pub").unwrap(), Visibility::Public);
        assert!(Visibility::from_str("invalid").is_err());
    }

    #[test]
    fn test_visibility_is_methods() {
        assert!(Visibility::Private.is_private());
        assert!(!Visibility::Private.is_team());
        assert!(!Visibility::Private.is_organization());
        assert!(!Visibility::Private.is_public());

        assert!(!Visibility::Team.is_private());
        assert!(Visibility::Team.is_team());

        assert!(Visibility::Organization.is_organization());
        assert!(Visibility::Public.is_public());
    }
