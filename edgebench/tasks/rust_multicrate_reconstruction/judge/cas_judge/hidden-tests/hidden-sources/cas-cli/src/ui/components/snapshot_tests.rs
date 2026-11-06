    #[test]
    fn heading_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().heading("CAS Doctor").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn heading_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().heading("CAS Doctor").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn error_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().error("Connection failed").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn info_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().info("3 tasks pending").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn field_plain_80() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().field("Status", "open").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn field_long_value() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt()
            .field(
                "Description",
                "A very long description that exceeds the terminal width",
            )
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn field_accent_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().field_accent("ID", "cas-1234").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn bullet_multiple_plain_80() {
        let mut tf = TestFormatter::plain(80);
        {
            let mut fmt = tf.fmt();
            fmt.bullet("First item").unwrap();
            fmt.bullet("Second item").unwrap();
            fmt.bullet("Third item").unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn bullet_plain_40() {
        let mut tf = TestFormatter::plain(40);
        {
            let mut fmt = tf.fmt();
            fmt.bullet("Short").unwrap();
            fmt.bullet("A longer bullet that wraps at narrow width")
                .unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn indent_block_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().indent_block("Short\nNarrow block").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn key_hint_plain_40() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt().key_hint("Enter", "Select item").unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn progress_zero_total() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().progress(0, 0).unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn progress_partial() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().progress(3, 7).unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn combined_task_list_plain() {
        let mut tf = TestFormatter::plain(80);
        {
            let mut fmt = tf.fmt();
            fmt.heading("Tasks").unwrap();
            fmt.newline().unwrap();
            fmt.field_accent("ID", "cas-abc1").unwrap();
            fmt.field("Title", "Build testing harness").unwrap();
            fmt.field("Status", "in_progress").unwrap();
            fmt.field("Priority", "P1").unwrap();
            fmt.newline().unwrap();
            fmt.separator().unwrap();
            fmt.newline().unwrap();
            fmt.field_accent("ID", "cas-def2").unwrap();
            fmt.field("Title", "Migrate doctor command").unwrap();
            fmt.field("Status", "open").unwrap();
            fmt.field("Priority", "P2").unwrap();
            fmt.newline().unwrap();
            fmt.separator().unwrap();
            fmt.info("2 tasks shown").unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn very_long_heading() {
        let mut tf = TestFormatter::plain(40);
        tf.fmt()
            .heading("A Very Long Heading That Definitely Exceeds Width")
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn header_h1_plain_40() {
        let mut tf = TestFormatter::plain(40);
        Header::h1("CAS Doctor").render(&mut tf.fmt()).unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn status_line_warning_plain() {
        let mut tf = TestFormatter::plain(80);
        StatusLine::warning("Deprecated feature")
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn status_line_info_plain() {
        let mut tf = TestFormatter::plain(80);
        StatusLine::info("3 tasks pending")
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn status_group_plain() {
        let mut tf = TestFormatter::plain(80);
        StatusGroup::new()
            .push(StatusLine::success("Store connected"))
            .push(StatusLine::success("Index healthy"))
            .push(StatusLine::warning("Config missing"))
            .push(StatusLine::error("Auth failed"))
            .render(&mut tf.fmt())
            .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn list_nested_plain() {
        let mut tf = TestFormatter::plain(80);
        List::bullet(vec![
            ListItem::new("Parent"),
            ListItem::with_children(
                "Has children",
                vec![
                    ListItem::new("Child A"),
                    ListItem::with_children("Child B", vec![ListItem::new("Grandchild")]),
                ],
            ),
            ListItem::new("Another top-level"),
        ])
        .render(&mut tf.fmt())
        .unwrap();
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn combined_components_task_view() {
        let mut tf = TestFormatter::plain(80);
        {
            let mut fmt = tf.fmt();
            Header::h2("Task Details").render(&mut fmt).unwrap();
            KeyValue::new()
                .add("ID", "cas-10a4")
                .add("Title", "Build testing harness")
                .add("Status", "in_progress")
                .add("Priority", "P1")
                .render(&mut fmt)
                .unwrap();
            fmt.newline().unwrap();
            Header::h3("Dependencies").render(&mut fmt).unwrap();
            List::bullet(vec![
                ListItem::new("cas-277c (closed)"),
                ListItem::new("cas-737b (blocked)"),
            ])
            .render(&mut fmt)
            .unwrap();
        }
        insta::assert_snapshot!(tf.output());
    }

    #[test]
    fn all_components_render_dark_theme() {
        let mut tf = TestFormatter::dark();
        render_all_components(&mut tf);
        let output = tf.output_plain();
        assert!(!output.is_empty());
        assert!(output.contains("CAS Doctor"));
        assert!(output.contains("cas-1234"));
    }

    #[test]
    fn all_components_render_high_contrast_theme() {
        let mut tf = TestFormatter::high_contrast();
        render_all_components(&mut tf);
        let output = tf.output_plain();
        assert!(!output.is_empty());
        assert!(output.contains("CAS Doctor"));
    }

    #[test]
    fn component_theme_parity_all_modes() {
        for mode in [ThemeMode::Dark, ThemeMode::Light, ThemeMode::HighContrast] {
            let mut tf = TestFormatter::with_theme(mode, 80);
            render_all_components(&mut tf);
            let plain = tf.output_plain();
            assert!(
                !plain.is_empty(),
                "Theme {mode:?} produced empty component output"
            );
            assert!(
                plain.contains("CAS Doctor"),
                "Theme {mode:?} missing Header"
            );
            assert!(
                plain.contains("Store connected"),
                "Theme {mode:?} missing StatusLine"
            );
            assert!(
                plain.contains("cas-1234"),
                "Theme {mode:?} missing KeyValue"
            );
            assert!(plain.contains("First item"), "Theme {mode:?} missing List");
            assert!(plain.contains("ID"), "Theme {mode:?} missing Table header");
        }
    }
