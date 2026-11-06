//! Diff parsing, rendering, and syntax highlighting for CAS.
//!
//! This crate provides core data types and a parser for representing
//! unified diffs, ported from the `@pierre/diffs` TypeScript library.
//! Types model parsed patch files at the file, hunk, and line level.

pub mod highlight;
pub mod iter;
pub mod parser;

pub mod diff_files;
pub mod inline_diff;
pub mod widget;

pub use diff_files::diff_files;
pub use inline_diff::{InlineSpan, compute_inline_diff};

use serde::{Deserialize, Serialize};

/// Describes the type of change for a file in a diff.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ChangeType {
    /// File content was modified, name unchanged.
    Change,
    /// File was renamed/moved without content changes (100% similarity).
    RenamePure,
    /// File was renamed/moved and content was also modified.
    RenameChanged,
    /// A new file was added.
    New,
    /// An existing file was removed.
    Deleted,
}

/// Line types parsed from a patch file.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum HunkLineType {
    /// Unchanged context line (prefixed with space).
    Context,
    /// Expanded context line (loaded on demand).
    Expanded,
    /// Added line (prefixed with `+`).
    Addition,
    /// Removed line (prefixed with `-`).
    Deletion,
    /// Metadata line (e.g. `\ No newline at end of file`).
    Metadata,
}

/// Intra-line diff algorithm to use for highlighting changes within a line.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum LineDiffType {
    /// Word-level diff that joins regions separated by a single character.
    WordAlt,
    /// Standard word-level diff.
    Word,
    /// Character-level diff.
    Char,
    /// No intra-line diffing.
    None,
}

/// A block of unchanged context lines within a hunk.
///
/// Consecutive lines prefixed with a space are grouped into a single
/// `ContextContent`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ContextContent {
    /// Number of unchanged lines in this context block.
    pub lines: usize,
    /// Zero-based index into `FileDiffMetadata::addition_lines` where this
    /// context block starts.
    pub addition_line_index: usize,
    /// Zero-based index into `FileDiffMetadata::deletion_lines` where this
    /// context block starts.
    pub deletion_line_index: usize,
}

/// A block of changes (additions and/or deletions) within a hunk.
///
/// Consecutive `+` and `-` lines are grouped into a single `ChangeContent`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ChangeContent {
    /// Number of deleted lines (prefixed with `-`) in this change block.
    pub deletions: usize,
    /// Zero-based index into `FileDiffMetadata::deletion_lines` where the
    /// deleted lines start.
    pub deletion_line_index: usize,
    /// Number of added lines (prefixed with `+`) in this change block.
    pub additions: usize,
    /// Zero-based index into `FileDiffMetadata::addition_lines` where the
    /// added lines start.
    pub addition_line_index: usize,
}

/// A content segment within a hunk — either context or changes.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "lowercase")]
pub enum HunkContent {
    /// Unchanged context lines.
    Context(ContextContent),
    /// Changed lines (additions and/or deletions).
    Change(ChangeContent),
}

/// A single hunk from a diff, corresponding to one `@@ ... @@` block.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Hunk {
    /// Number of unchanged lines between the previous hunk (or file start)
    /// and this hunk.
    pub collapsed_before: usize,

    /// Starting line number in the new file version (from `+X` in hunk header).
    pub addition_start: usize,
    /// Total line count in the new file version for this hunk (from `+X,count`).
    /// Includes both context lines and lines prefixed with `+`.
    pub addition_count: usize,
    /// Number of lines prefixed with `+` in this hunk.
    pub addition_lines: usize,
    /// Zero-based index into `FileDiffMetadata::addition_lines` where this
    /// hunk's content starts.
    pub addition_line_index: usize,

    /// Starting line number in the old file version (from `-X` in hunk header).
    pub deletion_start: usize,
    /// Total line count in the old file version for this hunk (from `-X,count`).
    /// Includes both context lines and lines prefixed with `-`.
    pub deletion_count: usize,
    /// Number of lines prefixed with `-` in this hunk.
    pub deletion_lines: usize,
    /// Zero-based index into `FileDiffMetadata::deletion_lines` where this
    /// hunk's content starts.
    pub deletion_line_index: usize,

    /// Content segments within this hunk (context and change blocks).
    pub hunk_content: Vec<HunkContent>,
    /// Function/method name after the `@@` markers, if present.
    pub hunk_context: Option<String>,
    /// Raw hunk header string (e.g. `@@ -1,5 +1,7 @@`).
    pub hunk_specs: Option<String>,

    /// Starting line index for this hunk in split (side-by-side) view.
    pub split_line_start: usize,
    /// Total rendered line count for this hunk in split view.
    pub split_line_count: usize,

    /// Starting line index for this hunk in unified view.
    pub unified_line_start: usize,
    /// Total rendered line count for this hunk in unified view.
    pub unified_line_count: usize,

    /// True if the old file version has no trailing newline at EOF.
    pub no_eof_cr_deletions: bool,
    /// True if the new file version has no trailing newline at EOF.
    pub no_eof_cr_additions: bool,
}

