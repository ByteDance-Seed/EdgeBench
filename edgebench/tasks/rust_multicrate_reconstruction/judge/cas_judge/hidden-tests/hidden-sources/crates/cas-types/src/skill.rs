    #[test]
    fn test_skill_type_from_str() {
        assert_eq!(SkillType::from_str("command").unwrap(), SkillType::Command);
        assert_eq!(SkillType::from_str("mcp").unwrap(), SkillType::Mcp);
        assert_eq!(SkillType::from_str("plugin").unwrap(), SkillType::Plugin);
        assert_eq!(
            SkillType::from_str("internal").unwrap(),
            SkillType::Internal
        );
    }

    #[test]
    fn test_skill_new() {
        let skill = Skill::new("cas-sk01".to_string(), "Test Skill".to_string());
        assert_eq!(skill.id, "cas-sk01");
        assert_eq!(skill.name, "Test Skill");
        assert!(skill.is_enabled());
        assert_eq!(skill.usage_count, 0);
        // New invokable fields default to false/empty
        assert!(!skill.invokable);
        assert!(skill.argument_hint.is_empty());
    }
