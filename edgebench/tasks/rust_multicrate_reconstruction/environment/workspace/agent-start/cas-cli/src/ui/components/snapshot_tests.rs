//! Snapshot tests for all Formatter convenience methods and Renderable components.
//!
//! Each method/component is tested in plain mode (for readable, stable snapshots)
//! and with narrow terminal width (40 cols) to verify edge-case rendering.
//! Theme parity tests verify all render under all 3 theme modes without panics.

#[cfg(test)]
mod tests {
    use crate::ui::components::test_helpers::TestFormatter;
    use crate::ui::components::{
        Header, KeyValue, List, ListItem, Renderable, StatusGroup, StatusLine, Table,
    };
    use crate::ui::theme::ThemeMode;

    // ========================================================================
    // heading()
    // ========================================================================



    #[test]
    fn heading_styled_dark() {
        let mut tf = TestFormatter::dark();
        tf.fmt().heading("CAS Doctor").unwrap();
        insta::assert_snapshot!(tf.output_plain());
    }

    // ========================================================================
    // subheading()
    // ========================================================================

    #[test]
    fn subheading_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().subheading("Section Title").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn subheading_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().subheading("Section Title").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // status()
    // ========================================================================

    #[test]
    fn status_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().status("Store", "Connected").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn status_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().status("Store", "Connected").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn status_empty_value() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().status("Status", "").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // success()
    // ========================================================================

    #[test]
    fn success_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().success("All checks passed").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn success_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().success("All checks passed").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // warning()
    // ========================================================================

    #[test]
    fn warning_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().warning("Deprecated feature in use").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn warning_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().warning("Deprecated feature in use").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // error()
    // ========================================================================


    #[test]
    fn error_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().error("Connection failed").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // info()
    // ========================================================================


    #[test]
    fn info_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().info("3 tasks pending").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // field()
    // ========================================================================


