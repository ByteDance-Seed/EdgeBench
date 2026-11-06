// main.zig — Stub implementation of the swscale candidate library.
//
// Exports three C-linkage functions matching swscale_api.h.
// Replace this with a real implementation.

const std = @import("std");

// ── Pixel format constants (match swscale_api.h) ────────────────────────────

const PIXFMT_YUV420P = 0;
const PIXFMT_YUV422P = 1;
const PIXFMT_YUV444P = 2;
const PIXFMT_NV12 = 3;
const PIXFMT_NV21 = 4;
const PIXFMT_RGB24 = 5;
const PIXFMT_BGR24 = 6;
const PIXFMT_RGBA = 7;
const PIXFMT_BGRA = 8;
const PIXFMT_GRAY8 = 9;

const ALGO_NEAREST = 0;
const ALGO_BILINEAR = 1;
const ALGO_BICUBIC = 2;

// ── Context ─────────────────────────────────────────────────────────────────

const SwsContext = struct {
    src_w: c_int,
    src_h: c_int,
    src_fmt: c_int,
    dst_w: c_int,
    dst_h: c_int,
    dst_fmt: c_int,
    algo: c_int,
};

// ── Exported functions ──────────────────────────────────────────────────────

export fn swscale_create(
    src_w: c_int,
    src_h: c_int,
    src_fmt: c_int,
    dst_w: c_int,
    dst_h: c_int,
    dst_fmt: c_int,
    algo: c_int,
) ?*anyopaque {
    const ctx = std.heap.c_allocator.create(SwsContext) catch return null;
    ctx.* = .{
        .src_w = src_w,
        .src_h = src_h,
        .src_fmt = src_fmt,
        .dst_w = dst_w,
        .dst_h = dst_h,
        .dst_fmt = dst_fmt,
        .algo = algo,
    };
    return @ptrCast(ctx);
}

export fn swscale_process(
    opaque: ?*anyopaque,
    src_data: [*]const ?[*]const u8,
    src_stride: [*]const c_int,
    dst_data: [*]const ?[*]u8,
    dst_stride: [*]const c_int,
) c_int {
    _ = src_data;
    _ = src_stride;
    _ = dst_data;
    _ = dst_stride;

    const ctx: *SwsContext = @ptrCast(@alignCast(opaque orelse return -1));
    _ = ctx;

    // TODO: Implement pixel format conversion and scaling here.
    // This stub returns -1 (error). Replace with your implementation.
    return -1;
}

export fn swscale_destroy(opaque: ?*anyopaque) void {
    if (opaque) |ptr| {
        const ctx: *SwsContext = @ptrCast(@alignCast(ptr));
        std.heap.c_allocator.destroy(ctx);
    }
}
