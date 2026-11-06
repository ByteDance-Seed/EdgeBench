//! Core search traits
//!
//! This module defines the fundamental traits for search operations:
//!
//! - [`SearchDocument`] - Generic document representation for indexing
//! - [`VectorStore`] - Vector storage and similarity search
//! - [`TextIndex`] - Full-text (BM25) search index

use std::collections::HashMap;

use crate::error::Result;

/// A document that can be indexed for search
///
/// This trait provides a generic interface for documents that can be
/// indexed by both full-text (BM25) and vector (semantic) search systems.
///
/// # Example
///
/// ```rust,ignore
/// use cas_search::SearchDocument;
///
/// struct MyDoc {
///     id: String,
///     title: String,
///     body: String,
///     tags: Vec<String>,
/// }
///
/// impl SearchDocument for MyDoc {
///     fn doc_id(&self) -> &str { &self.id }
///     fn doc_content(&self) -> &str { &self.body }
///     fn doc_type(&self) -> &str { "article" }
///     fn doc_tags(&self) -> Vec<&str> { self.tags.iter().map(|s| s.as_str()).collect() }
///     fn doc_metadata(&self) -> HashMap<String, String> {
///         let mut m = HashMap::new();
///         m.insert("title".into(), self.title.clone());
///         m
///     }
/// }
/// ```
pub trait SearchDocument {
    /// Unique identifier for the document
    fn doc_id(&self) -> &str;

    /// Primary text content to be indexed and searched
    fn doc_content(&self) -> &str;

    /// Document type (e.g., "entry", "task", "rule", "skill")
    ///
    /// Used for filtering search results by type.
    fn doc_type(&self) -> &str;

    /// Tags associated with the document
    ///
    /// Tags are indexed separately and can be used for filtering.
    fn doc_tags(&self) -> Vec<&str>;

    /// Additional metadata as key-value pairs
    ///
    /// Metadata can include title, timestamps, status, etc.
    fn doc_metadata(&self) -> HashMap<String, String>;

    /// Optional title for display purposes
    fn doc_title(&self) -> Option<&str> { todo!() }

    /// Combined text for embedding generation
    ///
    /// Override this to customize what text is used for semantic search.
    /// By default, combines title (if present) and content.
    fn doc_embedding_text(&self) -> String { todo!() }
}

/// Vector storage and similarity search trait
///
/// This trait abstracts over different vector storage backends (HNSW, LMDB, etc.)
/// and provides a consistent interface for storing embeddings and performing
/// similarity searches.
///
/// # Example
///
/// ```rust,ignore
/// use cas_search::VectorStore;
///
/// fn search_similar(store: &dyn VectorStore, query: &[f32]) -> Vec<String> {
///     let results = store.search(query, 10).unwrap();
///     results.into_iter().map(|(id, _score)| id).collect()
/// }
/// ```
pub trait VectorStore: Send + Sync {
    /// Store an embedding vector for a document
    ///
    /// # Arguments
    /// * `doc_id` - Unique identifier for the document
    /// * `embedding` - The embedding vector to store
    ///
    /// # Errors
    /// Returns an error if the embedding dimension doesn't match the store's
    /// configured dimension, or if storage fails.
    fn store(&self, doc_id: &str, embedding: &[f32]) -> Result<()>;

    /// Retrieve an embedding vector by document ID
    ///
    /// Returns `None` if no embedding exists for the given ID.
    fn get(&self, doc_id: &str) -> Result<Option<Vec<f32>>>;

    /// Delete an embedding by document ID
    ///
    /// No-op if the embedding doesn't exist.
    fn delete(&self, doc_id: &str) -> Result<()>;

    /// Find k nearest neighbors to the query vector
    ///
    /// Returns a list of (doc_id, similarity_score) pairs sorted by
    /// similarity in descending order (most similar first).
    ///
    /// # Arguments
    /// * `query` - The query embedding vector
    /// * `k` - Maximum number of results to return
    fn search(&self, query: &[f32], k: usize) -> Result<Vec<(String, f32)>>;

    /// Check if an embedding exists for the given document ID
    fn exists(&self, doc_id: &str) -> Result<bool>;

    /// Count total embeddings stored
    fn count(&self) -> Result<usize>;

    /// List all document IDs with stored embeddings
    fn list_ids(&self) -> Result<Vec<String>>;

