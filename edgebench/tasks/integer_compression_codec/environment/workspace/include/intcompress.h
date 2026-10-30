#ifndef INTCOMPRESS_H_
#define INTCOMPRESS_H_

// ============================================================================
// Integer Compression Codec — ABI Contract
//
// ⚠️ DO NOT MODIFY THIS HEADER. The remote evaluation service dlsym's these
// exact symbols with C linkage. Any change to signatures, names, or linkage
// will result in a compile_error or symbol_not_found failure.
// ============================================================================

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Encode `n` uint32 values from `in` into `out` (capacity `out_cap` bytes).
// Returns the number of bytes written, or SIZE_MAX on failure.
// Caller guarantees: out_cap >= 4 * n * sizeof(uint32_t).
size_t ic_encode(const uint32_t* in, size_t n,
                 uint8_t* out, size_t out_cap);

// Decode `in_size` bytes from `in` into uint32 array `out` (capacity `out_cap`
// elements). Returns the number of elements written, or SIZE_MAX on failure.
size_t ic_decode(const uint8_t* in, size_t in_size,
                 uint32_t* out, size_t out_cap);

// Optional: random-access decode of the `block_idx`-th block.
// Implementors choose block size (recommended 128 or 256 elements). Return
// SIZE_MAX if unsupported — the evaluator tolerates this for base scoring.
size_t ic_decode_block(const uint8_t* in, size_t in_size,
                       size_t block_idx, uint32_t* out, size_t out_cap);

#ifdef __cplusplus
}
#endif

#endif  // INTCOMPRESS_H_
