const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "swscale_candidate",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // With -Doptimize=ReleaseFast, Zig defaults to baseline x86_64 (SSE2).
    // To target AVX2 for SIMD, use: zig build -Doptimize=ReleaseFast -Dcpu=x86_64_v3
    // Or use @Vector with portable SIMD — Zig auto-selects the best backend.

    lib.linkLibC();
    b.installArtifact(lib);
}
