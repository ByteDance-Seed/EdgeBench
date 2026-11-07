"""Real FFmpeg regression. Set FFMPEG_BASELINE_SO to the compiled task shim.

Optionally set FFMPEG_PREVIOUS_BASELINE_SO for byte-for-byte legacy parity.
Run with python3 environment/check_baseline_padding.py from the task directory.
"""
import ctypes
import json
import mmap
import os
from pathlib import Path
import random
import sys
import unittest

WORKSPACE = Path(__file__).resolve().parent / "workspace"
sys.path.insert(0, str(WORKSPACE))
from pixel_formats import allocate_image, image_to_bytes, load_swscale_library

BYTE_POINTER = ctypes.POINTER(ctypes.c_uint8)
BASELINE = os.environ.get("FFMPEG_BASELINE_SO")
PREVIOUS = os.environ.get("FFMPEG_PREVIOUS_BASELINE_SO")


def convert(library, width, height, fmt, padding, color, negative_stride=False):
    """Keep only logical source pixels readable before a guard page."""
    bpp = 3 if fmt in (5, 6) else 4
    row_bytes = width * bpp
    stride = row_bytes + padding
    size = stride * height
    page = mmap.PAGESIZE
    readable = ((size + page - 1) // page) * page
    storage = mmap.mmap(-1, readable + page, prot=mmap.PROT_READ | mmap.PROT_WRITE)
    address = ctypes.addressof(ctypes.c_uint8.from_buffer(storage))
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mprotect.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_int]
    libc.mprotect.restype = ctypes.c_int
    if libc.mprotect(address + readable, page, 0):
        raise OSError(ctypes.get_errno(), "mprotect")
    first_row = address + readable - size
    rng = random.Random(width * 8191 + height * 97 + fmt)
    for y in range(height):
        data = bytes(rng.randrange(256) for _ in range(row_bytes))
        offset = first_row + y * stride
        ctypes.memmove(offset, data, len(data))
        if padding:
            tail = (color * ((padding + len(color) - 1) // len(color)))[:padding]
            ctypes.memmove(offset + row_bytes, tail, padding)
    src = (BYTE_POINTER * 4)(ctypes.cast(first_row, BYTE_POINTER))
    src_stride = (ctypes.c_int * 4)(stride)
    if negative_stride:
        src[0] = ctypes.cast(first_row + (height - 1) * stride, BYTE_POINTER)
        src_stride[0] = -stride
    dst, dst_stride, buffers = allocate_image(1, width, height)
    ctx = library.swscale_create(width, height, fmt, width, height, 1, 1)
    if not ctx:
        raise RuntimeError("swscale_create failed")
    try:
        code = library.swscale_process(ctx, src, src_stride, dst, dst_stride)
        if code:
            raise RuntimeError(f"swscale_process returned {code}")
        return [plane.hex() for plane in image_to_bytes(1, width, height, dst, dst_stride)]
    finally:
        library.swscale_destroy(ctx)


def isolated_conversion(library, *args, **kwargs):
    """A native fault becomes an assertion result instead of killing the suite."""
    import resource

    rd, wr = os.pipe()
    child = os.fork()
    if child == 0:
        os.close(rd)
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
        try:
            value = {"planes": convert(library, *args, **kwargs)}
        except Exception as exc:
            value = {"error": str(exc)}
        os.write(wr, json.dumps(value).encode())
        os._exit(0)
    os.close(wr)
    with os.fdopen(rd, "rb") as pipe:
        payload = pipe.read()
    _, status = os.waitpid(child, 0)
    if os.WIFSIGNALED(status):
        return {"signal": os.WTERMSIG(status)}
    if os.WEXITSTATUS(status):
        return {"exit_code": os.WEXITSTATUS(status)}
    return json.loads(payload)


@unittest.skipUnless(BASELINE and hasattr(os, "fork"), "requires FFMPEG_BASELINE_SO and POSIX")
class ReferencePaddingTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.library = load_swscale_library(BASELINE)
        cls.previous = load_swscale_library(PREVIOUS) if PREVIOUS else None

    def assert_success(self, result):
        self.assertIn("planes", result, result)
        return result["planes"]

    def test_tight_odd_inputs_and_padding_independence(self):
        for fmt in (5, 6, 7, 8):
            for width in (3, 7, 17, 129):
                for height in (1, 3, 7):
                    with self.subTest(fmt=fmt, width=width, height=height):
                        expected = self.assert_success(isolated_conversion(
                            self.library, width, height, fmt, 64, b"\0"
                        ))
                        for padding, color in ((0, b"\0"), (32, b"\xff\0\0"), (32, b"\0\0\xff")):
                            actual = self.assert_success(isolated_conversion(
                                self.library, width, height, fmt, padding, color
                            ))
                            self.assertEqual(actual, expected)

    def test_negative_stride(self):
        for fmt in (5, 6, 7, 8):
            with self.subTest(fmt=fmt):
                expected = self.assert_success(isolated_conversion(
                    self.library, 17, 3, fmt, 64, b"\0", negative_stride=True
                ))
                actual = self.assert_success(isolated_conversion(
                    self.library, 17, 3, fmt, 0, b"\0", negative_stride=True
                ))
                self.assertEqual(actual, expected)

    def test_legacy_even_width_parity(self):
        if not self.previous:
            self.skipTest("requires FFMPEG_PREVIOUS_BASELINE_SO")
        for fmt in (5, 6, 7, 8):
            for width in (4, 8, 18, 130):
                for height in (1, 3):
                    with self.subTest(fmt=fmt, width=width, height=height):
                        before = self.assert_success(isolated_conversion(
                            self.previous, width, height, fmt, 64, b"\0"
                        ))
                        after = self.assert_success(isolated_conversion(
                            self.library, width, height, fmt, 64, b"\0"
                        ))
                        self.assertEqual(after, before)

    def test_legacy_zero_padded_odd_parity(self):
        if not self.previous:
            self.skipTest("requires FFMPEG_PREVIOUS_BASELINE_SO")
        for fmt in (5, 6, 7, 8):
            for width in (3, 7, 17, 129):
                for height in (1, 3):
                    with self.subTest(fmt=fmt, width=width, height=height):
                        before = self.assert_success(isolated_conversion(
                            self.previous, width, height, fmt, 64, b"\0"
                        ))
                        after = self.assert_success(isolated_conversion(
                            self.library, width, height, fmt, 64, b"\0"
                        ))
                        self.assertEqual(after, before)


if __name__ == "__main__":
    unittest.main()
