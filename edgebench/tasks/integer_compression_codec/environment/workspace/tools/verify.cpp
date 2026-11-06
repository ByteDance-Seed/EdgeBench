// Fuzz verifier: exercises ic_encode / ic_decode on many random inputs
// (various distributions and sizes) and checks exact roundtrip equality.

#include "intcompress.h"

#include <algorithm>
#include <cstdio>
#include <cstdint>
#include <cstring>
#include <dlfcn.h>
#include <random>
#include <vector>

namespace {

using EncodeFn = size_t(*)(const uint32_t*, size_t, uint8_t*, size_t);
using DecodeFn = size_t(*)(const uint8_t*, size_t, uint32_t*, size_t);

enum class Dist { Random, SortedAscending, LowEntropy, Zipfian, Sparse };

std::vector<uint32_t> gen(std::mt19937_64& rng, Dist d, size_t n) {
    std::vector<uint32_t> v(n);
    switch (d) {
        case Dist::Random:
            for (auto& x : v) x = static_cast<uint32_t>(rng());
            break;
        case Dist::SortedAscending: {
            uint64_t cur = 0;
            std::exponential_distribution<double> exp(1.0 / 1000.0);
            for (auto& x : v) {
                cur += 1 + static_cast<uint64_t>(exp(rng));
                x = static_cast<uint32_t>(cur & 0x7fffffffu);
            }
            break;
        }
        case Dist::LowEntropy: {
            std::normal_distribution<double> nd(2500.0, 300.0);
            for (auto& x : v) {
                double s = nd(rng);
                x = static_cast<uint32_t>(std::max(0.0, s));
            }
            break;
        }
        case Dist::Zipfian: {
            // crude discrete approximation
            std::uniform_real_distribution<double> u(0.0, 1.0);
            for (auto& x : v) {
                double r = u(rng);
                x = static_cast<uint32_t>(1.0 / (r + 1e-6));
            }
            break;
        }
        case Dist::Sparse: {
            std::uniform_int_distribution<int> hot(0, 99);
            std::uniform_int_distribution<int> pick(0, 1);
            std::vector<uint32_t> hotvals(100);
            for (auto& h : hotvals) h = static_cast<uint32_t>(rng() & 0xffff);
            for (auto& x : v) {
                x = pick(rng) ? hotvals[hot(rng)] : static_cast<uint32_t>(rng());
            }
            std::sort(v.begin(), v.end());
            break;
        }
    }
    return v;
}

}  // namespace

int main(int argc, char** argv) {
    if (argc < 2) {
        std::fprintf(stderr, "usage: %s <libintcompress.so> [rounds=1000]\n", argv[0]);
        return 1;
    }
    int rounds = (argc >= 3) ? std::atoi(argv[2]) : 1000;

    void* lib = dlopen(argv[1], RTLD_NOW);
    if (!lib) { std::fprintf(stderr, "dlopen: %s\n", dlerror()); return 1; }
    auto encode = reinterpret_cast<EncodeFn>(dlsym(lib, "ic_encode"));
    auto decode = reinterpret_cast<DecodeFn>(dlsym(lib, "ic_decode"));
    if (!encode || !decode) {
        std::fprintf(stderr, "symbols missing\n"); return 1;
    }

    std::mt19937_64 rng(0xC0FFEEULL);
    Dist all[] = { Dist::Random, Dist::SortedAscending, Dist::LowEntropy,
                   Dist::Zipfian, Dist::Sparse };
    std::uniform_int_distribution<int> pick_dist(0, 4);
    std::uniform_int_distribution<size_t> pick_n(0, 100000);

    int fail = 0;
    for (int r = 0; r < rounds; ++r) {
        Dist d = all[pick_dist(rng)];
        size_t n = pick_n(rng);
        auto in = gen(rng, d, n);
        std::vector<uint8_t> enc(4ull * (n + 1) * sizeof(uint32_t));
        std::vector<uint32_t> out(n);
        size_t eb = encode(in.data(), n, enc.data(), enc.size());
        if (eb == static_cast<size_t>(-1)) {
            std::fprintf(stderr, "encode failed: round=%d n=%zu dist=%d\n", r, n, static_cast<int>(d));
            ++fail; continue;
        }
        size_t ds = decode(enc.data(), eb, out.data(), out.size());
        if (ds != n || std::memcmp(in.data(), out.data(), n * 4) != 0) {
            std::fprintf(stderr, "roundtrip FAIL: round=%d n=%zu dist=%d\n", r, n, static_cast<int>(d));
            ++fail;
        }
    }
    std::printf("verify: %d rounds, %d failures\n", rounds, fail);
    return fail == 0 ? 0 : 1;
}
