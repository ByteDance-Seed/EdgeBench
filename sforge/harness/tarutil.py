# Copyright (c) 2026 ByteDance Ltd. and/or its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Safe tar extraction on every supported Python (``filter=`` needs 3.11.4+)."""

from __future__ import annotations

import tarfile
from pathlib import Path


def safe_extractall(tar: tarfile.TarFile, dest: Path) -> None:
    """Extract *tar* into *dest*, refusing members that escape it."""
    if hasattr(tarfile, "data_filter"):
        tar.extractall(dest, filter="data")
        return
    root = dest.resolve()
    for member in tar.getmembers():
        target = (root / member.name).resolve()
        if root != target and root not in target.parents:
            raise tarfile.TarError(f"unsafe path in archive: {member.name}")
        if member.issym() or member.islnk():
            link = (target.parent / member.linkname).resolve()
            if root != link and root not in link.parents:
                raise tarfile.TarError(f"unsafe link in archive: {member.name}")
        if member.isdev():
            raise tarfile.TarError(f"device file in archive: {member.name}")
    tar.extractall(dest)
