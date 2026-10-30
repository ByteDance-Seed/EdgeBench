    #[test]
    fn test_team_color_rgb_known() {
        assert_eq!(team_color_rgb("green"), Color::Rgb(74, 222, 128));
        assert_eq!(team_color_rgb("blue"), Color::Rgb(96, 165, 250));
        assert_eq!(team_color_rgb("magenta"), Color::Rgb(232, 121, 249));
    }

    #[test]
    fn test_all_palette_colors_distinct() {
        let colors: Vec<Color> = AUTO_ASSIGN_ORDER
            .iter()
            .map(|name| team_color_rgb(name))
            .collect();
        for i in 0..colors.len() {
            for j in (i + 1)..colors.len() {
                assert_ne!(
                    colors[i], colors[j],
                    "{} and {} have the same RGB",
                    AUTO_ASSIGN_ORDER[i], AUTO_ASSIGN_ORDER[j]
                );
            }
        }
    }
