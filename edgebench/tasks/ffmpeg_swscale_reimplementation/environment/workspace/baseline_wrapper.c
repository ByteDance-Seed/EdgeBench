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
#include <libswscale/swscale.h>
#include <libavutil/pixfmt.h>
#include <libavutil/imgutils.h>

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
} BaselineCtx;

/* ── Exported API ──────────────────────────────────────────────────────── */

void *swscale_create(int src_w, int src_h, int src_fmt,
                     int dst_w, int dst_h, int dst_fmt,
                     int algo) {
    enum AVPixelFormat av_src = map_pixfmt(src_fmt);
    enum AVPixelFormat av_dst = map_pixfmt(dst_fmt);
    if (av_src == AV_PIX_FMT_NONE || av_dst == AV_PIX_FMT_NONE)
        return NULL;

    struct SwsContext *sws = sws_getContext(
        src_w, src_h, av_src,
        dst_w, dst_h, av_dst,
        map_algo(algo), NULL, NULL, NULL);
    if (!sws)
        return NULL;

    BaselineCtx *ctx = malloc(sizeof(BaselineCtx));
    if (!ctx) {
        sws_freeContext(sws);
        return NULL;
    }
    ctx->sws = sws;
    ctx->src_h = src_h;
    ctx->dst_h = dst_h;
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
    free(ctx);
}
