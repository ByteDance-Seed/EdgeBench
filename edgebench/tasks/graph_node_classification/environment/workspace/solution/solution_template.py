from __future__ import annotations

from typing import Dict, List, Optional


class Solution:
    def __init__(self) -> None:
        self._num_classes = 0
        self._by_id: Dict[int, dict] = {}
        self._adj: Dict[int, List[int]] = {}
        self._labels: Dict[int, int] = {}
        self._centroids: List[Optional[List[float]]] = []
        self._priors: List[float] = []
        self._compat: List[List[float]] = []

    @staticmethod
    def _normalize(values: List[float]) -> List[float]:
        clipped = [float(v) if float(v) > 0.0 else 0.0 for v in values]
        total = sum(clipped)
        if total <= 1e-12:
            n = len(clipped)
            if n == 0:
                return []
            return [1.0 / float(n)] * n
        return [v / total for v in clipped]

    def _prepare_nodes(self, rows: List[dict], edges: List[List[int]]) -> None:
        self._by_id = {}
        for row in rows:
            try:
                nid = int(row.get("node_id"))
            except Exception:
                continue
            self._by_id[nid] = row

        self._adj = {nid: [] for nid in self._by_id.keys()}
        for edge in edges:
            if not isinstance(edge, list) or len(edge) != 2:
                continue
            try:
                u = int(edge[0])
                v = int(edge[1])
            except Exception:
                continue
            if u in self._adj:
                self._adj[u].append(v)
            if v in self._adj:
                self._adj[v].append(u)

    def _prepare_labels(self, labeled_ids: List[int]) -> None:
        self._labels = {}
        counts = [1.0] * self._num_classes
        sums: List[Optional[List[float]]] = [None] * self._num_classes
        class_counts = [0] * self._num_classes

        for nid in labeled_ids:
            row = self._by_id.get(nid)
            if row is None:
                continue
            label = row.get("label")
            feat = row.get("feat")
            if label is None or not isinstance(feat, list) or not feat:
                continue
            try:
                lb = int(label)
                vec = [float(x) for x in feat]
            except Exception:
                continue
            if lb < 0 or lb >= self._num_classes:
                continue

            self._labels[nid] = lb
            counts[lb] += 1.0
            class_counts[lb] += 1
            if sums[lb] is None:
                sums[lb] = [0.0] * len(vec)
            if len(sums[lb]) != len(vec):
                continue
            for i, value in enumerate(vec):
                sums[lb][i] += value

        total = sum(counts)
        self._priors = [c / total for c in counts]
        self._centroids = [None] * self._num_classes
        for lb in range(self._num_classes):
            if sums[lb] is None or class_counts[lb] <= 0:
                continue
            self._centroids[lb] = [value / float(class_counts[lb]) for value in sums[lb]]

    def _prepare_compatibility(self) -> None:
        compat = [[1.0 for _ in range(self._num_classes)] for _ in range(self._num_classes)]
        for nid, lb in self._labels.items():
            for nbr in self._adj.get(nid, []):
                nbr_lb = self._labels.get(nbr)
                if nbr_lb is None:
                    continue
                compat[lb][nbr_lb] += 1.0
        self._compat = [self._normalize(row) for row in compat]

    def _feature_probs(self, nid: int) -> List[float]:
        row = self._by_id.get(nid, {})
        feat = row.get("feat")
        if not isinstance(feat, list) or not feat:
            return list(self._priors)
        try:
            vec = [float(x) for x in feat]
        except Exception:
            return list(self._priors)

        scores: List[float] = []
        for lb in range(self._num_classes):
            centroid = self._centroids[lb]
            if centroid is None or len(centroid) != len(vec):
                scores.append(self._priors[lb])
                continue
            dist = 0.0
            for a, b in zip(vec, centroid):
                d = a - b
                dist += d * d
            mse = dist / float(len(vec))
            scores.append((self._priors[lb] + 1e-6) / (mse + 1e-6))
        return self._normalize(scores)

    def _graph_probs(self, nid: int, current: Dict[int, List[float]]) -> Optional[List[float]]:
        neighbors = self._adj.get(nid, [])
        if not neighbors:
            return None

        scores = [0.0] * self._num_classes
        used = 0
        for nbr in neighbors:
            nbr_probs = current.get(nbr)
            if nbr_probs is None:
                continue
            used += 1
            for target_class in range(self._num_classes):
                compat_row = self._compat[target_class]
                value = 0.0
                for observed_class, prob in enumerate(nbr_probs):
                    value += compat_row[observed_class] * prob
                scores[target_class] += value
        if used == 0:
            return None
        return self._normalize(scores)

    @staticmethod
    def _argmax(values: List[float]) -> int:
        best_idx = 0
        best_value = values[0] if values else 0.0
        for idx in range(1, len(values)):
            if values[idx] > best_value:
                best_idx = idx
                best_value = values[idx]
        return best_idx

    def solve(self, input_data: Dict) -> Dict:
        rows = input_data.get("nodes", [])
        graph = input_data.get("graph", {})
        edges = graph.get("edges", []) if isinstance(graph, dict) else []
        meta = input_data.get("dataset_meta", {})

        self._num_classes = int(meta.get("num_classes", 5))
        train_nodes = [int(x) for x in input_data.get("train_nodes", [])]
        valid_nodes = [int(x) for x in input_data.get("valid_nodes", [])]
        test_nodes = [int(x) for x in input_data.get("test_nodes", [])]
        labeled_ids = train_nodes + valid_nodes

        self._prepare_nodes(rows, edges)
        self._prepare_labels(labeled_ids)
        self._prepare_compatibility()

        current: Dict[int, List[float]] = {}
        for nid, label in self._labels.items():
            probs = [0.0] * self._num_classes
            probs[label] = 1.0
            current[nid] = probs

        feature_cache: Dict[int, List[float]] = {}
        for nid in test_nodes:
            probs = self._feature_probs(nid)
            feature_cache[nid] = probs
            current[nid] = list(probs)

        feature_weight = 0.6
        graph_weight = 0.4
        for _ in range(6):
            updated = dict(current)
            for nid in test_nodes:
                feat_probs = feature_cache[nid]
                graph_probs = self._graph_probs(nid, current)
                if graph_probs is None:
                    updated[nid] = feat_probs
                    continue
                mixed = [
                    feature_weight * feat_probs[c] + graph_weight * graph_probs[c]
                    for c in range(self._num_classes)
                ]
                updated[nid] = self._normalize(mixed)
            current = updated

        predictions: Dict[str, int] = {}
        confidences: Dict[str, float] = {}
        for nid in test_nodes:
            probs = current.get(nid) or feature_cache.get(nid) or list(self._priors)
            pred = self._argmax(probs)
            predictions[str(nid)] = int(pred)
            confidences[str(nid)] = max(0.0, min(1.0, float(max(probs) if probs else 0.0)))

        return {"predictions": predictions, "confidences": confidences}
