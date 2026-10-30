/*
 * swscale_api.h — Public API for the swscale candidate shared library.
 *
 * The agent must implement a shared library (libswscale_candidate.so) that
 * exports the three C-linkage functions declared below.  The verifier loads
 * the library with dlopen / Python ctypes and calls these functions directly.
 *
 * Pixel data follows the planar/packed conventions used by FFmpeg:
 *   - Planar formats (YUV420P, YUV422P, YUV444P, GRAY8) store each
 *     colour plane in a separate buffer.  data[0]=Y, data[1]=U, data[2]=V.
 *   - Semi-planar formats (NV12, NV21) use data[0]=Y and data[1]=UV interleaved.
 *   - Packed formats (RGB24, BGR24, RGBA, BGRA) store everything in data[0].
 *
 * linesize[i] gives the byte stride of plane i (may be larger than the
 * minimum row size due to alignment padding).
 */

#ifndef SWSCALE_API_H
#define SWSCALE_API_H

#include <stdint.h>

/* ── Pixel formats ───────────────────────────────────────────────── */
#define SWS_PIXFMT_YUV420P    0   /* Planar YUV 4:2:0, 12 bpp           */
#define SWS_PIXFMT_YUV422P    1   /* Planar YUV 4:2:2, 16 bpp           */
#define SWS_PIXFMT_YUV444P    2   /* Planar YUV 4:4:4, 24 bpp           */
#define SWS_PIXFMT_NV12       3   /* Semi-planar YUV 4:2:0, Y + UV      */
#define SWS_PIXFMT_NV21       4   /* Semi-planar YUV 4:2:0, Y + VU      */
#define SWS_PIXFMT_RGB24      5   /* Packed RGB  8:8:8                   */
#define SWS_PIXFMT_BGR24      6   /* Packed BGR  8:8:8                   */
#define SWS_PIXFMT_RGBA       7   /* Packed RGBA 8:8:8:8                 */
#define SWS_PIXFMT_BGRA       8   /* Packed BGRA 8:8:8:8                 */
#define SWS_PIXFMT_GRAY8      9   /* Single-plane grayscale, 8 bpp       */
#define SWS_PIXFMT_COUNT     10

/* ── Scaling algorithms ──────────────────────────────────────────── */
#define SWS_ALGO_NEAREST      0   /* Nearest-neighbour                   */
#define SWS_ALGO_BILINEAR     1   /* Bilinear interpolation              */
#define SWS_ALGO_BICUBIC      2   /* Bicubic (Catmull-Rom / Mitchell)    */
#define SWS_ALGO_COUNT        3

/* ── Functions to export ─────────────────────────────────────────── */

/*
 * swscale_create  — Allocate and initialise a conversion context.
 *
 *   src_w, src_h  : source image dimensions (pixels)
 *   src_fmt       : source pixel format (SWS_PIXFMT_*)
 *   dst_w, dst_h  : destination image dimensions (pixels)
 *   dst_fmt       : destination pixel format (SWS_PIXFMT_*)
 *   algo          : scaling algorithm (SWS_ALGO_*)
 *
 * Returns an opaque context pointer, or NULL on error.
 * The context may pre-compute filter coefficients, lookup tables, etc.
 */
void *swscale_create(int src_w, int src_h, int src_fmt,
                     int dst_w, int dst_h, int dst_fmt,
                     int algo);

/*
 * swscale_process — Convert / scale one frame.
 *
 *   ctx           : context returned by swscale_create
 *   src_data[4]   : source plane pointers (unused planes are NULL)
 *   src_stride[4] : source byte strides per plane
 *   dst_data[4]   : destination plane pointers (caller-allocated)
 *   dst_stride[4] : destination byte strides per plane
 *
 * Returns 0 on success, negative on error.
 */
int swscale_process(void *ctx,
                    const uint8_t *const src_data[4],
                    const int src_stride[4],
                    uint8_t *const dst_data[4],
                    const int dst_stride[4]);

/*
 * swscale_destroy — Free a conversion context.
 */
void swscale_destroy(void *ctx);

#endif /* SWSCALE_API_H */
