// Standalone encode-only runner. Used by the evaluation service to run ENCODE
// in a separate process from DECODE, so a submission cannot cache the raw input
// between calls.

#include "intcompress.h"

#include <chrono>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <fstream>
#include <string>
#include <vector>

using EncodeFn = size_t(*)(const uint32_t*, size_t, uint8_t*, size_t);

int main(int argc, char** argv) {
    if (argc != 5) {
        std::fprintf(stderr, "usage: runner_encode <input.u32> <lib.so> <out.enc> <out.meta>\n");
        return 2;
    }
    std::ifstream fi(argv[1], std::ios::binary | std::ios::ate);
    if (!fi) { std::perror(argv[1]); return 3; }
    const size_t bytes = static_cast<size_t>(fi.tellg());
    fi.seekg(0);
    std::vector<uint32_t> in(bytes / 4);
    fi.read(reinterpret_cast<char*>(in.data()), static_cast<std::streamsize>(bytes));

    void* lib = dlopen(argv[2], RTLD_NOW);
    if (!lib) { std::fprintf(stderr, "dlopen: %s\n", dlerror()); return 4; }
    auto encode = reinterpret_cast<EncodeFn>(dlsym(lib, "ic_encode"));
    if (!encode) { std::fprintf(stderr, "no ic_encode\n"); return 5; }

    std::vector<uint8_t> enc(4ull * in.size() * sizeof(uint32_t));
    auto t0 = std::chrono::steady_clock::now();
    size_t eb = encode(in.data(), in.size(), enc.data(), enc.size());
    auto t1 = std::chrono::steady_clock::now();
    if (eb == static_cast<size_t>(-1)) {
        std::fprintf(stderr, "encode failed\n"); return 6;
    }
    double enc_ms = std::chrono::duration<double, std::milli>(t1 - t0).count();

    std::ofstream fo(argv[3], std::ios::binary);
    fo.write(reinterpret_cast<const char*>(enc.data()),
             static_cast<std::streamsize>(eb));

    // write sidecar meta
    std::FILE* m = std::fopen(argv[4], "w");
    std::fprintf(m, "{\"n\":%zu,\"encoded_bytes\":%zu,\"encode_ms\":%.3f}\n",
                 in.size(), eb, enc_ms);
    std::fclose(m);
    return 0;
}