    #[test]
    fn field_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().field("Status", "open").unwrap();
        insta::assert_snapshot!(tf.output());
    }


    // ========================================================================
    // field_accent()
    // ========================================================================

    #[test]
    fn field_accent_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().field_accent("ID", "cas-1234").unwrap();
        insta::assert_snapshot!(tf.output());
    }


    // ========================================================================
    // bullet()
    // ========================================================================

    #[test]
    fn bullet_single_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().bullet("First item").unwrap();
        insta::assert_snapshot!(tf.output());
    }



    // ========================================================================
    // separator()
    // ========================================================================

    #[test]
    fn separator_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().separator().unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn separator_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().separator().unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // indent_block()
    // ========================================================================

    #[test]
    fn indent_block_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt()
            .indent_block("Line one\nLine two\nLine three")
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }


    #[test]
    fn indent_block_single_line() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().indent_block("Just one line").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // key_hint()
    // ========================================================================

    #[test]
    fn key_hint_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().key_hint("q", "Quit").unwrap();
        insta::assert_snapshot!(tf.output());
    }


    #[test]
    fn key_hint_multiple() {
        let mut tf = TestFormatter::plain(80);
        {
            let mut fmt = tf.fmt();
            fmt.key_hint("q", "Quit").unwrap();
            fmt.key_hint("j/k", "Navigate").unwrap();
            fmt.key_hint("Enter", "Select").unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // progress()
    // ========================================================================

    #[test]
    fn progress_half_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().progress(5, 10).unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn progress_empty() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().progress(0, 10).unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn progress_full() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().progress(10, 10).unwrap();
        insta::assert_snapshot!(tf.output());
    }



    // ========================================================================
    // Combined output (simulating a command's full output)
    // ========================================================================

    #[test]
    fn combined_doctor_output_plain_80() {
        let mut tf = TestFormatter::plain(80);
        {
            let mut fmt = tf.fmt();
            fmt.heading("CAS Doctor").unwrap();
            fmt.newline().unwrap();
            fmt.subheading("Store").unwrap();
            fmt.field("Database", "/home/user/.cas/store.db").unwrap();
            fmt.field("Size", "2.4 MB").unwrap();
            fmt.success("Store connected").unwrap();
            fmt.newline().unwrap();
            fmt.subheading("Search Index").unwrap();
            fmt.field("Entries", "142").unwrap();
            fmt.success("Index healthy").unwrap();
            fmt.newline().unwrap();
            fmt.separator().unwrap();
            fmt.info("All systems operational").unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn combined_doctor_output_plain_40() {
        let mut tf = TestFormatter::plain(40);
        {
            let mut fmt = tf.fmt();
            fmt.heading("CAS Doctor").unwrap();
            fmt.newline().unwrap();
            fmt.subheading("Store").unwrap();
            fmt.field("Database", "/home/user/.cas/store.db").unwrap();
            fmt.success("Store connected").unwrap();
            fmt.newline().unwrap();
            fmt.separator().unwrap();
            fmt.info("All systems operational").unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }


    #[test]
    fn combined_key_hints_bar() {
        let mut tf = TestFormatter::plain(80);
        {
            let mut fmt = tf.fmt();
            fmt.separator().unwrap();
            fmt.key_hint("q", "Quit").unwrap();
            fmt.key_hint("j/k", "Navigate").unwrap();
            fmt.key_hint("Enter", "Select").unwrap();
            fmt.key_hint("?", "Help").unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // Edge cases
    // ========================================================================

    #[test]
    fn empty_heading() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().heading("").unwrap();
        insta::assert_snapshot!(tf.output());
    }


    #[test]
    fn unicode_content() {
        let mut tf = TestFormatter::plain(80);
        {
            let mut fmt = tf.fmt();
            fmt.heading("ユニコード テスト").unwrap();
            fmt.field("名前", "テスト").unwrap();
            fmt.success("完了").unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn wide_terminal_200() {
        let mut tf = TestFormatter::plain(200);
        {
            let mut fmt = tf.fmt();
            fmt.heading("Wide").unwrap();
            fmt.separator().unwrap();
            fmt.progress(7, 10).unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // Header component
    // ========================================================================

    #[test]
    fn header_h1_plain_80() {
        let mut tf = TestFormatter::plain(80);
        Header::h1("CAS Doctor").render(&mut tf.fmt()).unwrap();
        insta::assert_snapshot!(tf.output());
    }


    #[test]
    fn header_h2_plain() {
        let mut tf = TestFormatter::plain(80);
        Header::h2("Details").render(&mut tf.fmt()).unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn header_h3_plain() {
        let mut tf = TestFormatter::plain(80);
        Header::h3("Subsection").render(&mut tf.fmt()).unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn header_with_icon_plain() {
        let mut tf = TestFormatter::plain(80);
        Header::h1("Tasks")
            .with_icon("📋")
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn header_h1_styled_dark() {
        let mut tf = TestFormatter::dark();
        Header::h1("CAS Doctor").render(&mut tf.fmt()).unwrap();
        insta::assert_snapshot!(tf.output_plain());
    }

    // ========================================================================
    // StatusLine component
    // ========================================================================

    #[test]
    fn status_line_success_plain() {
        let mut tf = TestFormatter::plain(80);
        StatusLine::success("All checks passed")
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn status_line_error_plain() {
        let mut tf = TestFormatter::plain(80);
        StatusLine::error("Connection failed")
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }



    #[test]
    fn status_line_plain_40() {
        let mut tf = TestFormatter::plain(40);
        StatusLine::success("All checks passed")
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }


    // ========================================================================
    // KeyValue component
    // ========================================================================

    #[test]
    fn key_value_alignment_plain() {
        let mut tf = TestFormatter::plain(80);
        KeyValue::new()
            .add("ID", "cas-1234")
            .add("Status", "open")
            .add("Very Long Key Name", "value")
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn key_value_plain_40() {
        let mut tf = TestFormatter::plain(40);
        KeyValue::new()
            .add("ID", "cas-1234")
            .add("Title", "A task with a long title")
            .add("Status", "in_progress")
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn key_value_custom_separator() {
        let mut tf = TestFormatter::plain(80);
        KeyValue::new()
            .with_separator(" = ")
            .add("x", "1")
            .add("y", "2")
            .add("z", "3")
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn key_value_single_entry() {
        let mut tf = TestFormatter::plain(80);
        KeyValue::new()
            .add("Name", "CAS")
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn key_value_empty() {
        let mut tf = TestFormatter::plain(80);
        KeyValue::new().render(&mut tf.fmt()).unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // List component
    // ========================================================================

    #[test]
    fn list_bullet_plain_80() {
        let mut tf = TestFormatter::plain(80);
        List::bullet(vec![
            ListItem::new("First item"),
            ListItem::new("Second item"),
            ListItem::new("Third item"),
        ])
        .render(&mut tf.fmt())
        .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn list_bullet_plain_40() {
        let mut tf = TestFormatter::plain(40);
        List::bullet(vec![
            ListItem::new("Short"),
            ListItem::new("A longer item that may need wrapping"),
        ])
        .render(&mut tf.fmt())
        .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn list_numbered_plain() {
        let mut tf = TestFormatter::plain(80);
        List::numbered(vec![
            ListItem::new("Alpha"),
            ListItem::new("Beta"),
            ListItem::new("Gamma"),
        ])
        .render(&mut tf.fmt())
        .unwrap();
        insta::assert_snapshot!(tf.output());
    }


    #[test]
    fn list_empty() {
        let mut tf = TestFormatter::plain(80);
        List::bullet(vec![]).render(&mut tf.fmt()).unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn list_dash_plain() {
        let mut tf = TestFormatter::plain(80);
        List::dash(vec![ListItem::new("Item A"), ListItem::new("Item B")])
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // Table component
    // ========================================================================

    #[test]
    fn table_basic_plain_80() {
        let mut tf = TestFormatter::plain(80);
        Table::new()
            .columns(&["ID", "Title", "Status"])
            .rows(vec![
                vec!["cas-abc1", "Fix bug", "Open"],
                vec!["cas-def2", "Add feature", "Closed"],
            ])
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn table_narrow_terminal() {
        let mut tf = TestFormatter::plain(40);
        Table::new()
            .columns(&["ID", "Title", "Status"])
            .rows(vec![vec![
                "cas-abc1",
                "Very long task title that should truncate",
                "open",
            ]])
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn table_empty_rows() {
        let mut tf = TestFormatter::plain(80);
        Table::new()
            .columns(&["ID", "Name"])
            .rows(Vec::<Vec<&str>>::new())
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn table_no_border() {
        let mut tf = TestFormatter::plain(80);
        Table::new()
            .columns(&["Name", "Value"])
            .rows(vec![vec!["alpha", "1"], vec!["beta", "2"]])
            .border(crate::ui::components::table::Border::None)
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn table_ascii_border() {
        let mut tf = TestFormatter::plain(80);
        Table::new()
            .columns(&["Name", "Value"])
            .rows(vec![vec!["alpha", "1"], vec!["beta", "2"]])
            .border(crate::ui::components::table::Border::Ascii)
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn table_single_column() {
        let mut tf = TestFormatter::plain(80);
        Table::new()
            .columns(&["Items"])
            .rows(vec![vec!["one"], vec!["two"], vec!["three"]])
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    // ========================================================================
    // Combined component output
    // ========================================================================

    #[test]
    fn combined_components_doctor_style() {
        let mut tf = TestFormatter::plain(80);
        {
            let mut fmt = tf.fmt();
            Header::h1("CAS Doctor").render(&mut fmt).unwrap();
            fmt.newline().unwrap();
            StatusGroup::new()
                .push(StatusLine::success("Store connected"))
                .push(StatusLine::success("Schema up to date"))
                .push(StatusLine::warning("Index stale"))
                .render(&mut fmt)
                .unwrap();
            fmt.newline().unwrap();
            KeyValue::new()
                .add("Entries", "142")
                .add("Rules", "5")
                .add("Tasks", "23")
                .render(&mut fmt)
                .unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }


    // ========================================================================
    // Theme parity tests (including components)
    // ========================================================================


    #[test]
    fn all_components_render_light_theme() {
        let mut tf = TestFormatter::light();
        render_all_components(&mut tf);
        let output = tf.output_plain();
        assert!(!output.is_empty());
        assert!(output.contains("CAS Doctor"));
    }



    /// Render every component type for theme parity testing.
    fn render_all_components(tf: &mut TestFormatter) {
        let mut fmt = tf.fmt();
        Header::h1("CAS Doctor").render(&mut fmt).unwrap();
        Header::h2("Section").render(&mut fmt).unwrap();
        Header::h3("Subsection").render(&mut fmt).unwrap();
        StatusLine::success("Store connected")
            .render(&mut fmt)
            .unwrap();
        StatusLine::error("Auth failed").render(&mut fmt).unwrap();
        StatusLine::warning("Config stale")
            .render(&mut fmt)
            .unwrap();
        StatusLine::info("3 tasks").render(&mut fmt).unwrap();
        KeyValue::new()
            .add("ID", "cas-1234")
            .add("Status", "open")
            .render(&mut fmt)
            .unwrap();
        List::bullet(vec![
            ListItem::new("First item"),
            ListItem::new("Second item"),
        ])
        .render(&mut fmt)
        .unwrap();
        Table::new()
            .columns(&["ID", "Name"])
            .rows(vec![vec!["1", "test"]])
            .render(&mut fmt)
            .unwrap();
    }

    // ========================================================================
    // Theme parity tests (Formatter methods)
    // ========================================================================

    #[test]
    fn all_methods_render_dark_theme() {
        let mut tf = TestFormatter::dark();
        render_all_methods(&mut tf);
        let output = tf.output_plain();
        assert!(!output.is_empty());
        assert!(output.contains("Heading"));
        assert!(output.contains("Subheading"));
    }

    #[test]
    fn all_methods_render_light_theme() {
        let mut tf = TestFormatter::light();
        render_all_methods(&mut tf);
        let output = tf.output_plain();
        assert!(!output.is_empty());
        assert!(output.contains("Heading"));
        assert!(output.contains("Subheading"));
    }

    #[test]
    fn all_methods_render_high_contrast_theme() {
        let mut tf = TestFormatter::high_contrast();
        render_all_methods(&mut tf);
        let output = tf.output_plain();
        assert!(!output.is_empty());
        assert!(output.contains("Heading"));
        assert!(output.contains("Subheading"));
    }

    #[test]
    fn theme_parity_all_modes() {
        for mode in [ThemeMode::Dark, ThemeMode::Light, ThemeMode::HighContrast] {
            let mut tf = TestFormatter::with_theme(mode, 80);
            render_all_methods(&mut tf);
            let plain = tf.output_plain();
            assert!(!plain.is_empty(), "Theme {mode:?} produced empty output");
            assert!(plain.contains("Heading"), "Theme {mode:?} missing heading");
            assert!(
                plain.contains("success message"),
                "Theme {mode:?} missing success"
            );
            assert!(
                plain.contains("error message"),
                "Theme {mode:?} missing error"
            );
            assert!(plain.contains("50%"), "Theme {mode:?} missing progress");
        }
    }

    #[test]
    fn theme_parity_snapshot_dark() {
        let mut tf = TestFormatter::dark();
        render_all_methods(&mut tf);
        insta::assert_snapshot!(tf.output_plain());
    }

    #[test]
    fn theme_parity_snapshot_light() {
        let mut tf = TestFormatter::light();
        render_all_methods(&mut tf);
        insta::assert_snapshot!(tf.output_plain());
    }

    #[test]
    fn theme_parity_snapshot_high_contrast() {
        let mut tf = TestFormatter::high_contrast();
        render_all_methods(&mut tf);
        insta::assert_snapshot!(tf.output_plain());
    }

    /// Render every Formatter convenience method for parity testing.
    fn render_all_methods(tf: &mut TestFormatter) {
        let mut fmt = tf.fmt();
        fmt.heading("Heading").unwrap();
        fmt.subheading("Subheading").unwrap();
        fmt.status("Label", "Value").unwrap();
        fmt.success("success message").unwrap();
        fmt.warning("warning message").unwrap();
        fmt.error("error message").unwrap();
        fmt.info("info message").unwrap();
        fmt.field("Key", "value").unwrap();
        fmt.field_accent("Accent", "highlighted").unwrap();
        fmt.bullet("bullet item").unwrap();
        fmt.separator().unwrap();
        fmt.indent_block("indented\nblock").unwrap();
        fmt.key_hint("q", "Quit").unwrap();
        fmt.progress(5, 10).unwrap();
    }
}
