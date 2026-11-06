// Local benchmark harness. Mirrors the remote evaluator's measurement logic
// (running encode once + decode 5x median) but on the small local samples.
//
// Usage:
//   ./tools/bench <dataset.u32> <libintcompress.so>
//   ./tools/bench --all <libintcompress.so> [--baseline baseline.json]

#include "intcompress.h"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstdint>
#include <cstring>
#include <dlfcn.h>
#include <fstream>
#include <string>
#include <vector>

namespace {

using EncodeFn = size_t(*)(const uint32_t*, size_t, uint8_t*, size_t);
using DecodeFn = size_t(*)(const uint8_t*, size_t, uint32_t*, size_t);

std::vector<uint32_t> read_u32_file(const std::string& path) {
    std::ifstream f(path, std::ios::binary | std::ios::ate);
    if (!f) { std::fprintf(stderr, "open failed: %s\n", path.c_str()); std::exit(2); }
    const auto size = static_cast<size_t>(f.tellg());
    f.seekg(0);
    std::vector<uint32_t> out(size / 4);
    f.read(reinterpret_cast<char*>(out.data()), static_cast<std::streamsize>(size));
    return out;
}

double ms_between(std::chrono::steady_clock::time_point a,
                  std::chrono::steady_clock::time_point b) {
    return std::chrono::duration<double, std::milli>(b - a).count();
}

struct Result {
    size_t n;
    size_t encoded_bytes;
    double encode_ms;
    double decode_ms_median;
    double decode_gbps;
    bool   roundtrip_ok;
};

Result run_one(const std::string& path, EncodeFn encode, DecodeFn decode) {
    auto input = read_u32_file(path);
    const size_t n = input.size();
    std::vector<uint8_t> enc(4ull * n * sizeof(uint32_t));
    std::vector<uint32_t> dec(n);

    auto t0 = std::chrono::steady_clock::now();
    size_t enc_bytes = encode(input.data(), n, enc.data(), enc.size());
    auto t1 = std::chrono::steady_clock::now();
    if (enc_bytes == static_cast<size_t>(-1)) {
        std::fprintf(stderr, "encode failed on %s\n", path.c_str());
        std::exit(3);
    }

    double best = 1e18;
    for (int i = 0; i < 5; ++i) {
        auto d0 = std::chrono::steady_clock::now();
        size_t got = decode(enc.data(), enc_bytes, dec.data(), dec.size());
        auto d1 = std::chrono::steady_clock::now();
        if (got != n) {
            std::fprintf(stderr, "decode size mismatch on %s: %zu vs %zu\n",
                         path.c_str(), got, n);
            std::exit(4);
        }
        best = std::min(best, ms_between(d0, d1));
    }

    bool ok = std::memcmp(input.data(), dec.data(), n * sizeof(uint32_t)) == 0;
    const double raw_bytes = static_cast<double>(n) * sizeof(uint32_t);
    const double gbps = raw_bytes / (best / 1000.0) / (1ull << 30);

    return { n, enc_bytes, ms_between(t0, t1), best, gbps, ok };
}

void print_one(const std::string& name, const Result& r) {
    const double bpi = r.encoded_bytes * 8.0 / r.n;
    std::printf("[%-10s] n=%-9zu enc=%-10zu bpi=%-6.2f "
                "enc_ms=%-7.2f dec_ms=%-6.2f dec_gbps=%-5.2f ok=%d\n",
                name.c_str(), r.n, r.encoded_bytes, bpi,
                r.encode_ms, r.decode_ms_median, r.decode_gbps,
                r.roundtrip_ok ? 1 : 0);
}

}  // namespace

int main(int argc, char** argv) {
    if (argc < 3) {
        std::fprintf(stderr, "usage: %s <dataset.u32|--all> <libintcompress.so> [--baseline file.json]\n",
                     argv[0]);
        return 1;
    }
    const std::string first(argv[1]);
    const char* lib_path = argv[2];

    void* lib = dlopen(lib_path, RTLD_NOW);
    if (!lib) {
        std::fprintf(stderr, "dlopen failed: %s\n", dlerror());
        return 1;
    }
    auto encode = reinterpret_cast<EncodeFn>(dlsym(lib, "ic_encode"));
    auto decode = reinterpret_cast<DecodeFn>(dlsym(lib, "ic_decode"));
    if (!encode || !decode) {
        std::fprintf(stderr, "missing ic_encode/ic_decode\n");
        return 1;
    }

    if (first == "--all") {
        static const char* names[] = {
            "docids", "ts_sec", "ts_ns", "temp",
            "grid",   "zipf",   "rand",  "sparse"
        };
        for (const char* nm : names) {
            std::string path = std::string("datasets/") + nm + ".u32";
            auto r = run_one(path, encode, decode);
            print_one(nm, r);
        }
    } else {
        auto r = run_one(first, encode, decode);
        print_one(first, r);
    }
    dlclose(lib);
    return 0;
}
