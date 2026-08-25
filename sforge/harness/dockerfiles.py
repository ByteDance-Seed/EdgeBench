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

"""Dockerfile templates for SForge images (base, work, judge)."""

from __future__ import annotations

# --- Base Dockerfile: official image + common tools ---
_DOCKERFILE_BASE = """\
FROM --platform={platform} {official_image}
{user_directive}\
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
{env_directives}
RUN {apt_mirror_prepare}apt-get update && apt-get install -y --no-install-recommends \\
    {packages} sudo \\
    && rm -rf /var/lib/apt/lists/* \\
{apt_mirror_restore}\
    && useradd -m -s /bin/bash agent \\
    && echo 'agent ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \\
    && git config --global safe.directory '*'
{pip_directive}{post_install_directive}
"""

# --- Work Dockerfile: agent workspace (skeleton + docs, NO tests) ---
_DOCKERFILE_WORK = """\
FROM --platform={platform} {base_image}
{env_directives}
COPY setup_workspace.sh /tmp/setup_workspace.sh
RUN chmod +x /tmp/setup_workspace.sh && /bin/bash /tmp/setup_workspace.sh \\
    && chown -R agent:agent {cwd}
USER agent
WORKDIR {cwd}
"""

# --- Judge Dockerfile: grading environment (skeleton + tests, NO docs) ---
_DOCKERFILE_JUDGE = """\
FROM --platform={platform} {base_image}
{env_directives}
COPY setup_judge.sh /tmp/setup_judge.sh
RUN chmod +x /tmp/setup_judge.sh && /bin/bash /tmp/setup_judge.sh
WORKDIR {cwd}
"""


def get_dockerfile_base(
    base_image_spec: dict,
    platform: str,
    env_directives: str = "",
    apt_mirror_url: str | None = None,
) -> str:
    """Generate a base Dockerfile from a base image spec dict."""
    spec = base_image_spec
    packages = " \\\n    ".join(spec["extra_packages"])
    user_directive = spec.get("user_directive", "")
    post_install_directive = spec.get("post_install_directive", "")

    apt_mirror_prepare = ""
    apt_mirror_restore = ""
    if apt_mirror_url:
        url = apt_mirror_url.rstrip("/")
        apt_mirror_prepare = (
            "rm -rf /tmp/sforge-apt-original && "
            "mkdir -p /tmp/sforge-apt-original && "
            "if [ -e /etc/apt/sources.list ]; then "
            "cp -a /etc/apt/sources.list /tmp/sforge-apt-original/; fi && "
            "if [ -d /etc/apt/sources.list.d ]; then "
            "cp -a /etc/apt/sources.list.d /tmp/sforge-apt-original/; fi && "
            "find /etc/apt -maxdepth 2 -type f "
            "\\( -name '*.list' -o -name '*.sources' \\) "
            "-exec sed -Ei "
            f"-e 's#https?://deb.debian.org#{url}#g' "
            f"-e 's#https?://archive.ubuntu.com#{url}#g' "
            f"-e 's#https?://security.ubuntu.com#{url}#g' "
            "{} + && "
        )
        apt_mirror_restore = (
            "    && rm -f /etc/apt/sources.list \\\n"
            "    && rm -rf /etc/apt/sources.list.d \\\n"
            "    && if [ -e /tmp/sforge-apt-original/sources.list ]; then "
            "mv /tmp/sforge-apt-original/sources.list /etc/apt/; fi \\\n"
            "    && if [ -d /tmp/sforge-apt-original/sources.list.d ]; then "
            "mv /tmp/sforge-apt-original/sources.list.d /etc/apt/; "
            "else mkdir -p /etc/apt/sources.list.d; fi \\\n"
            "    && rm -rf /tmp/sforge-apt-original \\\n"
        )

    pip_packages = spec.get("pip_packages", [])
    pip_directive = ""
    if pip_packages:
        pkgs = " ".join(pip_packages)
        pip_directive = f"RUN pip install --no-cache-dir {pkgs}\n"

    return _DOCKERFILE_BASE.format(
        platform=platform,
        official_image=spec["official_image"],
        user_directive=user_directive,
        env_directives=env_directives,
        apt_mirror_prepare=apt_mirror_prepare,
        apt_mirror_restore=apt_mirror_restore,
        packages=packages,
        pip_directive=pip_directive,
        post_install_directive=post_install_directive,
    )


def _secret_mount_prefix(secrets: dict[str, str]) -> tuple[str, str]:
    """Build the --mount and export fragments for BuildKit secret mounts.

    Returns (mount_clause, export_clause) to splice into a RUN instruction.
    Both are empty strings when *secrets* is empty.
    """
    if not secrets:
        return "", ""
    mounts = " ".join(f"--mount=type=secret,id={sid}" for sid in secrets)
    exports = " && ".join(
        f"export SFORGE_{sid.upper()}=$(cat /run/secrets/{sid} 2>/dev/null)"
        for sid in secrets
    )
    return mounts + " ", exports + " && "


def get_dockerfile_work(
    platform: str,
    base_image: str,
    cwd: str,
    env_directives: str = "",
    secrets: dict[str, str] | None = None,
) -> str:
    """Generate a work Dockerfile (agent workspace)."""
    mount_clause, export_clause = _secret_mount_prefix(secrets or {})
    return (
        f"FROM --platform={platform} {base_image}\n"
        f"{env_directives}\n"
        f"COPY setup_workspace.sh /tmp/setup_workspace.sh\n"
        f"RUN {mount_clause}{export_clause}"
        f"chmod +x /tmp/setup_workspace.sh && /bin/bash /tmp/setup_workspace.sh \\\n"
        f"    && chown -R agent:agent {cwd}\n"
        f"USER agent\n"
        f"WORKDIR {cwd}\n"
    )


def get_dockerfile_judge(
    platform: str,
    base_image: str,
    cwd: str,
    env_directives: str = "",
    secrets: dict[str, str] | None = None,
) -> str:
    """Generate a judge Dockerfile (grading environment)."""
    mount_clause, export_clause = _secret_mount_prefix(secrets or {})
    return (
        f"FROM --platform={platform} {base_image}\n"
        f"{env_directives}\n"
        f"COPY setup_judge.sh /tmp/setup_judge.sh\n"
        f"RUN {mount_clause}{export_clause}"
        f"chmod +x /tmp/setup_judge.sh && /bin/bash /tmp/setup_judge.sh\n"
        f"WORKDIR {cwd}\n"
    )
