//! SearchDocument implementations for CAS domain types
//!
//! This module provides [`SearchDocument`] implementations for all
//! CAS domain types, enabling them to be indexed and searched.

use std::collections::HashMap;

use cas_code::CodeSymbol;
use cas_types::{Entry, Rule, Skill, Spec, Task};

use crate::traits::SearchDocument;

// =============================================================================
// Entry implementation
// =============================================================================

impl SearchDocument for Entry {
    fn doc_id(&self) -> &str { todo!() }

    fn doc_content(&self) -> &str { todo!() }

    fn doc_type(&self) -> &str { todo!() }

    fn doc_tags(&self) -> Vec<&str> { todo!() }

    fn doc_metadata(&self) -> HashMap<String, String> { todo!() }

    fn doc_title(&self) -> Option<&str> { todo!() }
}

// =============================================================================
// Task implementation
// =============================================================================

impl SearchDocument for Task {
    fn doc_id(&self) -> &str { todo!() }

    fn doc_content(&self) -> &str { todo!() }

    fn doc_type(&self) -> &str { todo!() }

    fn doc_tags(&self) -> Vec<&str> { todo!() }

    fn doc_metadata(&self) -> HashMap<String, String> { todo!() }

    fn doc_title(&self) -> Option<&str> { todo!() }

    fn doc_embedding_text(&self) -> String { todo!() }
}

// =============================================================================
// Rule implementation
// =============================================================================

impl SearchDocument for Rule {
    fn doc_id(&self) -> &str { todo!() }

    fn doc_content(&self) -> &str { todo!() }

    fn doc_type(&self) -> &str { todo!() }

    fn doc_tags(&self) -> Vec<&str> { todo!() }

    fn doc_metadata(&self) -> HashMap<String, String> { todo!() }
}

// =============================================================================
// Skill implementation
// =============================================================================

impl SearchDocument for Skill {
    fn doc_id(&self) -> &str { todo!() }

    fn doc_content(&self) -> &str { todo!() }

    fn doc_type(&self) -> &str { todo!() }

    fn doc_tags(&self) -> Vec<&str> { todo!() }

    fn doc_metadata(&self) -> HashMap<String, String> { todo!() }

    fn doc_title(&self) -> Option<&str> { todo!() }

    fn doc_embedding_text(&self) -> String { todo!() }
}

// =============================================================================
// Spec implementation
// =============================================================================

impl SearchDocument for Spec {
    fn doc_id(&self) -> &str { todo!() }

    fn doc_content(&self) -> &str { todo!() }

    fn doc_type(&self) -> &str { todo!() }

    fn doc_tags(&self) -> Vec<&str> { todo!() }

    fn doc_metadata(&self) -> HashMap<String, String> { todo!() }

    fn doc_title(&self) -> Option<&str> { todo!() }

    fn doc_embedding_text(&self) -> String { todo!() }
}

// =============================================================================
// CodeSymbol implementation
// =============================================================================

impl SearchDocument for CodeSymbol {
    fn doc_id(&self) -> &str { todo!() }

    fn doc_content(&self) -> &str { todo!() }

    fn doc_type(&self) -> &str { todo!() }

    fn doc_tags(&self) -> Vec<&str> { todo!() }

    fn doc_metadata(&self) -> HashMap<String, String> { todo!() }

    fn doc_title(&self) -> Option<&str> { todo!() }

    fn doc_embedding_text(&self) -> String { todo!() }
}

#[cfg(test)]
#[path = "document_tests/tests.rs"]
mod tests;
