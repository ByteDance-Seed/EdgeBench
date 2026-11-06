//! Friendly name generator for CAS agents
//!
//! Generates random adjective-noun combinations like "jolly-panda" or "swift-falcon"
//! for use as human-friendly agent identifiers in multi-agent sessions.

use rand::Rng;
use rand::seq::IndexedRandom;
use std::collections::HashSet;

const ADJECTIVES: &[&str] = &[
    "agile", "bold", "brave", "bright", "calm", "clever", "cosmic", "crisp", "daring", "eager",
    "fair", "fast", "fierce", "gentle", "golden", "happy", "jolly", "keen", "kind", "lively",
    "loyal", "mighty", "nimble", "noble", "patient", "proud", "quick", "quiet", "rapid", "ready",
    "sharp", "silent", "smooth", "solid", "steady", "strong", "sturdy", "subtle", "swift",
    "tender", "true", "vivid", "warm", "watchful", "wild", "wise", "witty", "young", "zealous",
    "zen",
];

const NOUNS: &[&str] = &[
    "badger", "bear", "cardinal", "cheetah", "cobra", "condor", "crane", "crow", "dolphin",
    "dragon", "eagle", "falcon", "finch", "fox", "gazelle", "gopher", "hawk", "heron", "hound",
    "jaguar", "jay", "kestrel", "koala", "lark", "leopard", "lion", "lynx", "marten", "merlin",
    "newt", "octopus", "otter", "owl", "panda", "panther", "parrot", "pelican", "phoenix", "puma",
    "raven", "robin", "salmon", "shark", "sparrow", "spider", "stork", "swan", "tiger", "viper",
    "wolf",
];

/// Generate a single random friendly name
///
/// # Example
/// ```rust
/// use cas::orchestration::names;
///
/// let name = names::generate();
/// // Returns something like "jolly-panda-42" or "swift-falcon-7"
/// ```
pub fn generate() -> String { todo!() }

/// Generate N unique friendly names
///
/// If more names are requested than possible combinations (50 * 51 * 99 = 252,450),
/// this will return as many unique names as possible.
///
/// # Example
/// ```rust
/// use cas::orchestration::names;
///
/// let names = names::generate_unique(3);
/// // Returns something like ["jolly-panda-42", "swift-falcon-7", "brave-owl-88"]
/// ```
pub fn generate_unique(count: usize) -> Vec<String> { todo!() }

#[cfg(test)]
mod tests {
    use crate::orchestration::names::*;

    #[test]
    fn test_generate_format() {
        let name = generate();
        assert!(name.contains('-'), "Name should contain hyphen: {name}");
        let parts: Vec<&str> = name.split('-').collect();
        assert_eq!(
            parts.len(),
            3,
            "Name should have exactly three parts: {name}"
        );
    }

    #[test]
    fn test_generate_uses_valid_words() {
        let name = generate();
        let parts: Vec<&str> = name.split('-').collect();
        assert!(
            ADJECTIVES.contains(&parts[0]),
            "First part should be a valid adjective: {}",
            parts[0]
        );
        assert!(
            NOUNS.contains(&parts[1]),
            "Second part should be a valid noun: {}",
            parts[1]
        );
        let num: u8 = parts[2].parse().expect("Third part should be a number");
        assert!((1..100).contains(&num), "Number should be 1-99: {num}");
    }

    #[test]
    fn test_generate_unique_returns_correct_count() {
        let names = generate_unique(5);
        assert_eq!(names.len(), 5);
    }

    #[test]
    fn test_generate_unique_all_different() {
        let names = generate_unique(10);
        let unique: HashSet<_> = names.iter().collect();
        assert_eq!(unique.len(), names.len(), "All names should be unique");
    }

    #[test]
    fn test_generate_unique_handles_large_count() {
        // Should not panic even with large count
        let names = generate_unique(100);
        assert_eq!(names.len(), 100);
    }
}
