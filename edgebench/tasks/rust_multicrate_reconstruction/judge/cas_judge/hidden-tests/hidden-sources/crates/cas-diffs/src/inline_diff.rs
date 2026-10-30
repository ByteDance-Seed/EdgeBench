    #[test]
    fn word_alt_joins_single_char_gaps() {
        // When two highlighted regions are separated by a single space,
        // WordAlt merges them into one highlighted region.
        // Compare Word vs WordAlt on "x y" vs "a b":
        let (del_word, _) = compute_inline_diff("x y", "a b", LineDiffType::Word);
        let (del_alt, _) = compute_inline_diff("x y", "a b", LineDiffType::WordAlt);

        // Word mode keeps the space as a separate neutral span
        assert_eq!(
            del_word,
            vec![span("x", true), span(" ", false), span("y", true)]
        );
        // WordAlt joins the single-space gap into the highlighted span
        assert_eq!(del_alt, vec![span("x y", true)]);
    }

    #[test]
    fn empty_lines() {
        let (del, add) = compute_inline_diff("", "", LineDiffType::Char);
        assert!(del.is_empty());
        assert!(add.is_empty());
    }
