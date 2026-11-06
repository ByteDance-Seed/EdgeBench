    #[test]
    fn test_empty_table() {
        let table = Table::new()
            .columns(&["ID", "Name"])
            .rows(Vec::<Vec<&str>>::new())
            .border(Border::Unicode);

        let output = render_plain(&table);
        assert!(output.contains("ID"));
        assert!(output.contains("Name"));
        assert!(output.contains("(empty)"));
    }

    #[test]
    fn test_format_cell_center() {
        assert_eq!(Table::format_cell("hi", 6, Align::Center), "  hi  ");
        // Odd padding: left gets floor, right gets ceil
        assert_eq!(Table::format_cell("hi", 5, Align::Center), " hi  ");
    }

    #[test]
    fn test_column_width_constraints() {
        let table = Table::new()
            .columns_detailed(vec![
                Column::new("A").width(Width::Fixed(5)),
                Column::new("B").width(Width::Min(3)),
                Column::new("C").width(Width::Max(4)),
            ])
            .rows(vec![vec!["x", "y", "longer"]]);

        let widths = table.compute_widths(80);
        assert_eq!(widths[0], 5); // Fixed
        assert!(widths[1] >= 3); // Min
        assert!(widths[2] <= 4); // Max
    }

    #[test]
    fn test_builder_chain() {
        // Verify builder methods return Self for chaining
        let table = Table::new()
            .columns(&["A", "B"])
            .rows(vec![vec!["1", "2"]])
            .border(Border::Ascii)
            .indent(2);

        assert_eq!(table.border, Border::Ascii);
        assert_eq!(table.indent, 2);
        assert_eq!(table.cols.len(), 2);
        assert_eq!(table.rows.len(), 1);
    }
