/*
 * baseline_wrapper.c — Thin C shim that wraps FFmpeg's libswscale (compiled
 * with --disable-asm) behind the swscale_api.h interface.
 *
 * Compiled at Docker build time into libswscale_baseline.so.  The verifier
 * loads both this baseline and the agent's candidate via the same ctypes
 * interface for a fair apples-to-apples benchmark.
 *
 * Build:
 *   gcc -shared -fPIC -O2 -o libswscale_baseline.so baseline_wrapper.c \
 *       -I/usr/local/include -L/usr/local/lib -lswscale -lavutil
 */

#include <stdlib.h>
#include <stdint.h>
#include <limits.h>
#include <stddef.h>
#include <string.h>
#include <libswscale/swscale.h>
#include <libavutil/pixfmt.h>
#include <libavutil/imgutils.h>
#include <libavutil/mem.h>

/* ── Format mapping (SWS_PIXFMT_* → AVPixelFormat) ─────────────────────── */

static enum AVPixelFormat map_pixfmt(int fmt) {
    switch (fmt) {
        case 0:  return AV_PIX_FMT_YUV420P;
        case 1:  return AV_PIX_FMT_YUV422P;
        case 2:  return AV_PIX_FMT_YUV444P;
        case 3:  return AV_PIX_FMT_NV12;
        case 4:  return AV_PIX_FMT_NV21;
        case 5:  return AV_PIX_FMT_RGB24;
        case 6:  return AV_PIX_FMT_BGR24;
        case 7:  return AV_PIX_FMT_RGBA;
        case 8:  return AV_PIX_FMT_BGRA;
        case 9:  return AV_PIX_FMT_GRAY8;
        default: return AV_PIX_FMT_NONE;
    }
}

static int map_algo(int algo) {
    switch (algo) {
        case 0:  return SWS_POINT;
        case 1:  return SWS_BILINEAR;
        case 2:  return SWS_BICUBIC;
        default: return SWS_BILINEAR;
    }
}

/* ── Context ───────────────────────────────────────────────────────────── */

typedef struct {
    struct SwsContext *sws;
    int src_h;
    int dst_h;
    int src_row_bytes;
    uint8_t *padded_src[4];
    int padded_stride[4];
} BaselineCtx;

/* ── Exported API ──────────────────────────────────────────────────────── */

void *swscale_create(int src_w, int src_h, int src_fmt,
                     int dst_w, int dst_h, int dst_fmt,
                     int algo) {
    enum AVPixelFormat av_src = map_pixfmt(src_fmt);
    enum AVPixelFormat av_dst = map_pixfmt(dst_fmt);
    if (av_src == AV_PIX_FMT_NONE || av_dst == AV_PIX_FMT_NONE)
        return NULL;
    if (src_w <= 0 || src_w == INT_MAX || src_h <= 0 ||
        dst_w <= 0 || dst_h <= 0)
        return NULL;

    struct SwsContext *sws = sws_getContext(
        src_w, src_h, av_src,
        dst_w, dst_h, av_dst,
        map_algo(algo), NULL, NULL, NULL);
    if (!sws)
        return NULL;

    BaselineCtx *ctx = calloc(1, sizeof(BaselineCtx));
    if (!ctx) {
        sws_freeContext(sws);
        return NULL;
    }
    ctx->sws = sws;
    ctx->src_h = src_h;
    ctx->dst_h = dst_h;
    /* Scalar packed-RGB chroma conversion reads pairs, including a partner
     * beyond odd-width rows. Supply a zero-valued partner from owned storage.
     * Allocate once per context; common even-width inputs keep the direct path.
     */
    if ((src_w & 1) &&
        (av_src == AV_PIX_FMT_RGB24 || av_src == AV_PIX_FMT_BGR24 ||
         av_src == AV_PIX_FMT_RGBA || av_src == AV_PIX_FMT_BGRA)) {
        ctx->src_row_bytes = av_image_get_linesize(av_src, src_w, 0);
        int size = av_image_alloc(ctx->padded_src, ctx->padded_stride,
                                  src_w + 1, src_h, av_src, 32);
        if (ctx->src_row_bytes < 0 || size < 0) {
            av_freep(&ctx->padded_src[0]);
            sws_freeContext(sws);
            free(ctx);
            return NULL;
        }
        memset(ctx->padded_src[0], 0, size);
    }
    return ctx;
}

int swscale_process(void *opaque,
                    const uint8_t *const src_data[4],
                    const int src_stride[4],
                    uint8_t *const dst_data[4],
                    const int dst_stride[4]) {
    BaselineCtx *ctx = (BaselineCtx *)opaque;
    if (!ctx || !ctx->sws)
        return -1;
    if (ctx->padded_src[0]) {
        if (!src_data || !src_stride || !src_data[0] ||
            (src_stride[0] > -ctx->src_row_bytes &&
             src_stride[0] < ctx->src_row_bytes))
            return -1;
        for (int y = 0; y < ctx->src_h; y++) {
            memcpy(ctx->padded_src[0] + (ptrdiff_t)y * ctx->padded_stride[0],
                   src_data[0] + (ptrdiff_t)y * src_stride[0],
                   ctx->src_row_bytes);
        }
        src_data = (const uint8_t *const *)ctx->padded_src;
        src_stride = ctx->padded_stride;
    }
    int ret = sws_scale(ctx->sws,
                        src_data, src_stride,
                        0, ctx->src_h,
                        dst_data, dst_stride);
    return (ret == ctx->dst_h) ? 0 : -1;
}

void swscale_destroy(void *opaque) {
    BaselineCtx *ctx = (BaselineCtx *)opaque;
    if (!ctx) return;
    if (ctx->sws)
        sws_freeContext(ctx->sws);
    av_freep(&ctx->padded_src[0]);
    free(ctx);
}
