//! Tests for markdown rendering

#[cfg(test)]
#[allow(clippy::module_inception)]
mod tests {
    use crate::ui::markdown::render_markdown;
    use crate::ui::theme::ActiveTheme;

    fn test_theme() -> ActiveTheme {
        ActiveTheme::default()
    }

    #[test]
    fn test_empty_content() {
        let theme = test_theme();
        let lines = render_markdown("", &theme);
        assert!(lines.is_empty());
    }

    #[test]
    fn test_plain_text() {
        let theme = test_theme();
        let lines = render_markdown("Hello world", &theme);
        assert!(!lines.is_empty());
    }

    #[test]
    fn test_headers() {
        let theme = test_theme();
        let content = "# Header 1\n## Header 2\n### Header 3";
        let lines = render_markdown(content, &theme);
        assert!(lines.len() >= 3);
    }

    #[test]
    fn test_bold_and_italic() {
        let theme = test_theme();
        let content = "This is **bold** and *italic* text";
        let lines = render_markdown(content, &theme);
        assert!(!lines.is_empty());
    }

    #[test]
    fn test_inline_code() {
        let theme = test_theme();
        let content = "Use the `render_markdown` function";
        let lines = render_markdown(content, &theme);
        assert!(!lines.is_empty());
    }



    #[test]
    fn test_ordered_list() {
        let theme = test_theme();
        let content = "1. First\n2. Second\n3. Third";
        let lines = render_markdown(content, &theme);
        assert!(lines.len() >= 3);
    }

    #[test]
    fn test_nested_list() {
        let theme = test_theme();
        let content = "- Item 1\n  - Nested 1\n  - Nested 2\n- Item 2";
        let lines = render_markdown(content, &theme);
        assert!(lines.len() >= 4);
    }

    #[test]
    fn test_blockquote() {
        let theme = test_theme();
        let content = "> This is a quote\n> Multiple lines";
        let lines = render_markdown(content, &theme);
        assert!(!lines.is_empty());
    }

    #[test]
    fn test_horizontal_rule() {
        let theme = test_theme();
        let content = "Before\n\n---\n\nAfter";
        let lines = render_markdown(content, &theme);
        assert!(lines.len() >= 3);
    }




}