    /// Get the embedding dimension for this store
    fn dimension(&self) -> usize;
}

/// Full-text search index trait
///
/// This trait abstracts over full-text search backends (Tantivy, etc.)
/// and provides a consistent interface for BM25-style text search.
pub trait TextIndex: Send + Sync {
    /// Index a document for full-text search
    ///
    /// # Arguments
    /// * `doc` - The document to index
    fn index(&self, doc: &dyn SearchDocument) -> Result<()>;

    /// Remove a document from the index
    fn remove(&self, doc_id: &str) -> Result<()>;

    /// Search for documents matching a query
    ///
    /// Returns a list of (doc_id, bm25_score) pairs sorted by score
    /// in descending order.
    ///
    /// # Arguments
    /// * `query` - The search query string
    /// * `limit` - Maximum number of results to return
    fn search(&self, query: &str, limit: usize) -> Result<Vec<(String, f64)>>;

    /// Search with type filter
    ///
    /// # Arguments
    /// * `query` - The search query string
    /// * `doc_type` - Only return documents of this type
    /// * `limit` - Maximum number of results to return
    fn search_with_type(
        &self,
        query: &str,
        doc_type: &str,
        limit: usize,
    ) -> Result<Vec<(String, f64)>>;

    /// Search with tag filter
    ///
    /// # Arguments
    /// * `query` - The search query string
    /// * `tags` - Only return documents with all these tags
    /// * `limit` - Maximum number of results to return
    fn search_with_tags(
        &self,
        query: &str,
        tags: &[&str],
        limit: usize,
    ) -> Result<Vec<(String, f64)>>;

    /// Commit any pending changes to the index
    fn commit(&self) -> Result<()>;
}

/// A search result from any search method
#[derive(Debug, Clone)]
pub struct SearchResult {
    /// Document ID
    pub id: String,
    /// Relevance score (normalized to 0-1 range)
    pub score: f64,
    /// Source of the score (bm25, semantic, hybrid)
    pub source: ScoreSource,
}

/// Source of a search result score
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ScoreSource {
    /// BM25 full-text search
    Bm25,
    /// Semantic vector search
    Semantic,
    /// Combined hybrid search
    Hybrid,
    /// Reranker model
    Reranked,
}

impl SearchResult {
    /// Create a new search result
    pub fn new(id: impl Into<String>, score: f64, source: ScoreSource) -> Self { todo!() }
}

// =============================================================================
// Async traits (requires `parallel` feature, Rust 1.75+ native async traits)
// =============================================================================

/// Async vector storage and similarity search trait
///
/// This is the async version of [`VectorStore`] for concurrent operations.
/// Uses native `async fn` in traits (Rust 1.75+) - no async-trait crate needed.
///
/// # Note
///
/// Native async traits do NOT support trait objects (`dyn AsyncVectorStore`).
/// Use generics with trait bounds instead: `fn search<V: AsyncVectorStore>(store: &V)`.
///
/// # Example
///
/// ```rust,ignore
/// use cas_search::AsyncVectorStore;
///
/// async fn search_similar<V: AsyncVectorStore>(store: &V, query: &[f32]) -> Vec<String> {
///     let results = store.search_async(query, 10).await.unwrap();
///     results.into_iter().map(|(id, _score)| id).collect()
/// }
/// ```
#[cfg(feature = "parallel")]
pub trait AsyncVectorStore: Send + Sync {
    /// Store an embedding vector asynchronously
    ///
    /// CPU-bound operations should use `tokio::task::spawn_blocking`.
    fn store_async(
        &self,
        doc_id: &str,
        embedding: &[f32],
    ) -> impl std::future::Future<Output = Result<()>> + Send;

    /// Retrieve an embedding vector asynchronously
    fn get_async(
        &self,
        doc_id: &str,
    ) -> impl std::future::Future<Output = Result<Option<Vec<f32>>>> + Send;

    /// Delete an embedding asynchronously
    fn delete_async(&self, doc_id: &str) -> impl std::future::Future<Output = Result<()>> + Send;

    /// Find k nearest neighbors asynchronously
    ///
    /// CPU-bound HNSW search should use `tokio::task::spawn_blocking`.
    fn search_async(
        &self,
        query: &[f32],
        k: usize,
    ) -> impl std::future::Future<Output = Result<Vec<(String, f32)>>> + Send;

