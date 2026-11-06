//! Tree component — hierarchical display with tree-line connectors
//!
//! Renders nested data with standard tree-line characters (├── └── │)
//! for visualizing dependency trees, file trees, and task hierarchies.
//!
//! ```ignore
//! Tree::new("cas-cli")
//!     .child(Tree::new("src")
//!         .child(Tree::leaf("main.rs"))
//!         .child(Tree::leaf("lib.rs")))
//!     .child(Tree::leaf("Cargo.toml"))
//!     .render(&mut fmt)?;
//!
//! // Output:
//! // cas-cli
//! // ├── src
//! // │   ├── main.rs
//! // │   └── lib.rs
//! // └── Cargo.toml
//! ```

use std::io;

use ratatui::style::Color as RatatuiColor;

use super::formatter::Formatter;
use super::traits::Renderable;

/// A tree node with a label and optional children.
pub struct Tree {
    label: String,
    children: Vec<Tree>,
    color: Option<RatatuiColor>,
}

impl Tree {
    /// Create a tree node with the given label.
    pub fn new(label: impl Into<String>) -> Self { todo!() }

    /// Create a leaf node (no children).
    pub fn leaf(label: impl Into<String>) -> Self { todo!() }

    /// Add a child subtree.
    pub fn child(mut self, child: Tree) -> Self { todo!() }

    /// Add multiple children at once.
    pub fn children(mut self, children: Vec<Tree>) -> Self { todo!() }

    /// Set a custom color for this node's label.
    pub fn with_color(mut self, color: RatatuiColor) -> Self { todo!() }

    /// Render a tree node and its children recursively.
    ///
    /// `prefix` is the accumulated prefix for the current depth (e.g., "│   ").
    /// `is_last` indicates if this node is the last sibling.
    /// `is_root` indicates if this is the root node (no connector).
    fn render_node(
        &self,
        fmt: &mut Formatter,
        prefix: &str,
        is_last: bool,
        is_root: bool,
    ) -> io::Result<()> { todo!() }

    /// Write just the label text with optional color.
    fn write_label(&self, fmt: &mut Formatter) -> io::Result<()> { todo!() }
}

impl Renderable for Tree {
    fn render(&self, fmt: &mut Formatter) -> io::Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ui::theme::ActiveTheme;

    fn render_plain(tree: &Tree) -> String {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            tree.render(&mut fmt).unwrap();
        }
        String::from_utf8(buf).unwrap()
    }

    #[test]
    fn test_single_node() {
        let tree = Tree::new("root");
        let output = render_plain(&tree);
        assert_eq!(output, "root\n");
    }

    #[test]
    fn test_one_child() {
        let tree = Tree::new("parent").child(Tree::leaf("child"));
        let output = render_plain(&tree);
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines[0], "parent");
        assert_eq!(lines[1], "`-- child");
    }

    #[test]
    fn test_two_children() {
        let tree = Tree::new("root")
            .child(Tree::leaf("first"))
            .child(Tree::leaf("second"));

        let output = render_plain(&tree);
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines[0], "root");
        assert_eq!(lines[1], "|-- first");
        assert_eq!(lines[2], "`-- second");
    }

    #[test]
    fn test_three_children() {
        let tree = Tree::new("root")
            .child(Tree::leaf("a"))
            .child(Tree::leaf("b"))
            .child(Tree::leaf("c"));

        let output = render_plain(&tree);
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines[0], "root");
        assert_eq!(lines[1], "|-- a");
        assert_eq!(lines[2], "|-- b");
        assert_eq!(lines[3], "`-- c");
    }


    #[test]
    fn test_deep_nesting() {
        let tree =
            Tree::new("L0").child(Tree::new("L1").child(Tree::new("L2").child(Tree::leaf("L3"))));

        let output = render_plain(&tree);
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines[0], "L0");
        assert_eq!(lines[1], "`-- L1");
        assert_eq!(lines[2], "    `-- L2");
        assert_eq!(lines[3], "        `-- L3");
    }

    #[test]
    fn test_mixed_depth() {
        let tree = Tree::new("root")
            .child(Tree::new("branch").child(Tree::leaf("deep leaf")))
            .child(Tree::leaf("shallow leaf"));

        let output = render_plain(&tree);
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines[0], "root");
        assert_eq!(lines[1], "|-- branch");
        assert_eq!(lines[2], "|   `-- deep leaf");
        assert_eq!(lines[3], "`-- shallow leaf");
    }


    #[test]
    fn test_styled_deep_tree() {
        let theme = ActiveTheme::default_dark();
        // Need multiple children so the first uses ├── and generates │ continuation
        let tree = Tree::new("top")
            .child(Tree::new("mid").child(Tree::leaf("bottom")))
            .child(Tree::leaf("sibling"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            tree.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("\u{2502}")); // │ continuation line
    }

    #[test]
    fn test_children_builder() {
        let tree =
            Tree::new("root").children(vec![Tree::leaf("a"), Tree::leaf("b"), Tree::leaf("c")]);
        assert_eq!(tree.children.len(), 3);
    }

    #[test]
    fn test_no_children() {
        let tree = Tree::leaf("lonely");
        let output = render_plain(&tree);
        assert_eq!(output, "lonely\n");
    }

    #[test]
    fn test_with_color() {
        let theme = ActiveTheme::default_dark();
        let tree = Tree::new("root")
            .child(Tree::leaf("green").with_color(RatatuiColor::Green))
            .child(Tree::leaf("red").with_color(RatatuiColor::Red));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            tree.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("green"));
        assert!(output.contains("red"));
        assert!(output.contains("\x1b["));
    }

    #[test]
    fn test_connector_alignment() {
        // Verify that continuation lines (│) align properly when first child
        // has children but second doesn't
        let tree = Tree::new("root")
            .child(
                Tree::new("first")
                    .child(Tree::leaf("child-a"))
                    .child(Tree::leaf("child-b")),
            )
            .child(Tree::leaf("second"));

        let output = render_plain(&tree);
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines[0], "root");
        assert_eq!(lines[1], "|-- first");
        assert_eq!(lines[2], "|   |-- child-a");
        assert_eq!(lines[3], "|   `-- child-b");
        assert_eq!(lines[4], "`-- second");
    }
}
