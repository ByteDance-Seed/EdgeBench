from __future__ import absolute_import
import numpy as np
from ann_benchmarks.algorithms.base.module import BaseANN


class Custom(BaseANN):
    """Baseline custom algorithm. Agent should replace fit/query with
    a faster ANN implementation while keeping Recall@10 >= 0.95."""

    def __init__(self, metric):
        self._metric = metric
        self._data = None
        self.name = "custom"

    def fit(self, X):
        self._data = np.ascontiguousarray(X, dtype=np.float32)

    def query(self, v, n):
        v = np.asarray(v, dtype=np.float32)
        if self._metric == "euclidean":
            dists = np.linalg.norm(self._data - v, axis=1)
        elif self._metric == "angular":
            dot = self._data @ v
            dists = -dot / (np.linalg.norm(self._data, axis=1) * np.linalg.norm(v) + 1e-12)
        else:
            dists = np.linalg.norm(self._data - v, axis=1)
        return np.argsort(dists)[:n].tolist()
