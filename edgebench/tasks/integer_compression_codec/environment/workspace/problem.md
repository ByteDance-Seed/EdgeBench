Background: High-throughput integer compression codecs are core building blocks for columnar storage (ClickHouse, DuckDB, Apache Parquet), full-text search inverted indexes (Lucene, Tantivy), and time-series databases (InfluxDB, VictoriaMetrics).
The fundamental tension is: compression ratio and decoding throughput are at odds -- Varint-based schemes decode quickly but use more bits; FastPFor/SIMD-BP128 achieve better compression ratios but are complex to implement; Elias-Fano is optimal for sorted sequences but has high random access overhead. Production systems typically adopt block-adaptive strategies.

Task: Implement a C++17 integer compression codec library `libintcompress.so`, exporting the following C-linkage symbols:
`size_t ic_encode(const uint32_t* in, size_t n, uint8_t* out, size_t out_cap);`
`size_t ic_decode(const uint8_t* in, size_t in_size, uint32_t* out, size_t out_cap);`
`size_t ic_decode_block(const uint8_t* in, size_t in_size, size_t block_idx, uint32_t* out, size_t out_cap);` (random block access, block_idx is 0-based block number; implementations that do not support this may return SIZE_MAX)

Input distributions (8 fixed datasets): (1) Ascending docIDs (search engine gov2 sample, 100M) (2) Ascending Unix timestamps (seconds) (3) Ascending Unix timestamps (nanoseconds) (4) Sensor temperature readings (low-entropy small values) (5) Geographic coordinate grid IDs (medium-entropy zigzag distribution) (6) Zipfian document lengths (highly skewed) (7) Uniform random uint32 (worst case) (8) Sorted data with duplicates (sparse + high-frequency value mix)

Scoring formula: Let B_i^0 and T_i^0 be the baseline (official Varint) compressed bits-per-integer and decoding throughput for dataset i; let B_i and T_i be the contestant's corresponding values.
    S_i = min(B_i^0 / B_i, 8.0) × min(T_i / T_i^0, 40.0) (both ratios are capped to prevent extreme score inflation)
    Final score: Score = Σ_{i=1..8} w_i × S_i / Σ w_i, where w = [2, 1.5, 1.5, 1, 1, 1, 1, 1] (docID and timestamp datasets carry higher weight, reflecting production workload distributions).

Hard constraints: (1) If decode(encode(X)) != X for any dataset, S_i = 0; (2) If total encode+decode time for a single dataset exceeds 300s, S_i = 0; (3) Encoded buffer must not exceed 4 × n × sizeof(uint32_t); (4) No exploiting any input information beyond block_idx (e.g., hidden seeds).

Resource limits: Remote evaluation uses a 4 vCPU / 8 GB / 20 GB disk Docker container; g++ 12.2 -std=c++17 -O3 -march=x86-64-v3 (AVX2 available, AVX-512 unavailable, to avoid score variance from hardware differences).

Evaluation method: Remote evaluation, each contestant is allowed up to 100 submissions, each submission's score is the weighted composite score across 8 datasets, and the final score is the maximum across all submissions. Each submission returns per-dataset details (encoded_bytes, encode_ms, decode_ms, roundtrip_ok, S_i) to help contestants identify bottlenecks.
