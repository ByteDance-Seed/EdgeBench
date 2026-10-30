    #[test]
    fn test_typical_light_terminal_bg() {
        // Common light terminal backgrounds
        assert!(!is_dark_rgb(253, 246, 227)); // Solarized Light
        assert!(!is_dark_rgb(255, 255, 255)); // Pure white
        assert!(!is_dark_rgb(245, 245, 245)); // Light gray
        assert!(!is_dark_rgb(250, 250, 250)); // Near-white
    }

    #[test]
    fn test_normalize_2_digit() {
        assert_eq!(normalize_channel("FF"), Some(255));
        assert_eq!(normalize_channel("00"), Some(0));
        assert_eq!(normalize_channel("80"), Some(128));
        assert_eq!(normalize_channel("1A"), Some(26));
    }

    #[test]
    fn test_parse_osc11_light_background() {
        // Solarized Light background
        let response = b"\x1b]11;rgb:FDF6/E3E3/DBDB\x1b\\";
        assert_eq!(parse_osc11_response(response), Some(false));
    }

    #[test]
    fn test_colorfgbg_dark_bright_bg() {
        assert_eq!(parse_colorfgbg_value("0;8"), Some(true));
    }

    #[test]
    fn test_colorfgbg_light_white_bg() {
        assert_eq!(parse_colorfgbg_value("0;7"), Some(false));
    }

    #[test]
    fn test_colorfgbg_three_part() {
        // Some terminals use "fg;extra;bg" format
        assert_eq!(parse_colorfgbg_value("15;default;0"), Some(true));
    }

    #[test]
    fn test_colorfgbg_invalid_format() {
        assert_eq!(parse_colorfgbg_value("invalid"), None);
    }

    #[test]
    fn test_colorfgbg_empty() {
        assert_eq!(parse_colorfgbg_value(""), None);
    }

    #[test]
    fn test_detect_defaults_to_dark() {
        let _guard = ENV_LOCK.lock().unwrap();
        // In test environment (non-TTY, no COLORFGBG), should default to dark
        unsafe { std::env::remove_var("COLORFGBG") };
        let mode = detect_background_theme();
        assert_eq!(mode, ThemeMode::Dark);
    }
