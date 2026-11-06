//! Grep search using ripgrep libraries
//!
//! Provides file content search using the same libraries that power ripgrep:
//! - grep-searcher for line-oriented search
//! - grep-regex for regex matching
//! - ignore for gitignore-aware file walking
//!
//! This module is fully generic with no CAS dependencies.

use std::path::{Path, PathBuf};

use grep_regex::RegexMatcherBuilder;
use grep_searcher::{
    BinaryDetection, Searcher, SearcherBuilder, Sink, SinkContext, SinkContextKind, SinkMatch,
};
use ignore::WalkBuilder;

use crate::error::{Result, SearchError};

/// A single grep match result
#[derive(Debug, Clone)]
pub struct GrepMatch {
    /// File path where match was found (relative to search root)
    pub file_path: String,
    /// Line number (1-indexed)
    pub line_number: u64,
    /// The matching line content
    pub line_content: String,
    /// Context lines before the match
    pub before_context: Vec<String>,
    /// Context lines after the match
    pub after_context: Vec<String>,
}

/// Options for grep search
#[derive(Debug, Clone)]
pub struct GrepOptions {
    /// Regex pattern to search for
    pub pattern: String,
    /// File glob pattern (e.g., "*.rs", "src/**/*.ts")
    pub glob: Option<String>,
    /// Lines of context before match
    pub before_context: usize,
    /// Lines of context after match
    pub after_context: usize,
    /// Case insensitive search
    pub case_insensitive: bool,
    /// Maximum results to return
    pub limit: usize,
}

impl Default for GrepOptions {
    fn default() -> Self { todo!() }
}

/// Custom sink that captures matches with context
struct ContextSink {
    file_path: String,
    matches: Vec<GrepMatch>,
    before_buffer: Vec<String>,
    current_match: Option<GrepMatch>,
    after_remaining: usize,
    after_context_count: usize,
    limit: usize,
}

impl ContextSink {
    fn new(file_path: String, before_context: usize, after_context: usize, limit: usize) -> Self { todo!() }

    fn finalize(mut self) -> Vec<GrepMatch> { todo!() }
}

impl Sink for ContextSink {
    type Error = std::io::Error;

    fn matched(
        &mut self,
        _searcher: &Searcher,
        mat: &SinkMatch<'_>,
    ) -> std::result::Result<bool, Self::Error> { todo!() }

    fn context(
        &mut self,
        _searcher: &Searcher,
        ctx: &SinkContext<'_>,
    ) -> std::result::Result<bool, Self::Error> { todo!() }
}

/// Grep search implementation using ripgrep libraries
pub struct GrepSearch {
    root: PathBuf,
}

impl GrepSearch {
    /// Create a new grep search rooted at the given path
    pub fn new(root: &Path) -> Self { todo!() }

    /// Get the search root path
    pub fn root(&self) -> &Path { todo!() }

    /// Search for matches in files under the root directory
    pub fn search(&self, opts: &GrepOptions) -> Result<Vec<GrepMatch>> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::grep::*;
    use std::fs;
    use tempfile::TempDir;


    #[test]
    fn test_grep_case_insensitive() {
        let dir = TempDir::new().unwrap();
        let file_path = dir.path().join("test.txt");
        fs::write(&file_path, "Hello World\nhello world\nHELLO WORLD\n").unwrap();

        let grep = GrepSearch::new(dir.path());
        let results = grep
            .search(&GrepOptions {
                pattern: "hello".to_string(),
                case_insensitive: true,
                ..Default::default()
            })
            .unwrap();

        assert_eq!(results.len(), 3);
    }

    #[test]
    fn test_grep_regex_pattern() {
        let dir = TempDir::new().unwrap();
        let file_path = dir.path().join("test.rs");
        fs::write(&file_path, "fn foo() {}\nfn bar() {}\nfn baz() {}\n").unwrap();

        let grep = GrepSearch::new(dir.path());
        let results = grep
            .search(&GrepOptions {
                pattern: r"fn\s+ba".to_string(),
                ..Default::default()
            })
            .unwrap();

        assert_eq!(results.len(), 2);
    }


    #[test]
    fn test_grep_path_glob() {
        let dir = TempDir::new().unwrap();

        let src_dir = dir.path().join("src");
        let lib_dir = dir.path().join("lib");
        fs::create_dir_all(&src_dir).unwrap();
        fs::create_dir_all(&lib_dir).unwrap();
        fs::write(src_dir.join("foo.rs"), "fn foo() {}\n").unwrap();
        fs::write(lib_dir.join("bar.rs"), "fn bar() {}\n").unwrap();

        let grep = GrepSearch::new(dir.path());

        let results = grep
            .search(&GrepOptions {
                pattern: "fn".to_string(),
                glob: Some("src/**/*.rs".to_string()),
                ..Default::default()
            })
            .unwrap();

        assert_eq!(results.len(), 1);
        assert!(results[0].file_path.contains("foo"));
    }

    #[test]
    fn test_grep_with_context() {
        let dir = TempDir::new().unwrap();
        let file_path = dir.path().join("test.rs");
        fs::write(&file_path, "line 1\nline 2\nMATCH\nline 4\nline 5\n").unwrap();

        let grep = GrepSearch::new(dir.path());
        let results = grep
            .search(&GrepOptions {
                pattern: "MATCH".to_string(),
                before_context: 2,
                after_context: 2,
                ..Default::default()
            })
            .unwrap();

        assert_eq!(results.len(), 1);
        assert_eq!(results[0].line_content, "MATCH");
        assert_eq!(results[0].before_context, vec!["line 1", "line 2"]);
        assert_eq!(results[0].after_context, vec!["line 4", "line 5"]);
    }

    #[test]
    fn test_grep_empty_pattern_error() {
        let dir = TempDir::new().unwrap();
        let grep = GrepSearch::new(dir.path());
        let result = grep.search(&GrepOptions::default());
        assert!(result.is_err());
    }

    #[test]
    fn test_grep_invalid_regex_error() {
        let dir = TempDir::new().unwrap();
        let grep = GrepSearch::new(dir.path());
        let result = grep.search(&GrepOptions {
            pattern: "[invalid".to_string(),
            ..Default::default()
        });
        assert!(result.is_err());
    }

}
