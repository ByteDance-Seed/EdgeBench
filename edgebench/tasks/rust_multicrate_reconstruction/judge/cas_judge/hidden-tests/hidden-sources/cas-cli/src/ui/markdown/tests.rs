    #[test]
    fn test_code_block() {
        let theme = test_theme();
        let content = "```rust\nfn main() {\n    println!(\"Hello\");\n}\n```";
        let lines = render_markdown(content, &theme);
        assert!(lines.len() >= 3); // At least borders + code lines
    }

    #[test]
    fn test_unordered_list() {
        let theme = test_theme();
        let content = "- Item 1\n- Item 2\n- Item 3";
        let lines = render_markdown(content, &theme);
        assert!(lines.len() >= 3);
    }

    #[test]
    fn test_link() {
        let theme = test_theme();
        let content = "Check out [this link](https://example.com)";
        let lines = render_markdown(content, &theme);
        assert!(!lines.is_empty());
    }

    #[test]
    fn test_table() {
        let theme = test_theme();
        let content = "| Header 1 | Header 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |";
        let lines = render_markdown(content, &theme);
        assert!(lines.len() >= 4); // borders + header + data row
    }

    #[test]
    fn test_task_list() {
        let theme = test_theme();
        let content = "- [ ] Unchecked\n- [x] Checked";
        let lines = render_markdown(content, &theme);
        assert!(lines.len() >= 2);
    }

    #[test]
    fn test_complex_document() {
        let theme = test_theme();
        let content = r#"
# Main Title

This is a **paragraph** with *emphasis*.

## Features

- Feature 1
- Feature 2
  - Sub-feature

```rust
fn example() {
    println!("code");
}
```

| Name | Value |
|------|-------|
| Foo  | Bar   |

> A blockquote

---

[Link](url)
"#;
        let lines = render_markdown(content, &theme);
        assert!(lines.len() > 10);
    }
