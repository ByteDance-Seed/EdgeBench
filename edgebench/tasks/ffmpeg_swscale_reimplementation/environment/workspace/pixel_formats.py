"""
pixel_formats.py — Shared pixel-format metadata used by agent dev tools and the
verifier.  Keeps format constants, plane counts, and buffer-size helpers in one
place so nothing drifts.
"""

from __future__ import annotations

import ctypes
from dataclasses import dataclass

# ── Constants (must match swscale_api.h) ─────────────────────────────────────

PIXFMT_YUV420P = 0
PIXFMT_YUV422P = 1
PIXFMT_YUV444P = 2
PIXFMT_NV12 = 3
PIXFMT_NV21 = 4
PIXFMT_RGB24 = 5
PIXFMT_BGR24 = 6
PIXFMT_RGBA = 7
PIXFMT_BGRA = 8
PIXFMT_GRAY8 = 9
PIXFMT_COUNT = 10

ALGO_NEAREST = 0
ALGO_BILINEAR = 1
ALGO_BICUBIC = 2
ALGO_COUNT = 3

PIXFMT_NAMES: dict[int, str] = {
    PIXFMT_YUV420P: "yuv420p",
    PIXFMT_YUV422P: "yuv422p",
    PIXFMT_YUV444P: "yuv444p",
    PIXFMT_NV12: "nv12",
    PIXFMT_NV21: "nv21",
    PIXFMT_RGB24: "rgb24",
    PIXFMT_BGR24: "bgr24",
    PIXFMT_RGBA: "rgba",
    PIXFMT_BGRA: "bgra",
    PIXFMT_GRAY8: "gray8",
}

PIXFMT_FROM_NAME: dict[str, int] = {v: k for k, v in PIXFMT_NAMES.items()}

ALGO_NAMES: dict[int, str] = {
    ALGO_NEAREST: "nearest",
    ALGO_BILINEAR: "bilinear",
    ALGO_BICUBIC: "bicubic",
}

ALGO_FROM_NAME: dict[str, int] = {v: k for k, v in ALGO_NAMES.items()}

# FFmpeg pixel format names used by the ffmpeg CLI (-pix_fmt flag).
FFMPEG_PIXFMT: dict[int, str] = {
    PIXFMT_YUV420P: "yuv420p",
    PIXFMT_YUV422P: "yuv422p",
    PIXFMT_YUV444P: "yuv444p",
    PIXFMT_NV12: "nv12",
    PIXFMT_NV21: "nv21",
    PIXFMT_RGB24: "rgb24",
    PIXFMT_BGR24: "bgr24",
    PIXFMT_RGBA: "rgba",
    PIXFMT_BGRA: "bgra",
    PIXFMT_GRAY8: "gray8",
}


# ── Plane geometry ───────────────────────────────────────────────────────────


@dataclass(frozen=True)
class PlaneDesc:
    """Width and height divisors + bytes-per-pixel for one plane."""

    w_shift: int  # log2 horizontal sub-sampling (0 = full, 1 = half)
    h_shift: int  # log2 vertical sub-sampling
    bpp: int  # bytes per pixel in this plane


@dataclass(frozen=True)
class PixFmtDesc:
    """Describes the planar layout of a pixel format."""

    name: str
    num_planes: int
    planes: tuple[PlaneDesc, ...]  # length == num_planes

    def plane_width(self, plane: int, width: int) -> int:
        return -((-width) >> self.planes[plane].w_shift)  # ceil division

    def plane_height(self, plane: int, height: int) -> int:
        return -((-height) >> self.planes[plane].h_shift)

    def plane_linesize(self, plane: int, width: int, align: int = 1) -> int:
        pw = self.plane_width(plane, width) * self.planes[plane].bpp
        if align > 1:
            pw = (pw + align - 1) & ~(align - 1)
        return pw

    def plane_size(self, plane: int, width: int, height: int, align: int = 1) -> int:
        return self.plane_linesize(plane, width, align) * self.plane_height(
            plane, height
        )

    def total_size(self, width: int, height: int, align: int = 1) -> int:
        return sum(
            self.plane_size(i, width, height, align) for i in range(self.num_planes)
        )


