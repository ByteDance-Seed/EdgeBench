# Arc Standard Library: embed module
# Vector embeddings, similarity search, and text chunking

# --- Vector Math (native implementations for performance) ---

pub fn dot_product(vec_a, vec_b) => embed_dot_product(vec_a, vec_b)

pub fn magnitude(vec) => embed_magnitude(vec)

pub fn cosine_similarity(vec_a, vec_b) => embed_cosine_similarity(vec_a, vec_b)

pub fn normalize(vec) => embed_normalize(vec)

pub fn euclidean_distance(vec_a, vec_b) => embed_euclidean_distance(vec_a, vec_b)

pub fn centroid(vectors) => embed_centroid(vectors)

# --- Similarity Search ---

# Find top_k most similar vectors from candidates list
# candidates: list of {id, vector} maps
# Returns: list of {id, score} maps sorted by similarity (descending)
pub fn most_similar(query_vec, candidates, top_k) => embed_most_similar(query_vec, candidates, top_k)

# --- Text Chunking ---

# Split text into chunks of approximately chunk_size characters
# Returns list of {chunk, index} maps
pub fn chunk_and_embed(text, chunk_size) {
  let mut chunks = []
  let mut i = 0
  let text_len = len(text)
  let mut idx = 0
  do {
    let end = if i + chunk_size > text_len { text_len } el { i + chunk_size }
    let chunk = slice(text, i, end)
    chunks = push(chunks, {chunk: chunk, index: idx})
    i = i + chunk_size
    idx = idx + 1
  } until i >= text_len
  chunks
}
