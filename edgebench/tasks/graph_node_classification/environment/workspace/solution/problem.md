# Task: Squirrel Heterophilous Graph Node Classification

## 1. Background Description

You will act as an offline graph learning Agent, completing a single-label node classification task on the **Squirrel** dataset. Squirrel comes from WikipediaNetwork and is a typical **heterophilous graph**: many nodes tend to connect to neighbors of **different classes** rather than same-class neighbors. Therefore, simply relying on the homophily assumption that "most neighbors share the same class" typically does not yield stable performance.

This is not a tabular classification problem that looks at only local samples, but a **single-graph, transductive** node classification task. During evaluation, the entire graph, all node features, and the current split's train/validation/test node partitions are provided to you at once. You may legitimately use graph structure, node features, train/validation labels, and the feature information of unlabeled test nodes; however, you cannot bypass the interface to directly read underlying evaluation data files.

The approximate scale and meta-information of the dataset are as follows:

- Number of nodes: `5201`
- Number of edges: `217073`
- Feature dimension: `2089`
- Number of classes: `5`
- Evaluation protocol: `10` official splits

The final evaluation considers not only classification quality but also **confidence calibration**, **runtime**, and **peak memory**.

## 2. Task Objective

You need to implement the `Solution` class in `solution/solution.py`; if that file does not exist, the evaluator will fall back to `solution/solution_template.py`.

Your core objective is: for each official split's test nodes, output class predictions and provide reasonable confidence scores where possible, maximizing the average `final_score`.

The interface is as follows:

```python
class Solution:
    def __init__(self):
        pass

    def solve(self, input_data: dict) -> dict:
        pass
```

Notes:

- Formal evaluation will **re-instantiate** a new `Solution` object for each split.
- For a single split, `solve(input_data)` is called only once.
- You should not rely on memory state persisted across splits.

## 3. Evaluation Mechanism

The execution flow of `runner.py` for each split can be summarized as:

1. Load the full Squirrel graph, all node records, and the current split's train/validation/test partition.
2. Mask the true `label` of test nodes to `null` and construct `input_data`.
3. Instantiate your `Solution` and call `solve(input_data)` once.
4. Use `verifier.py` to compute classification and calibration metrics for that split.
5. Combine time penalties and resource penalties to obtain the `final_score` for that split.
6. Repeat the above process across all `10` official splits, and average the per-split scores as the formal result.

Therefore, your implementation needs to simultaneously satisfy:

- Handling the full single-graph input, not just a small batch.
- Maintaining robustness across different splits, not overfitting to a single partition.
- Making reasonable trade-offs among accuracy, calibration, speed, and memory.

## 4. Input

`runner.py` passes a dictionary to `Solution.solve(input_data)`. The input format for a single split is as follows:

```json
{
  "graph": {
    "edges": [[0, 1], [1, 2]],
    "num_nodes": 5201,
    "num_edges": 217073,
    "is_directed": false
  },
  "nodes": [
    {
      "node_id": 0,
      "feat": [0.1, 0.2, 0.3],
      "label": 4
    }
  ],
  "train_nodes": [0, 1, 2],
  "valid_nodes": [3, 4],
  "test_nodes": [5, 6],
  "split_id": 0,
  "dataset_meta": {
    "dataset_name": "Squirrel",
    "num_classes": 5,
    "feature_dim": 2089,
    "geom_gcn_preprocess": true
  }
}
```

Details:

- `input_data["graph"]["edges"]` directly provides the edge list for the entire graph, which you may legitimately use.
- `input_data["nodes"]` provides records for **all nodes**, not just the current split's subset.
- For test nodes in the current split, `label` is masked to `null`; training and validation set labels are visible.
- `train_nodes`, `valid_nodes`, `test_nodes` are the node ID lists for the current split.
- `split_id` indicates the official split number currently being evaluated.
- `dataset_meta` provides meta-information such as the number of classes, feature dimension, and preprocessing flags.
- This is a **single-label multi-class** classification task where each node corresponds to exactly one integer class ID.

## 5. Output

`Solution.solve` must return:

```json
{
  "predictions": {
    "5": 1,
    "6": 3
  }
}
```

It may also optionally return:

```json
{
  "predictions": {
    "5": 1,
    "6": 3
  },
  "confidences": {
    "5": 0.82,
    "6": 0.67
  }
}
```

Requirements:

- The keys of `predictions` must be test node IDs, which can be strings or values convertible to strings.
- The values of `predictions` must be integer class IDs.
- All test nodes in the current split should be covered.
- `confidences` is optional; if provided, values must be in `[0, 1]`.
- The returned result must be a JSON-serializable plain Python object.

Additional notes:

- `confidences` participates in the computation of the calibration metrics `ece` / `one_minus_ece`.
- If `confidences` is not provided, the evaluator will use a default confidence value, which typically hurts the calibration score.

## 6. Scoring Overview

`verifier.py` computes the following metrics for the current split:

- `macro_f1`
- `micro_f1`
- `balanced_accuracy`
- `one_minus_ece`

Where:

- `micro_f1` is equivalent to overall accuracy in this single-label multi-class setting.
- `one_minus_ece = max(0, 1 - ece)`, used to reward better confidence calibration.

The quality composite score is:

```text
overall_score =
    0.4 * macro_f1 +
    0.3 * micro_f1 +
    0.2 * balanced_accuracy +
    0.1 * one_minus_ece
```

The final score for each split is:

```text
time_penalty = 0.01 * log(max(1e-6, total_solution_time_sec))
resource_penalty = 0.001 * max(0, peak_memory_mb - 4096)
final_score = overall_score - time_penalty - resource_penalty
```

Where:

- `total_solution_time_sec` is the total runtime of `solve` for that split.
- `peak_memory_mb` is the peak memory recorded during evaluation of that split.
- The formal result is the average of `final_score` across the `10` official splits.

## 7. Constraints and Security

- The runtime environment provides CPU-version PyTorch (`torch==2.2.2+cpu`), which you can use in `solution/solution.py` for CPU tensors, linear algebra, and lightweight model computation.
- Calling GPU-related code or depending on any GPU device is strictly prohibited, including but not limited to `torch.cuda`, `.cuda()`, `.to("cuda")`, `torch.device("cuda")`, CUDA/MPS/XPU/ROCm, CuPy, PyCUDA, `numba.cuda`, JAX, or TensorFlow GPU backends.
- Formal evaluation hides GPU-visible devices and checks submitted code for common GPU APIs before execution; violations will be deemed invalid submissions.
- The `solution` is prohibited from directly reading underlying files in the `data/` directory; the evaluator audits file access to relevant files.
- `runner.py` already provides the graph structure and node data needed to complete the task through `input_data`.
- Design your implementation for an offline environment; do not depend on external networks, online APIs, or remote services.
- The only permitted evaluation command is `python runner.py`.
- `solution/runner.py` enforces formal full evaluation: it always uses all `10` official splits, does not accept additional command-line arguments, and does not enable `QUICK_TEST`.
- After each successful evaluation, `runner.py` refreshes `last_result.json` in the current directory, containing a sanitized metric summary suitable for continued optimization.
- The console should ultimately show only the `Score` output by `runner.py`.

## 8. Implementation Hints

- This task involves **heterophilous graph** node classification; do not assume "neighbors tend to share the same class as the target node."
- You may combine node features, graph structure, local label statistics, validation set signals, lightweight propagation methods, or non-GNN baselines.
- Since each split creates a new `Solution` instance, your implementation should be as robust, deterministic, and reproducible as possible.
- If you output `confidences`, ensure they match the prediction quality; poorly calibrated high-confidence predictions will lower `one_minus_ece`.
