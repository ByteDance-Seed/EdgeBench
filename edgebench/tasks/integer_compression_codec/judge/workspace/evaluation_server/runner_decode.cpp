// Standalone decode-only runner. Reads the encoded blob and the original input
// (read-only), runs 5× decode, compares byte-exact, and writes a meta.json.

#include "intcompress.h"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <fstream>
#include <string>
#include <vector>

using DecodeFn = size_t(*)(const uint8_t*, size_t, uint32_t*, size_t);

std::vector<uint8_t> slurp_bytes(const char* path) {
    std::ifstream f(path, std::ios::binary | std::ios::ate);
    if (!f) { std::perror(path); std::exit(3); }
    const size_t n = static_cast<size_t>(f.tellg());
    f.seekg(0);
    std::vector<uint8_t> v(n);
    f.read(reinterpret_cast<char*>(v.data()), static_cast<std::streamsize>(n));
    return v;
}

int main(int argc, char** argv) {
    if (argc != 5) {
        std::fprintf(stderr, "usage: runner_decode <encoded.bin> <lib.so> <orig.u32> <out.json>\n");
        return 2;
    }
    auto enc = slurp_bytes(argv[1]);
    auto orig = slurp_bytes(argv[3]);
    const size_t n = orig.size() / 4;

    void* lib = dlopen(argv[2], RTLD_NOW);
    if (!lib) { std::fprintf(stderr, "dlopen: %s\n", dlerror()); return 4; }
    auto decode = reinterpret_cast<DecodeFn>(dlsym(lib, "ic_decode"));
    if (!decode) { std::fprintf(stderr, "no ic_decode\n"); return 5; }

    std::vector<uint32_t> out(n);
    double best = 1e18;
    for (int i = 0; i < 5; ++i) {
        auto t0 = std::chrono::steady_clock::now();
        size_t got = decode(enc.data(), enc.size(), out.data(), out.size());
        auto t1 = std::chrono::steady_clock::now();
        if (got != n) { std::fprintf(stderr, "size mismatch: %zu\n", got); return 6; }
        double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
        best = std::min(best, ms);
    }

    bool ok = std::memcmp(orig.data(), out.data(), n * 4) == 0;
    double gbps = (static_cast<double>(n) * 4.0) / (best / 1000.0) / (1ull << 30);

    // re-read encode_ms from the meta file beside the encoded blob
    std::string meta_path = std::string(argv[1]) + ".meta";  // caller passes explicit path in server
    // The server currently writes a *separate* meta path; here we just emit
    // decode + roundtrip. The server merges by submission_id.
    std::FILE* f = std::fopen(argv[4], "w");
    std::fprintf(f,
        "{\"n\":%zu,\"encoded_bytes\":%zu,\"encode_ms\":0.0,"
        "\"decode_ms\":%.3f,\"decode_gbps\":%.4f,\"roundtrip_ok\":%s}\n",
        n, enc.size(), best, gbps, ok ? "true" : "false");
    std::fclose(f);
    return 0;
}
