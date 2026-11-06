# Copyright (c) 2026 ByteDance Ltd. and/or its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Public checker semantics; real scalar-library qualification runs in its image."""
from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest


@pytest.fixture
def checker(monkeypatch, tmp_path):
    workspace = Path(__file__).resolve().parents[1] / "edgebench/tasks/ffmpeg_swscale_reimplementation/environment/workspace"
    monkeypatch.syspath_prepend(str(workspace))
    spec = importlib.util.spec_from_file_location("ffmpeg_dev_correctness", workspace / "verify_correctness.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    monkeypatch.setattr(module, "MEDIA_DIR", tmp_path)
    # Independent bytes, no FFmpeg process or native library needed by unit tests.
    (tmp_path / "gradient_4x4_gray8.raw").write_bytes(bytes(range(16)))
    monkeypatch.setattr(module.subprocess, "run", lambda *a, **k: pytest.fail("Unexpected CLI reference"))
    return module


class GrayLibrary:
    def __init__(self, *, value=None, mutate=False, result=0, create=True):
        self.value = value
        self.mutate = mutate
        self.result = result
        self.create = create
        self.destroyed = 0
        self.arguments = []

    def swscale_create(self, *args):
        self.arguments.append(args)
        self.width, self.height = args[3:5]
        return 1 if self.create else None

    def swscale_process(self, ctx, src, src_stride, dst, dst_stride):
        for y in range(self.height):
            for x in range(self.width):
                if self.mutate:
                    src[0][y * src_stride[0] + x] = 255
                dst[0][y * dst_stride[0] + x] = (
                    src[0][y * src_stride[0] + x] if self.value is None else self.value
                )
        return self.result

    def swscale_destroy(self, ctx):
        self.destroyed += 1


def workload(checker, algo):
    return dict(label="gray identity", src_fmt=checker.PIXFMT_GRAY8,
                dst_fmt=checker.PIXFMT_GRAY8, src_w=4, src_h=4,
                dst_w=4, dst_h=4, algo=algo)


@pytest.mark.parametrize("algo", [0, 1, 2])
def test_same_pixels_use_scalar_abi_for_each_algorithm(checker, algo):
    candidate, reference = GrayLibrary(), GrayLibrary()
    result = checker.run_workload(candidate, workload(checker, algo), reference)
    assert result["status"] == "pass"
    assert result["min_psnr"] == float("inf")
    assert reference.arguments == candidate.arguments
    assert reference.arguments[0][-1] == algo
    assert reference.destroyed == candidate.destroyed == 1


@pytest.mark.parametrize("mutate", [False, True])
def test_wrong_pixels_are_rejected_even_when_candidate_modifies_input(checker, mutate):
    result = checker.run_workload(GrayLibrary(value=255, mutate=mutate),
                                  workload(checker, 0), GrayLibrary())
    assert result["status"] == "fail"
    assert result["min_psnr"] < result["threshold"] == 60


@pytest.mark.parametrize("create,result,match,destroyed", [
    (False, 0, "Scalar reference swscale_create", 0),
    (True, -1, "Scalar reference swscale_process", 1),
])
def test_broken_reference_is_an_error_not_a_candidate_mismatch(checker, create, result, match, destroyed):
    candidate = GrayLibrary()
    reference = GrayLibrary(create=create, result=result)
    with pytest.raises(RuntimeError, match=match):
        checker.run_workload(candidate, workload(checker, 1), reference)
    assert reference.destroyed == destroyed
    assert candidate.arguments == []


def test_missing_scalar_baseline_does_not_fall_back_to_cli(checker, monkeypatch):
    monkeypatch.setattr(checker, "BASELINE_LIB", "/missing-scalar-baseline.so")
    with pytest.raises(OSError):
        checker.run_workload(GrayLibrary(), workload(checker, 1))