# Format descriptors — indexed by SWS_PIXFMT_* constant.
PIXFMT_DESCS: dict[int, PixFmtDesc] = {
    PIXFMT_YUV420P: PixFmtDesc(
        "yuv420p",
        3,
        (
            PlaneDesc(0, 0, 1),  # Y
            PlaneDesc(1, 1, 1),  # U
            PlaneDesc(1, 1, 1),  # V
        ),
    ),
    PIXFMT_YUV422P: PixFmtDesc(
        "yuv422p",
        3,
        (
            PlaneDesc(0, 0, 1),
            PlaneDesc(1, 0, 1),
            PlaneDesc(1, 0, 1),
        ),
    ),
    PIXFMT_YUV444P: PixFmtDesc(
        "yuv444p",
        3,
        (
            PlaneDesc(0, 0, 1),
            PlaneDesc(0, 0, 1),
            PlaneDesc(0, 0, 1),
        ),
    ),
    PIXFMT_NV12: PixFmtDesc(
        "nv12",
        2,
        (
            PlaneDesc(0, 0, 1),  # Y: full width, full height, 1 byte/sample
            PlaneDesc(
                1, 1, 2
            ),  # UV interleaved: half-width chroma pairs, half-height, 2 bytes/pair
        ),
    ),
    PIXFMT_NV21: PixFmtDesc(
        "nv21",
        2,
        (
            PlaneDesc(0, 0, 1),  # Y
            PlaneDesc(1, 1, 2),  # VU interleaved: same geometry as NV12
        ),
    ),
    PIXFMT_RGB24: PixFmtDesc("rgb24", 1, (PlaneDesc(0, 0, 3),)),
    PIXFMT_BGR24: PixFmtDesc("bgr24", 1, (PlaneDesc(0, 0, 3),)),
    PIXFMT_RGBA: PixFmtDesc("rgba", 1, (PlaneDesc(0, 0, 4),)),
    PIXFMT_BGRA: PixFmtDesc("bgra", 1, (PlaneDesc(0, 0, 4),)),
    PIXFMT_GRAY8: PixFmtDesc("gray8", 1, (PlaneDesc(0, 0, 1),)),
}


# ── ctypes helpers for loading candidate / baseline .so ──────────────────────


def _arr4_int():
    return ctypes.c_int * 4


def _arr4_ptr():
    return ctypes.POINTER(ctypes.c_uint8) * 4


def load_swscale_library(path: str):
    """Load a shared library implementing the swscale_api.h interface.

    Returns a ctypes CDLL handle with function signatures set up.
    """
    lib = ctypes.CDLL(path)

    # swscale_create
    lib.swscale_create.argtypes = [
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,  # src_w, src_h, src_fmt
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,  # dst_w, dst_h, dst_fmt
        ctypes.c_int,  # algo
    ]
    lib.swscale_create.restype = ctypes.c_void_p

    # swscale_process
    lib.swscale_process.argtypes = [
        ctypes.c_void_p,  # ctx
        _arr4_ptr(),  # src_data
        _arr4_int(),  # src_stride
        _arr4_ptr(),  # dst_data
        _arr4_int(),  # dst_stride
    ]
    lib.swscale_process.restype = ctypes.c_int

    # swscale_destroy
    lib.swscale_destroy.argtypes = [ctypes.c_void_p]
    lib.swscale_destroy.restype = None

    return lib


def allocate_image(fmt: int, width: int, height: int, align: int = 32):
    """Allocate aligned buffers for an image, returning (data_arr, stride_arr, bufs).

    data_arr and stride_arr are ctypes arrays ready to pass to swscale_process.
    bufs is a list of ctypes byte arrays (must be kept alive).
    """
    desc = PIXFMT_DESCS[fmt]
    data_arr = _arr4_ptr()()
    stride_arr = _arr4_int()()
    bufs = []

    for i in range(4):
        if i < desc.num_planes:
            ls = desc.plane_linesize(i, width, align)
            h = desc.plane_height(i, height)
            buf = (ctypes.c_uint8 * (ls * h))()
            bufs.append(buf)
            data_arr[i] = ctypes.cast(buf, ctypes.POINTER(ctypes.c_uint8))
            stride_arr[i] = ls
        else:
            data_arr[i] = ctypes.cast(
                ctypes.c_void_p(None), ctypes.POINTER(ctypes.c_uint8)
            )
            stride_arr[i] = 0
            bufs.append(None)

    return data_arr, stride_arr, bufs


def image_to_bytes(
    fmt: int, width: int, height: int, data_arr, stride_arr
) -> list[bytes]:
    """Extract plane pixel data (without stride padding) as a list of bytes objects."""
    desc = PIXFMT_DESCS[fmt]
    planes = []
    for i in range(desc.num_planes):
        pw = desc.plane_width(i, width) * desc.planes[i].bpp
        ph = desc.plane_height(i, height)
        ls = stride_arr[i]
        raw = ctypes.cast(data_arr[i], ctypes.POINTER(ctypes.c_uint8 * (ls * ph)))[0]
        rows = []
        for r in range(ph):
            rows.append(bytes(raw[r * ls : r * ls + pw]))
        planes.append(b"".join(rows))
    return planes


def fill_image_from_bytes(
    fmt: int, width: int, height: int, data_arr, stride_arr, plane_bytes: list[bytes]
) -> None:
    """Write plane pixel data into pre-allocated ctypes buffers."""
    desc = PIXFMT_DESCS[fmt]
    for i in range(desc.num_planes):
        pw = desc.plane_width(i, width) * desc.planes[i].bpp
        ph = desc.plane_height(i, height)
        ls = stride_arr[i]
        raw = ctypes.cast(data_arr[i], ctypes.POINTER(ctypes.c_uint8 * (ls * ph)))[0]
        src = plane_bytes[i]
        for r in range(ph):
            raw[r * ls : r * ls + pw] = src[r * pw : (r + 1) * pw]
