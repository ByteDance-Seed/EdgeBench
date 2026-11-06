//! Sort options for CAS queries
//!
//! Provides unified sorting for entries, tasks, and search results.

use std::str::FromStr;

/// Sort order direction
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum SortOrder {
    /// Ascending order (oldest first, lowest first)
    Asc,
    /// Descending order (newest first, highest first)
    #[default]
    Desc,
}

impl FromStr for SortOrder {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

impl std::fmt::Display for SortOrder {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { todo!() }
}

/// Sort field for entries (memories)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum EntrySortField {
    /// Sort by creation date
    #[default]
    Created,
    /// Sort by last update date
    Updated,
    /// Sort by importance score
    Importance,
    /// Sort by title (alphabetically)
    Title,
}

impl FromStr for EntrySortField {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

impl EntrySortField {
    /// Get the SQL column name for this field
    pub fn sql_column(&self) -> &'static str { todo!() }
}

/// Sort field for tasks
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum TaskSortField {
    /// Sort by creation date
    #[default]
    Created,
    /// Sort by last update date
    Updated,
    /// Sort by priority (0=highest priority)
    Priority,
    /// Sort by title (alphabetically)
    Title,
}

impl FromStr for TaskSortField {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

impl TaskSortField {
    /// Get the SQL column name for this field
    pub fn sql_column(&self) -> &'static str { todo!() }

    /// Get the default sort order for this field
    /// (priority sorts ascending by default, dates sort descending)
    pub fn default_order(&self) -> SortOrder { todo!() }
}

/// Sort field for search results
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum SearchSortField {
    /// Sort by relevance score (default for search)
    #[default]
    Relevance,
    /// Sort by creation date
    Created,
    /// Sort by last update date
    Updated,
}

impl FromStr for SearchSortField {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Sort options for entry queries
#[derive(Debug, Clone, Default)]
pub struct EntrySortOptions {
    pub field: EntrySortField,
    pub order: SortOrder,
}

impl EntrySortOptions {
    pub fn new(field: EntrySortField, order: SortOrder) -> Self { todo!() }

    /// Create from optional string parameters
    pub fn from_params(sort: Option<&str>, order: Option<&str>) -> Self { todo!() }

    /// Get the SQL ORDER BY clause
    pub fn sql_order_by(&self) -> String { todo!() }
}

/// Sort options for task queries
#[derive(Debug, Clone, Default)]
pub struct TaskSortOptions {
    pub field: TaskSortField,
    pub order: Option<SortOrder>, // None = use field's default
}

impl TaskSortOptions {
    pub fn new(field: TaskSortField, order: Option<SortOrder>) -> Self { todo!() }

    /// Create from optional string parameters
    pub fn from_params(sort: Option<&str>, order: Option<&str>) -> Self { todo!() }

    /// Get the effective sort order (using field default if not specified)
    pub fn effective_order(&self) -> SortOrder { todo!() }

    /// Get the SQL ORDER BY clause
    pub fn sql_order_by(&self) -> String { todo!() }
}

/// Sort options for search queries
#[derive(Debug, Clone, Default)]
pub struct SearchSortOptions {
    pub field: SearchSortField,
    pub order: SortOrder,
}

impl SearchSortOptions {
    pub fn new(field: SearchSortField, order: SortOrder) -> Self { todo!() }

    /// Create from optional string parameters
    pub fn from_params(sort: Option<&str>, order: Option<&str>) -> Self { todo!() }

    /// Check if this is a relevance sort (affects search behavior)
    pub fn is_relevance_sort(&self) -> bool { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::sort::*;




    #[test]
    fn test_entry_sort_options_sql() {
        let opts = EntrySortOptions::new(EntrySortField::Created, SortOrder::Desc);
        assert_eq!(opts.sql_order_by(), "created DESC");

        let opts = EntrySortOptions::new(EntrySortField::Importance, SortOrder::Asc);
        assert_eq!(opts.sql_order_by(), "importance ASC");
    }

    #[test]
    fn test_task_sort_options_from_params() {
        let opts = TaskSortOptions::from_params(Some("priority"), None);
        assert_eq!(opts.field, TaskSortField::Priority);
        assert_eq!(opts.effective_order(), SortOrder::Asc); // Default for priority

        let opts = TaskSortOptions::from_params(Some("created"), Some("asc"));
        assert_eq!(opts.field, TaskSortField::Created);
        assert_eq!(opts.effective_order(), SortOrder::Asc);
    }

    #[test]
    fn test_search_sort_options() {
        let opts = SearchSortOptions::from_params(None, None);
        assert!(opts.is_relevance_sort());

        let opts = SearchSortOptions::from_params(Some("created"), Some("asc"));
        assert!(!opts.is_relevance_sort());
    }
}
