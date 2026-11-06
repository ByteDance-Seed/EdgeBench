    #[test]
    fn test_assert_row_contains() {
        let screen = screen("line one\nline two\nline three");

        assert!(screen.assert_row_contains(0, "one").is_ok());
        assert!(screen.assert_row_contains(1, "two").is_ok());
        assert!(screen.assert_row_contains(0, "two").is_err());
        assert!(screen.assert_row_contains(10, "any").is_err());
    }

    #[test]
    fn test_assert_text_at() {
        let screen = screen("0123456789\nabcdefghij");

        assert!(screen.assert_text_at(0, 0, "0123").is_ok());
        assert!(screen.assert_text_at(0, 5, "5678").is_ok());
        assert!(screen.assert_text_at(1, 0, "abcd").is_ok());
        assert!(screen.assert_text_at(0, 0, "xxxx").is_err());
    }

    #[test]
    fn test_assert_region() {
        let screen = screen("ABCDE\nFGHIJ\nKLMNO");

        assert!(screen.assert_region(0, 0, 3, 2, &["ABC", "FGH"]).is_ok());
        assert!(screen.assert_region(1, 1, 3, 2, &["GHI", "LMN"]).is_ok());
        assert!(screen.assert_region(0, 0, 3, 2, &["XXX", "XXX"]).is_err());
    }
