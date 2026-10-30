// ============================================================================
// Baseline Varint codec.
//
// This is the starting point provided by the task authors. It is intentionally
// simple and slow. Your job is to replace / augment this with a faster codec
// that preserves the ABI in include/intcompress.h.
//
// Format: 7-bit groups, little-endian. MSB=1 means "more bytes follow".
// ============================================================================

#include "intcompress.h"

#include <cstring>
#include <limits>

namespace {

constexpr size_t kFailure = static_cast<size_t>(-1);

inline size_t encode_varint_u32(uint32_t v, uint8_t* out) {
    size_t i = 0;
    while (v >= 0x80u) {
        out[i++] = static_cast<uint8_t>(v) | 0x80u;
        v >>= 7;
    }
    out[i++] = static_cast<uint8_t>(v);
    return i;
}

// Returns bytes consumed, or 0 on failure. Result written to *value.
inline size_t decode_varint_u32(const uint8_t* in, size_t in_size,
                                uint32_t* value) {
    uint32_t result = 0;
    size_t shift = 0;
    size_t i = 0;
    while (i < in_size && i < 5) {
        uint8_t byte = in[i++];
        result |= static_cast<uint32_t>(byte & 0x7fu) << shift;
        if ((byte & 0x80u) == 0) {
            *value = result;
            return i;
        }
        shift += 7;
    }
    return 0;  // truncated or too many bytes
}

}  // namespace

extern "C" size_t ic_encode(const uint32_t* in, size_t n,
                            uint8_t* out, size_t out_cap) {
    // Write a tiny header: 4-byte little-endian count, then varints.
    if (out_cap < 4) return kFailure;
    std::memcpy(out, &n, sizeof(uint32_t));  // low 32 bits of n
    size_t off = 4;
    for (size_t i = 0; i < n; ++i) {
        if (out_cap - off < 5) return kFailure;
        off += encode_varint_u32(in[i], out + off);
    }
    return off;
}

extern "C" size_t ic_decode(const uint8_t* in, size_t in_size,
                            uint32_t* out, size_t out_cap) {
    if (in_size < 4) return kFailure;
    uint32_t n_lo;
    std::memcpy(&n_lo, in, sizeof(uint32_t));
    size_t n = n_lo;  // assumes n fits in 32 bits; fine for our datasets
    if (n > out_cap) return kFailure;

    size_t off = 4;
    for (size_t i = 0; i < n; ++i) {
        uint32_t v;
        size_t consumed = decode_varint_u32(in + off, in_size - off, &v);
        if (consumed == 0) return kFailure;
        off += consumed;
        out[i] = v;
    }
    return n;
}

extern "C" size_t ic_decode_block(const uint8_t* /*in*/, size_t /*in_size*/,
                                  size_t /*block_idx*/,
                                  uint32_t* /*out*/, size_t /*out_cap*/) {
    // Baseline does not implement random-access block decoding.
    return kFailure;
}