    /// Check if an embedding exists asynchronously
    fn exists_async(&self, doc_id: &str) -> impl std::future::Future<Output = Result<bool>> + Send;

    /// Count total embeddings asynchronously
    fn count_async(&self) -> impl std::future::Future<Output = Result<usize>> + Send;

    /// Get the embedding dimension (sync - dimensions don't change)
    fn dimension(&self) -> usize;
}

/// Async full-text search index trait
///
/// This is the async version of [`TextIndex`] for concurrent operations.
/// Uses native `async fn` in traits (Rust 1.75+) - no async-trait crate needed.
///
/// # Note
///
/// Native async traits do NOT support trait objects (`dyn AsyncTextIndex`).
/// Use generics with trait bounds instead.
#[cfg(feature = "parallel")]
pub trait AsyncTextIndex: Send + Sync {
    /// Index a document asynchronously
    ///
    /// CPU-bound Tantivy operations should use `tokio::task::spawn_blocking`.
    fn index_async<D: SearchDocument + Sync>(
        &self,
        doc: &D,
    ) -> impl std::future::Future<Output = Result<()>> + Send;

    /// Remove a document from the index asynchronously
    fn remove_async(&self, doc_id: &str) -> impl std::future::Future<Output = Result<()>> + Send;

    /// Search for documents asynchronously
    ///
    /// CPU-bound Tantivy search should use `tokio::task::spawn_blocking`.
    fn search_async(
        &self,
        query: &str,
        limit: usize,
    ) -> impl std::future::Future<Output = Result<Vec<(String, f64)>>> + Send;

    /// Search with type filter asynchronously
    fn search_with_type_async(
        &self,
        query: &str,
        doc_type: &str,
        limit: usize,
    ) -> impl std::future::Future<Output = Result<Vec<(String, f64)>>> + Send;

    /// Search with tag filter asynchronously
    fn search_with_tags_async(
        &self,
        query: &str,
        tags: &[&str],
        limit: usize,
    ) -> impl std::future::Future<Output = Result<Vec<(String, f64)>>> + Send;

    /// Commit any pending changes asynchronously
    fn commit_async(&self) -> impl std::future::Future<Output = Result<()>> + Send;
}

/// Async embedder trait for generating text embeddings
///
/// Uses native `async fn` in traits (Rust 1.75+) - no async-trait crate needed.
#[cfg(feature = "parallel")]
pub trait AsyncEmbedder: Send + Sync {
    /// Generate embedding vector for text asynchronously
    ///
    /// CPU-bound model inference should use `tokio::task::spawn_blocking`.
    fn embed_async(&self, text: &str)
    -> impl std::future::Future<Output = Result<Vec<f32>>> + Send;

    /// Get embedding dimension (sync - doesn't change)
    fn dimension(&self) -> usize;
}

#[cfg(test)]
mod tests {
    use crate::traits::*;

    struct TestDoc {
        id: String,
        content: String,
        doc_type: String,
        tags: Vec<String>,
    }

    impl SearchDocument for TestDoc {
        fn doc_id(&self) -> &str {
            &self.id
        }

        fn doc_content(&self) -> &str {
            &self.content
        }

        fn doc_type(&self) -> &str {
            &self.doc_type
        }

        fn doc_tags(&self) -> Vec<&str> {
            self.tags.iter().map(|s| s.as_str()).collect()
        }

        fn doc_metadata(&self) -> HashMap<String, String> {
            HashMap::new()
        }
    }

    #[test]
    fn test_search_document_trait() {
        let doc = TestDoc {
            id: "doc-001".into(),
            content: "This is test content".into(),
            doc_type: "test".into(),
            tags: vec!["tag1".into(), "tag2".into()],
        };

        assert_eq!(doc.doc_id(), "doc-001");
        assert_eq!(doc.doc_content(), "This is test content");
        assert_eq!(doc.doc_type(), "test");
        assert_eq!(doc.doc_tags(), vec!["tag1", "tag2"]);
        assert!(doc.doc_title().is_none());
    }

    #[test]
    fn test_search_document_embedding_text() {
        let doc = TestDoc {
            id: "doc-001".into(),
            content: "Content here".into(),
            doc_type: "test".into(),
            tags: vec![],
        };

        // Without title, returns content
        assert_eq!(doc.doc_embedding_text(), "Content here");
    }


}
