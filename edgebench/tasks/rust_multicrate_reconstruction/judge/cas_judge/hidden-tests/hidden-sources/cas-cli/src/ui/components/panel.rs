    #[test]
    fn test_panel_empty_content_plain() {
        let panel = Panel::new("Empty");
        let output = render_plain(&panel);

        assert!(output.contains("Empty"));
        // Top and bottom borders
        let lines: Vec<&str> = output.lines().collect();
        assert!(lines.len() >= 3); // top + empty content + bottom
    }

    #[test]
    fn test_panel_consistent_border_width() {
        let panel = Panel::new("Title")
            .content(TextBlock("abc".to_string()))
            .content(TextBlock("longer content here".to_string()));

        let output = render_plain(&panel);
        let lines: Vec<&str> = output.lines().collect();

        // All lines should have the same width
        let widths: Vec<usize> = lines.iter().map(|l| l.chars().count()).collect();
        let first_width = widths[0];
        for (i, &w) in widths.iter().enumerate() {
            assert_eq!(
                w, first_width,
                "Line {i} has width {w}, expected {first_width}: {:?}",
                lines[i]
            );
        }
    }