/// Metadata and content for a single file's diff.
///
/// A JSON-compatible representation of a diff for a single file, including
/// all hunks, line arrays, and rendering metadata.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FileDiffMetadata {
    /// The file's name and path.
    pub name: String,
    /// Previous file path, present only if file was renamed or moved.
    pub prev_name: Option<String>,

    /// The type of change for this file.
    pub change_type: ChangeType,

    /// Diff hunks containing line-level change information. Each hunk
    /// corresponds to a `@@ -X,X +X,X @@` group in a diff.
    pub hunks: Vec<Hunk>,
    /// Pre-computed line count for this diff rendered in split style.
    pub split_line_count: usize,
    /// Pre-computed line count for this diff rendered in unified style.
    pub unified_line_count: usize,

    /// Whether the diff was parsed from a patch file (`true`) or generated
    /// from full file contents (`false`).
    ///
    /// When `true`, `deletion_lines`/`addition_lines` contain only the lines
    /// present in the patch and hunk expansion is unavailable.
    pub is_partial: bool,

    /// Lines from the previous version of the file. If `is_partial` is
    /// `false`, this is the entire old file. Otherwise, only lines from
    /// context and deletion regions of the patch.
    pub deletion_lines: Vec<String>,
    /// Lines from the new version of the file. If `is_partial` is `false`,
    /// this is the entire new file. Otherwise, only lines from context and
    /// addition regions of the patch.
    pub addition_lines: Vec<String>,
}

/// A parsed patch file, typically corresponding to a single commit.
///
/// Returned when parsing raw patch/diff strings.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ParsedPatch {
    /// Optional raw introductory text before the file diffs (e.g. commit
    /// message, author, date).
    pub patch_metadata: Option<String>,
    /// File changes contained in the patch.
    pub files: Vec<FileDiffMetadata>,
}

#[cfg(test)]
mod tests {
    use super::*;



    #[test]
    fn line_diff_type_serde() {
        assert_eq!(
            serde_json::to_string(&LineDiffType::WordAlt).unwrap(),
            "\"word-alt\""
        );
        assert_eq!(
            serde_json::to_string(&LineDiffType::None).unwrap(),
            "\"none\""
        );
    }

    #[test]
    fn context_content_construction() {
        let ctx = ContextContent {
            lines: 3,
            addition_line_index: 0,
            deletion_line_index: 0,
        };
        assert_eq!(ctx.lines, 3);
    }

    #[test]
    fn change_content_construction() {
        let change = ChangeContent {
            deletions: 2,
            deletion_line_index: 5,
            additions: 3,
            addition_line_index: 5,
        };
        assert_eq!(change.deletions, 2);
        assert_eq!(change.additions, 3);
    }

    #[test]
    fn hunk_content_tagged_serde() {
        let ctx = HunkContent::Context(ContextContent {
            lines: 1,
            addition_line_index: 0,
            deletion_line_index: 0,
        });
        let json = serde_json::to_string(&ctx).unwrap();
        assert!(json.contains("\"type\":\"context\""));

        let change = HunkContent::Change(ChangeContent {
            deletions: 1,
            deletion_line_index: 0,
            additions: 1,
            addition_line_index: 0,
        });
        let json = serde_json::to_string(&change).unwrap();
        assert!(json.contains("\"type\":\"change\""));
    }

