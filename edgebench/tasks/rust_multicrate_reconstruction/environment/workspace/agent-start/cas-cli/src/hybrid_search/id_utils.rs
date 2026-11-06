use regex::Regex;

/// Extract CAS ID patterns from a query string
/// Returns (extracted_ids, remaining_query)
/// Matches patterns like: cas-XXXX, cas-sk0a, rule-041, etc.
pub fn extract_id_patterns(query: &str) -> (Vec<String>, String) { todo!() }

/// Simple glob pattern matching for file paths
/// Supports * (any chars except /) and ** (any chars including /)
pub(crate) fn path_matches_pattern(path: &str, pattern: &str) -> bool { todo!() }
