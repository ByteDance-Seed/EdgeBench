// Reference copy of the baseline (Varint) codec.
// This is byte-identical to workspace/src/codec.cpp — kept here so the
// evaluation server can sanity-check that its own baseline measurement matches
// what Agents will see as their starting point.

#include "intcompress.h"

#include <cstring>

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

inline size_t decode_varint_u32(const uint8_t* in, size_t in_size, uint32_t* value) {
    uint32_t result = 0;
    size_t shift = 0, i = 0;
    while (i < in_size && i < 5) {
        uint8_t b = in[i++];
        result |= static_cast<uint32_t>(b & 0x7fu) << shift;
        if ((b & 0x80u) == 0) { *value = result; return i; }
        shift += 7;
    }
    return 0;
}
}  // namespace

extern "C" size_t ic_encode(const uint32_t* in, size_t n, uint8_t* out, size_t out_cap) {
    if (out_cap < 4) return kFailure;
    std::memcpy(out, &n, sizeof(uint32_t));
    size_t off = 4;
    for (size_t i = 0; i < n; ++i) {
        if (out_cap - off < 5) return kFailure;
        off += encode_varint_u32(in[i], out + off);
    }
    return off;
}

extern "C" size_t ic_decode(const uint8_t* in, size_t in_size, uint32_t* out, size_t out_cap) {
    if (in_size < 4) return kFailure;
    uint32_t n_lo; std::memcpy(&n_lo, in, sizeof(uint32_t));
    size_t n = n_lo;
    if (n > out_cap) return kFailure;
    size_t off = 4;
    for (size_t i = 0; i < n; ++i) {
        uint32_t v;
        size_t c = decode_varint_u32(in + off, in_size - off, &v);
        if (c == 0) return kFailure;
        off += c; out[i] = v;
    }
    return n;
}

extern "C" size_t ic_decode_block(const uint8_t*, size_t, size_t, uint32_t*, size_t) {
    return static_cast<size_t>(-1);
}