    #[test]
    fn hunk_construction() {
        let hunk = Hunk {
            collapsed_before: 5,
            addition_start: 1,
            addition_count: 7,
            addition_lines: 2,
            addition_line_index: 0,
            deletion_start: 1,
            deletion_count: 5,
            deletion_lines: 0,
            deletion_line_index: 0,
            hunk_content: vec![
                HunkContent::Context(ContextContent {
                    lines: 3,
                    addition_line_index: 0,
                    deletion_line_index: 0,
                }),
                HunkContent::Change(ChangeContent {
                    deletions: 0,
                    deletion_line_index: 3,
                    additions: 2,
                    addition_line_index: 3,
                }),
                HunkContent::Context(ContextContent {
                    lines: 2,
                    addition_line_index: 5,
                    deletion_line_index: 3,
                }),
            ],
            hunk_context: Some("fn main()".into()),
            hunk_specs: Some("@@ -1,5 +1,7 @@".into()),
            split_line_start: 0,
            split_line_count: 7,
            unified_line_start: 0,
            unified_line_count: 7,
            no_eof_cr_deletions: false,
            no_eof_cr_additions: false,
        };
        assert_eq!(hunk.addition_count, 7);
        assert_eq!(hunk.hunk_content.len(), 3);
    }

    #[test]
    fn file_diff_metadata_construction() {
        let file = FileDiffMetadata {
            name: "src/main.rs".into(),
            prev_name: None,
            change_type: ChangeType::Change,
            hunks: vec![],
            split_line_count: 10,
            unified_line_count: 10,
            is_partial: true,
            deletion_lines: vec!["old line".into()],
            addition_lines: vec!["new line".into()],
        };
        assert_eq!(file.name, "src/main.rs");
        assert!(file.prev_name.is_none());
        assert_eq!(file.change_type, ChangeType::Change);
    }

    #[test]
    fn file_diff_metadata_rename() {
        let file = FileDiffMetadata {
            name: "src/new_name.rs".into(),
            prev_name: Some("src/old_name.rs".into()),
            change_type: ChangeType::RenameChanged,
            hunks: vec![],
            split_line_count: 0,
            unified_line_count: 0,
            is_partial: false,
            deletion_lines: vec![],
            addition_lines: vec![],
        };
        assert_eq!(file.prev_name.as_deref(), Some("src/old_name.rs"));
        assert_eq!(file.change_type, ChangeType::RenameChanged);
    }


    #[test]
    fn parsed_patch_serde_roundtrip() {
        let patch = ParsedPatch {
            patch_metadata: None,
            files: vec![FileDiffMetadata {
                name: "test.rs".into(),
                prev_name: None,
                change_type: ChangeType::New,
                hunks: vec![Hunk {
                    collapsed_before: 0,
                    addition_start: 1,
                    addition_count: 3,
                    addition_lines: 3,
                    addition_line_index: 0,
                    deletion_start: 0,
                    deletion_count: 0,
                    deletion_lines: 0,
                    deletion_line_index: 0,
                    hunk_content: vec![HunkContent::Change(ChangeContent {
                        deletions: 0,
                        deletion_line_index: 0,
                        additions: 3,
                        addition_line_index: 0,
                    })],
                    hunk_context: None,
                    hunk_specs: Some("@@ -0,0 +1,3 @@".into()),
                    split_line_start: 0,
                    split_line_count: 3,
                    unified_line_start: 0,
                    unified_line_count: 3,
                    no_eof_cr_deletions: false,
                    no_eof_cr_additions: false,
                }],
                split_line_count: 3,
                unified_line_count: 3,
                is_partial: false,
                deletion_lines: vec![],
                addition_lines: vec![
                    "fn main() {".into(),
                    "    println!(\"hello\");".into(),
                    "}".into(),
                ],
            }],
        };

        let json = serde_json::to_string_pretty(&patch).unwrap();
        let back: ParsedPatch = serde_json::from_str(&json).unwrap();
        assert_eq!(patch, back);
    }
}
