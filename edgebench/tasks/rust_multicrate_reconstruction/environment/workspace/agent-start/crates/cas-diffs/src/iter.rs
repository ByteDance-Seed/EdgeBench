//! Diff iteration with split/unified layout support.
//!
//! Ports the iteration logic from `@pierre/diffs` `iterateOverDiff.ts` to Rust.
//! Walks through hunks in a [`FileDiffMetadata`], emitting [`DiffLineEvent`]s
//! for each line. Supports unified, split, and dual-mode layout, windowed
//! rendering for virtual scrolling, collapsed context between hunks, and
//! hunk expansion regions.

use std::collections::HashMap;

use crate::{ChangeContent, FileDiffMetadata, Hunk, HunkContent};

/// Default number of collapsed context lines that auto-expand.
pub const DEFAULT_COLLAPSED_CONTEXT_THRESHOLD: usize = 1;

/// Layout mode for diff rendering.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DiffStyle {
    /// Side-by-side: deletions on the left, additions on the right.
    Split,
    /// Interleaved: deletions then additions in sequence.
    Unified,
    /// Track both unified and split counters simultaneously.
    Both,
}

/// Metadata for a single line in the diff output.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DiffLineMetadata {
    /// 1-based line number in the file.
    pub line_number: usize,
    /// Zero-based index into the addition_lines or deletion_lines array.
    pub line_index: usize,
    /// Line index in unified rendering.
    pub unified_line_index: usize,
    /// Line index in split rendering.
    pub split_line_index: usize,
    /// True if this line has no trailing newline at EOF.
    pub no_eof_cr: bool,
}

/// An event emitted during diff iteration, representing one rendered line.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum DiffLineEvent {
    /// An unchanged context line present in both old and new files.
    Context {
        hunk_index: usize,
        collapsed_before: usize,
        collapsed_after: usize,
        deletion_line: DiffLineMetadata,
        addition_line: DiffLineMetadata,
    },
    /// An expanded context line loaded from full file content.
    ContextExpanded {
        hunk_index: usize,
        collapsed_before: usize,
        collapsed_after: usize,
        deletion_line: DiffLineMetadata,
        addition_line: DiffLineMetadata,
    },
    /// A changed line — deletion, addition, or both paired in split mode.
    Change {
        hunk_index: usize,
        collapsed_before: usize,
        collapsed_after: usize,
        deletion_line: Option<DiffLineMetadata>,
        addition_line: Option<DiffLineMetadata>,
    },
}

/// A region of expanded context around a hunk separator.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct HunkExpansionRegion {
    /// Number of lines expanded from the start of the collapsed region.
    pub from_start: usize,
    /// Number of lines expanded from the end of the collapsed region.
    pub from_end: usize,
}

/// Configuration for diff iteration.
pub struct IterateOverDiffProps<'a> {
    /// The file diff to iterate over.
    pub diff: &'a FileDiffMetadata,
    /// Layout mode.
    pub diff_style: DiffStyle,
    /// First visible line index (for windowed rendering).
    pub starting_line: usize,
    /// Number of visible lines (for windowed rendering). Use `usize::MAX` for
    /// no limit.
    pub total_lines: usize,
    /// Expanded hunk regions keyed by hunk index. `None` means no expansion.
    pub expanded_hunks: Option<&'a HashMap<usize, HunkExpansionRegion>>,
    /// If true, expand all collapsed regions.
    pub expand_all: bool,
    /// Number of collapsed lines that auto-expand without a separator.
    pub collapsed_context_threshold: usize,
}

