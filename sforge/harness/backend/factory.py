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

"""Backend factory."""

from __future__ import annotations

from sforge.harness.backend.base import ContainerBackend


def create_backend(
    name: str = "docker",
    *,
    docker_client=None,
    k8s_namespace: str = "default",
    k8s_node_selector: dict[str, str] | None = None,
    k8s_image_registry: str = "",
    k8s_kubeconfig: str | None = None,
    e2b_template_map: dict[str, str] | None = None,
    e2b_sandbox_ttl: int | None = None,
) -> ContainerBackend:
    if name == "docker":
        from sforge.harness.backend.docker_backend import DockerBackend

        return DockerBackend(client=docker_client)
    elif name == "k8s":
        from sforge.harness.backend.k8s_backend import K8sBackend

        return K8sBackend(
            namespace=k8s_namespace,
            node_selector=k8s_node_selector,
            image_registry=k8s_image_registry,
            kubeconfig=k8s_kubeconfig,
        )
    elif name == "e2b":
        from sforge.harness.backend.e2b_backend import E2BBackend

        return E2BBackend(
            template_map=e2b_template_map,
            sandbox_ttl=e2b_sandbox_ttl,
        )
    supported = "docker, k8s, e2b"
    raise ValueError(f"Unknown backend: {name!r}. Must be one of: {supported}.")
