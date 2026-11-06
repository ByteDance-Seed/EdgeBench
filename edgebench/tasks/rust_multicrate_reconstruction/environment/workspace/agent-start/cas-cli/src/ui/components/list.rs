//! List component — bullet/numbered/custom marker lists with nesting

use std::io;

use super::formatter::Formatter;
use super::traits::Renderable;
use crate::ui::theme::Icons;

/// Bullet style for list items.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BulletStyle {
    /// Filled bullet: • (styled) or - (plain)
    Bullet,
    /// Dash: –
    Dash,
    /// Numbered: 1. 2. 3.
    Numbered,
    /// No marker (indentation only)
    None,
}

/// A single list item, possibly with children.
pub struct ListItem {
    text: String,
    children: Vec<ListItem>,
}

impl ListItem {
    /// Create a leaf item with no children.
    pub fn new(text: impl Into<String>) -> Self { todo!() }

    /// Create an item with nested children.
    pub fn with_children(text: impl Into<String>, children: Vec<ListItem>) -> Self { todo!() }

    /// Add a child item.
    pub fn add_child(mut self, child: ListItem) -> Self { todo!() }
}

/// A styled list supporting bullets, numbering, and nesting.
///
/// ```ignore
/// List::bullet(vec![
///     ListItem::new("First item"),
///     ListItem::with_children("Second item", vec![
///         ListItem::new("Nested A"),
///         ListItem::new("Nested B"),
///     ]),
///     ListItem::new("Third item"),
/// ]).render(&mut fmt)?;
///
/// // Output:
/// //  • First item
/// //  • Second item
/// //    • Nested A
/// //    • Nested B
/// //  • Third item
/// ```
pub struct List {
    items: Vec<ListItem>,
    style: BulletStyle,
}

impl List {
    /// Create a list with a specific bullet style.
    pub fn new(items: Vec<ListItem>, style: BulletStyle) -> Self { todo!() }

    /// Create a bullet list (•).
    pub fn bullet(items: Vec<ListItem>) -> Self { todo!() }

    /// Create a dash list (–).
    pub fn dash(items: Vec<ListItem>) -> Self { todo!() }

    /// Create a numbered list (1. 2. 3.).
    pub fn numbered(items: Vec<ListItem>) -> Self { todo!() }

    /// Render a list of items at the given indentation depth.
    fn render_items(
        items: &[ListItem],
        fmt: &mut Formatter,
        depth: usize,
        parent_style: BulletStyle,
    ) -> io::Result<()> { todo!() }
}

impl Renderable for List {
    fn render(&self, fmt: &mut Formatter) -> io::Result<()> { todo!() }
}

/// Format the marker for a list item based on style and position.
fn format_marker(style: BulletStyle, index: usize, styled: bool) -> String { todo!() }

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ui::theme::ActiveTheme;


    #[test]
    fn test_numbered_list_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            List::numbered(vec![
                ListItem::new("Alpha"),
                ListItem::new("Beta"),
                ListItem::new("Gamma"),
            ])
            .render(&mut fmt)
            .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "1. Alpha\n2. Beta\n3. Gamma\n");
    }

    #[test]
    fn test_dash_list_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            List::dash(vec![ListItem::new("Item A"), ListItem::new("Item B")])
                .render(&mut fmt)
                .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "- Item A\n- Item B\n");
    }


    #[test]
    fn test_three_level_nesting_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            List::bullet(vec![ListItem::with_children(
                "Level 0",
                vec![ListItem::with_children(
                    "Level 1",
                    vec![ListItem::new("Level 2")],
                )],
            )])
            .render(&mut fmt)
            .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines.len(), 3);
        assert_eq!(lines[0], "- Level 0");
        assert_eq!(lines[1], "  - Level 1");
        assert_eq!(lines[2], "    - Level 2");
    }

    #[test]
    fn test_nested_numbered_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            List::numbered(vec![
                ListItem::with_children(
                    "First",
                    vec![ListItem::new("Sub A"), ListItem::new("Sub B")],
                ),
                ListItem::new("Second"),
            ])
            .render(&mut fmt)
            .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines[0], "1. First");
        assert_eq!(lines[1], "  1. Sub A");
        assert_eq!(lines[2], "  2. Sub B");
        assert_eq!(lines[3], "2. Second");
    }

    #[test]
    fn test_empty_list() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            List::bullet(vec![]).render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.is_empty());
    }

    #[test]
    fn test_bullet_list_styled() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            List::bullet(vec![ListItem::new("Styled item")])
                .render(&mut fmt)
                .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Styled item"));
        assert!(output.contains("\x1b["));
    }


    #[test]
    fn test_none_style_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            List::new(
                vec![ListItem::new("No marker"), ListItem::new("Also none")],
                BulletStyle::None,
            )
            .render(&mut fmt)
            .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "  No marker\n  Also none\n");
    }

    #[test]
    fn test_add_child_builder() {
        let item = ListItem::new("Parent")
            .add_child(ListItem::new("Child 1"))
            .add_child(ListItem::new("Child 2"));

        assert_eq!(item.children.len(), 2);
        assert_eq!(item.children[0].text, "Child 1");
        assert_eq!(item.children[1].text, "Child 2");
    }

}