impl<'a> IterateOverDiffProps<'a> {
    /// Create props with default windowing (show everything).
    pub fn new(diff: &'a FileDiffMetadata, diff_style: DiffStyle) -> Self { todo!() }
}

// Internal state for the iteration.
struct IterationState {
    diff_style: DiffStyle,
    viewport_start: usize,
    viewport_end: usize, // saturating: start + total
    is_windowed: bool,
    split_count: usize,
    unified_count: usize,
}

impl IterationState {
    fn new(props: &IterateOverDiffProps<'_>) -> Self { todo!() }

    fn should_break(&self) -> bool { todo!() }

    fn should_skip(&self, unified_height: usize, split_height: usize) -> bool { todo!() }

    fn increment_counts(&mut self, unified_value: usize, split_value: usize) { todo!() }

    fn is_in_window(&self, unified_height: usize, split_height: usize) -> bool { todo!() }

    fn is_in_unified_window(&self, unified_height: usize) -> bool { todo!() }

    fn is_in_split_window(&self, split_height: usize) -> bool { todo!() }
}

/// Iterate over a file diff, calling `callback` for each line event.
///
/// Returns `true` if the callback requested an early stop (by returning `true`),
/// `false` if iteration completed normally.
///
/// The callback receives a [`DiffLineEvent`] and returns `true` to stop
/// iteration or `false` to continue.
pub fn iterate_over_diff<F>(props: &IterateOverDiffProps<'_>, mut callback: F) -> bool
where
    F: FnMut(DiffLineEvent) -> bool,
{ todo!() }

// --- Internal helpers ---

struct ExpandedRegionResult {
    from_start: usize,
    from_end: usize,
    range_size: usize,
    collapsed_lines: usize,
}

fn get_expanded_region(
    is_partial: bool,
    range_size_raw: usize,
    expanded_hunks: Option<&HashMap<usize, HunkExpansionRegion>>,
    expand_all: bool,
    hunk_index: usize,
    collapsed_context_threshold: usize,
) -> ExpandedRegionResult { todo!() }

fn has_final_collapsed_hunk(diff: &FileDiffMetadata) -> bool { todo!() }

/// Compute visible iteration ranges for a change block.
fn get_change_iteration_ranges(
    state: &IterationState,
    content: &ChangeContent,
    diff_style: DiffStyle,
) -> Vec<(usize, usize)> { todo!() }

#[allow(clippy::too_many_arguments)]
fn get_change_line_data<F>(
    hunk: &Hunk,
    hunk_index: usize,
    leading: &mut ExpandedRegionResult,
    trailing: &Option<ExpandedRegionResult>,
    diff_style: DiffStyle,
    index: usize,
    unified_line_index: usize,
    split_line_index: usize,
    addition_line_index: usize,
    deletion_line_index: usize,
    addition_line_number: usize,
    deletion_line_number: usize,
    content: &ChangeContent,
    is_last_content: bool,
    unified_count: usize,
    split_count: usize,
    get_trailing_collapsed_after: &F,
) -> DiffLineEvent
where
    F: Fn(&Option<ExpandedRegionResult>, usize, usize) -> usize,
{ todo!() }

#[cfg(test)]
mod tests {
    use super::*;
    use crate::*;

    /// Build a simple diff: 3 context, 2 deletions + 2 additions, 3 context.
    fn simple_diff() -> FileDiffMetadata {
        FileDiffMetadata {
            name: "test.rs".into(),
            prev_name: None,
            change_type: ChangeType::Change,
            hunks: vec![Hunk {
                collapsed_before: 0,
                addition_start: 1,
                addition_count: 8,
                addition_lines: 2,
                addition_line_index: 0,
                deletion_start: 1,
                deletion_count: 8,
                deletion_lines: 2,
                deletion_line_index: 0,
                hunk_content: vec![
                    HunkContent::Context(ContextContent {
                        lines: 3,
                        addition_line_index: 0,
                        deletion_line_index: 0,
                    }),
                    HunkContent::Change(ChangeContent {
                        deletions: 2,
                        deletion_line_index: 3,
                        additions: 2,
                        addition_line_index: 3,
                    }),
                    HunkContent::Context(ContextContent {
                        lines: 3,
                        addition_line_index: 5,
                        deletion_line_index: 5,
                    }),
                ],
                hunk_context: None,
                hunk_specs: Some("@@ -1,8 +1,8 @@".into()),
                split_line_start: 0,
                split_line_count: 8,
                unified_line_start: 0,
                unified_line_count: 10,
                no_eof_cr_deletions: false,
                no_eof_cr_additions: false,
            }],
            split_line_count: 8,
            unified_line_count: 10,
            is_partial: true,
            deletion_lines: vec![
                "a".into(),
                "b".into(),
                "c".into(),
                "old1".into(),
                "old2".into(),
                "d".into(),
                "e".into(),
                "f".into(),
            ],
            addition_lines: vec![
                "a".into(),
                "b".into(),
                "c".into(),
                "new1".into(),
                "new2".into(),
                "d".into(),
                "e".into(),
                "f".into(),
            ],
        }
    }


    #[test]
    fn split_iteration_pairs_deletions_and_additions() {
        let diff = simple_diff();
        let props = IterateOverDiffProps::new(&diff, DiffStyle::Split);
        let mut events = Vec::new();
        iterate_over_diff(&props, |e| {
            events.push(e);
            false
        });

        // 3 context + 2 paired changes + 3 context = 8 events
        assert_eq!(events.len(), 8, "split should emit 8 events");

        // Change events should have both deletion and addition
        if let DiffLineEvent::Change {
            deletion_line,
            addition_line,
            ..
        } = &events[3]
        {
            assert!(deletion_line.is_some(), "split change should pair deletion");
            assert!(addition_line.is_some(), "split change should pair addition");
        }
    }

    #[test]
    fn windowed_iteration_skips_and_breaks() {
        let diff = simple_diff();
        let mut props = IterateOverDiffProps::new(&diff, DiffStyle::Unified);
        props.starting_line = 2;
        props.total_lines = 4;

        let mut events = Vec::new();
        iterate_over_diff(&props, |e| {
            events.push(e);
            false
        });

        // Window starts at line 2 (3rd line), shows 4 lines
        // Should get: context[2], change-del[0], change-del[1], change-add[0]
        assert_eq!(events.len(), 4, "windowed should emit exactly 4 events");

        // First event should be context (the 3rd context line)
        assert!(matches!(&events[0], DiffLineEvent::Context { .. }));
    }

    #[test]
    fn collapsed_context_between_hunks() {
        let diff = FileDiffMetadata {
            name: "test.rs".into(),
            prev_name: None,
            change_type: ChangeType::Change,
            hunks: vec![
                Hunk {
                    collapsed_before: 0,
                    addition_start: 1,
                    addition_count: 2,
                    addition_lines: 1,
                    addition_line_index: 0,
                    deletion_start: 1,
                    deletion_count: 2,
                    deletion_lines: 1,
                    deletion_line_index: 0,
                    hunk_content: vec![
                        HunkContent::Context(ContextContent {
                            lines: 1,
                            addition_line_index: 0,
                            deletion_line_index: 0,
                        }),
                        HunkContent::Change(ChangeContent {
                            deletions: 1,
                            deletion_line_index: 1,
                            additions: 1,
                            addition_line_index: 1,
                        }),
                    ],
                    hunk_context: None,
                    hunk_specs: None,
                    split_line_start: 0,
                    split_line_count: 2,
                    unified_line_start: 0,
                    unified_line_count: 3,
                    no_eof_cr_deletions: false,
                    no_eof_cr_additions: false,
                },
                Hunk {
                    collapsed_before: 10,
                    addition_start: 15,
                    addition_count: 2,
                    addition_lines: 1,
                    addition_line_index: 5,
                    deletion_start: 15,
                    deletion_count: 2,
                    deletion_lines: 1,
                    deletion_line_index: 5,
                    hunk_content: vec![
                        HunkContent::Context(ContextContent {
                            lines: 1,
                            addition_line_index: 5,
                            deletion_line_index: 5,
                        }),
                        HunkContent::Change(ChangeContent {
                            deletions: 1,
                            deletion_line_index: 6,
                            additions: 1,
                            addition_line_index: 6,
                        }),
                    ],
                    hunk_context: None,
                    hunk_specs: None,
                    split_line_start: 2,
                    split_line_count: 2,
                    unified_line_start: 3,
                    unified_line_count: 3,
                    no_eof_cr_deletions: false,
                    no_eof_cr_additions: false,
                },
            ],
            split_line_count: 4,
            unified_line_count: 6,
            is_partial: true,
            deletion_lines: (0..8).map(|i| format!("del{i}")).collect(),
            addition_lines: (0..8).map(|i| format!("add{i}")).collect(),
        };

        let props = IterateOverDiffProps::new(&diff, DiffStyle::Unified);
        let mut collapsed_values = Vec::new();
        iterate_over_diff(&props, |e| {
            let cb = match &e {
                DiffLineEvent::Context {
                    collapsed_before, ..
                } => *collapsed_before,
                DiffLineEvent::Change {
                    collapsed_before, ..
                } => *collapsed_before,
                DiffLineEvent::ContextExpanded {
                    collapsed_before, ..
                } => *collapsed_before,
            };
            if cb > 0 {
                collapsed_values.push(cb);
            }
            false
        });

        // Second hunk has collapsed_before=10, is_partial=true so no expansion
        // → collapsed_before should appear once with value 10
        assert_eq!(collapsed_values, vec![10]);
    }

    #[test]
    fn line_numbers_correct_in_unified() {
        let diff = simple_diff();
        let props = IterateOverDiffProps::new(&diff, DiffStyle::Unified);
        let mut line_numbers = Vec::new();
        iterate_over_diff(&props, |e| {
            match &e {
                DiffLineEvent::Context {
                    deletion_line,
                    addition_line,
                    ..
                } => {
                    line_numbers.push(('C', deletion_line.line_number, addition_line.line_number));
                }
                DiffLineEvent::Change {
                    deletion_line,
                    addition_line,
                    ..
                } => {
                    let del = deletion_line.map(|d| d.line_number).unwrap_or(0);
                    let add = addition_line.map(|a| a.line_number).unwrap_or(0);
                    line_numbers.push(('X', del, add));
                }
                _ => {}
            }
            false
        });

        // Context lines 1,2,3 (both sides same)
        assert_eq!(line_numbers[0], ('C', 1, 1));
        assert_eq!(line_numbers[1], ('C', 2, 2));
        assert_eq!(line_numbers[2], ('C', 3, 3));

        // Change: deletions first (lines 4, 5), then additions (lines 4, 5)
        assert_eq!(line_numbers[3], ('X', 4, 0)); // deletion line 4
        assert_eq!(line_numbers[4], ('X', 5, 0)); // deletion line 5
        assert_eq!(line_numbers[5], ('X', 0, 4)); // addition line 4
        assert_eq!(line_numbers[6], ('X', 0, 5)); // addition line 5

        // Context lines 6,7,8
        assert_eq!(line_numbers[7], ('C', 6, 6));
        assert_eq!(line_numbers[8], ('C', 7, 7));
        assert_eq!(line_numbers[9], ('C', 8, 8));
    }

    #[test]
    fn split_unmatched_change_lines() {
        // 3 deletions, 1 addition → split has 3 rows, last 2 deletion-only
        let diff = FileDiffMetadata {
            name: "test.rs".into(),
            prev_name: None,
            change_type: ChangeType::Change,
            hunks: vec![Hunk {
                collapsed_before: 0,
                addition_start: 1,
                addition_count: 1,
                addition_lines: 1,
                addition_line_index: 0,
                deletion_start: 1,
                deletion_count: 3,
                deletion_lines: 3,
                deletion_line_index: 0,
                hunk_content: vec![HunkContent::Change(ChangeContent {
                    deletions: 3,
                    deletion_line_index: 0,
                    additions: 1,
                    addition_line_index: 0,
                })],
                hunk_context: None,
                hunk_specs: None,
                split_line_start: 0,
                split_line_count: 3,
                unified_line_start: 0,
                unified_line_count: 4,
                no_eof_cr_deletions: false,
                no_eof_cr_additions: false,
            }],
            split_line_count: 3,
            unified_line_count: 4,
            is_partial: true,
            deletion_lines: vec!["a".into(), "b".into(), "c".into()],
            addition_lines: vec!["x".into()],
        };

        let props = IterateOverDiffProps::new(&diff, DiffStyle::Split);
        let mut events = Vec::new();
        iterate_over_diff(&props, |e| {
            events.push(e);
            false
        });

        assert_eq!(events.len(), 3, "split: max(3 del, 1 add) = 3 rows");

        // First row: paired (del + add)
        if let DiffLineEvent::Change {
            deletion_line,
            addition_line,
            ..
        } = &events[0]
        {
            assert!(deletion_line.is_some());
            assert!(addition_line.is_some());
        }

        // Rows 2 and 3: deletion only
        for i in 1..3 {
            if let DiffLineEvent::Change {
                deletion_line,
                addition_line,
                ..
            } = &events[i]
            {
                assert!(deletion_line.is_some(), "row {i} should have deletion");
                assert!(addition_line.is_none(), "row {i} should not have addition");
            }
        }
    }

    #[test]
    fn callback_early_stop() {
        let diff = simple_diff();
        let props = IterateOverDiffProps::new(&diff, DiffStyle::Unified);
        let mut count = 0;
        let stopped = iterate_over_diff(&props, |_| {
            count += 1;
            count >= 3 // stop after 3 events
        });
        assert!(stopped, "should report early stop");
        assert_eq!(count, 3, "should have emitted exactly 3 events");
    }

    #[test]
    fn empty_diff_produces_no_events() {
        let diff = FileDiffMetadata {
            name: "empty.rs".into(),
            prev_name: None,
            change_type: ChangeType::Change,
            hunks: vec![],
            split_line_count: 0,
            unified_line_count: 0,
            is_partial: true,
            deletion_lines: vec![],
            addition_lines: vec![],
        };
        let props = IterateOverDiffProps::new(&diff, DiffStyle::Unified);
        let mut count = 0;
        iterate_over_diff(&props, |_| {
            count += 1;
            false
        });
        assert_eq!(count, 0);
    }

    #[test]
    fn expanded_region_auto_expands_small_threshold() {
        let result = get_expanded_region(false, 1, None, false, 0, 1);
        assert_eq!(result.from_start, 1);
        assert_eq!(result.collapsed_lines, 0);
    }

    #[test]
    fn expanded_region_partial_stays_collapsed() {
        let result = get_expanded_region(true, 10, None, false, 0, 1);
        assert_eq!(result.from_start, 0);
        assert_eq!(result.from_end, 0);
        assert_eq!(result.collapsed_lines, 10);
    }

}
