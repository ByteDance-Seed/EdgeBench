//! Intra-line diff computation for highlighting changes within a line.

use similar::{ChangeTag, TextDiff};

use crate::LineDiffType;

/// A span of text within a line, indicating whether it should be highlighted
/// as a change.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct InlineSpan {
    /// The text content of this span.
    pub text: String,
    /// Whether this span represents changed text (should be highlighted).
    pub highlighted: bool,
}

/// Compute inline (intra-line) diffs between an old and new line.
///
/// Returns `(deletion_spans, addition_spans)` — the old line split into
/// spans showing what was removed, and the new line split into spans
/// showing what was added.
///
/// # Modes
/// - [`LineDiffType::None`]: Returns empty vectors (no inline diffing).
/// - [`LineDiffType::Char`]: Character-level granularity.
/// - [`LineDiffType::Word`]: Word-level granularity.
/// - [`LineDiffType::WordAlt`]: Word-level with span joining — single-character
///   neutral gaps between highlighted spans are merged into the highlighted span
///   to reduce visual noise.
pub fn compute_inline_diff(
    old_line: &str,
    new_line: &str,
    mode: LineDiffType,
) -> (Vec<InlineSpan>, Vec<InlineSpan>) { todo!() }

/// Port of `pushOrJoinSpan` from parseDiffDecorations.ts.
///
/// Consecutive same-type spans are always merged. Additionally, when
/// `enable_join` is true (WordAlt mode), a single-character neutral span
/// following a highlighted span is absorbed into the highlighted span,
/// preventing distracting single-space gaps in word diffs. This cross-type
/// join is skipped for the last item to avoid extending highlights to the
/// end of the line.
fn push_or_join_span(
    spans: &mut Vec<InlineSpan>,
    value: &str,
    highlighted: bool,
    enable_join: bool,
    is_last: bool,
) { todo!() }

#[cfg(test)]
mod tests {
    use super::*;

    fn span(text: &str, highlighted: bool) -> InlineSpan {
        InlineSpan {
            text: text.to_string(),
            highlighted,
        }
    }

    #[test]
    fn none_mode_returns_empty() {
        let (del, add) = compute_inline_diff("hello", "world", LineDiffType::None);
        assert!(del.is_empty());
        assert!(add.is_empty());
    }

    #[test]
    fn word_mode_highlights_insertion() {
        let (del, add) =
            compute_inline_diff("hello world", "hello brave world", LineDiffType::Word);
        // Deletion side: entire line is unchanged
        assert_eq!(del, vec![span("hello world", false)]);
        // Addition side: "brave " is the new part
        assert_eq!(
            add,
            vec![
                span("hello ", false),
                span("brave ", true),
                span("world", false),
            ]
        );
    }

    #[test]
    fn char_mode_highlights_individual_chars() {
        let (del, add) = compute_inline_diff("cat", "car", LineDiffType::Char);
        // Deletion: "ca" unchanged, "t" removed
        assert_eq!(del, vec![span("ca", false), span("t", true)]);
        // Addition: "ca" unchanged, "r" added
        assert_eq!(add, vec![span("ca", false), span("r", true)]);
    }

    #[test]
    fn char_vs_word_different_granularity() {
        let old = "foo bar";
        let new = "foo baz";

        let (del_char, add_char) = compute_inline_diff(old, new, LineDiffType::Char);
        let (del_word, add_word) = compute_inline_diff(old, new, LineDiffType::Word);

        // Char mode: "foo ba" equal, "r" vs "z" differ
        assert_eq!(del_char, vec![span("foo ba", false), span("r", true)]);
        assert_eq!(add_char, vec![span("foo ba", false), span("z", true)]);

        // Word mode: "foo " equal, "bar" vs "baz" differ (whole words)
        assert_eq!(del_word, vec![span("foo ", false), span("bar", true)]);
        assert_eq!(add_word, vec![span("foo ", false), span("baz", true)]);
    }


    #[test]
    fn word_alt_preserves_longer_neutral_gaps() {
        // Neutral gaps longer than 1 character should NOT be joined.
        // "abc  xyz" vs "ABC  XYZ" — double-space gap between changed words.
        let (del, _) = compute_inline_diff("abc  xyz", "ABC  XYZ", LineDiffType::WordAlt);
        // The "  " (2 chars) neutral gap should remain separate
        assert_eq!(
            del,
            vec![span("abc", true), span("  ", false), span("xyz", true)]
        );
    }

    #[test]
    fn strips_trailing_newline() {
        let (del, add) = compute_inline_diff("hello\n", "world\n", LineDiffType::Word);
        // Should diff "hello" vs "world", not include the newline
        assert_eq!(del, vec![span("hello", true)]);
        assert_eq!(add, vec![span("world", true)]);
    }

    #[test]
    fn identical_lines() {
        let (del, add) = compute_inline_diff("same text", "same text", LineDiffType::Word);
        assert_eq!(del, vec![span("same text", false)]);
        assert_eq!(add, vec![span("same text", false)]);
    }


    #[test]
    fn one_empty_one_not() {
        let (del, add) = compute_inline_diff("", "new text", LineDiffType::Word);
        assert!(del.is_empty());
        assert_eq!(add, vec![span("new text", true)]);
    }

    #[test]
    fn inline_span_serde_roundtrip() {
        let span = InlineSpan {
            text: "hello".into(),
            highlighted: true,
        };
        let json = serde_json::to_string(&span).unwrap();
        let back: InlineSpan = serde_json::from_str(&json).unwrap();
        assert_eq!(span, back);
    }
}
