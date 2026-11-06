use crate::mcp::tools::*;

#[cfg(test)]
mod tests {
    use crate::mcp::tools::mod_tests::*;

    // ========================================================================
    // Epic Branch Slugification Tests
    // ========================================================================

    #[test]
    fn test_slugify_for_branch_simple() {
        assert_eq!(slugify_for_branch("Add User Auth"), "add-user-auth");
        assert_eq!(slugify_for_branch("Simple Title"), "simple-title");
    }

    #[test]
    fn test_slugify_for_branch_special_chars() {
        assert_eq!(slugify_for_branch("Fix Bug #123"), "fix-bug-123");
        assert_eq!(slugify_for_branch("Add @feature!"), "add-feature");
        assert_eq!(
            slugify_for_branch("Special!@#$%^&*()Chars"),
            "special-chars"
        );
    }

    #[test]
    fn test_slugify_for_branch_multiple_spaces() {
        assert_eq!(slugify_for_branch("Multiple   Spaces"), "multiple-spaces");
        assert_eq!(
            slugify_for_branch("  Leading Trailing  "),
            "leading-trailing"
        );
    }

    #[test]
    fn test_slugify_for_branch_truncation() {
        // Test that long titles are truncated to 50 chars
        let long_title = "A".repeat(100);
        let result = slugify_for_branch(&long_title);
        assert_eq!(result.len(), 50);
        assert!(result.chars().all(|c| c == 'a'));
    }

    #[test]
    fn test_slugify_for_branch_preserves_numbers() {
        assert_eq!(
            slugify_for_branch("Version 2.0 Release"),
            "version-2-0-release"
        );
        assert_eq!(slugify_for_branch("CAS v1"), "cas-v1");
    }
}
