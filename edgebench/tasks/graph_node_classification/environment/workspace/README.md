# Task Package: Squirrel Heterophilous Graph Node Classification (gnc_heterophily_squirrel_01)

## 1. Task Overview

This task package evaluates an AI Agent's ability to model, implement, and iteratively improve on a real-world heterophilous graph node classification task. The dataset used is **Squirrel**, one of the most commonly used public benchmarks for heterophilous graph research in the WikipediaNetwork series. Nodes represent Wikipedia pages, edges represent links between pages, and labels represent the category each page belongs to. Unlike typical homophilous graphs, adjacent nodes in Squirrel frequently belong to different categories, so simple neighborhood smoothing strategies tend to be unstable.

This task requires the `solution` to produce node classification predictions under controlled input, balancing accuracy, calibration, runtime, and memory usage.

## 2. Why This Task Is Suitable for Long-Term Iteration

### 2.1 Heterophilous Graphs Are Inherently Challenging

- Neighbors do not naturally provide same-class information, and standard homophily assumptions easily break down.
- Graph structure can either provide gains or introduce noise, making aggregation strategies highly sensitive.
- The same method can show significant variance across different official splits, requiring implementations to be more robust.

### 2.2 Engineering Constraints Are Realistic and Verifiable

- The `solution` cannot directly read evaluation files under `data/`; it must work through the controlled input provided by the `runner`.
- The final score depends not only on classification metrics but also on time penalties and resource penalties.
- Both `QUICK_TEST` quick smoke testing and formal evaluation across 10 official splits are supported.

Therefore, this task can continuously test algorithm selection, code robustness, experiment reproducibility, and resource management.

## 3. Data Source and Research Alignment

### 3.1 Dataset and Task Package Are Fully Consistent

- Dataset actually used in the task package: **Squirrel**
- Data source type: WikipediaNetwork / Geom-GCN publicly preprocessed version
- Formal data directory in the task package: `data/squirrel/`
- Data preparation script: `tools/prepare_data.py`

The exported evaluation files include:

- `nodes_all.jsonl`: each line contains `node_id`, `feat`, `label`
- `graph.csv`: edge list with header `source,target`
- `train_split_00.jsonl` ~ `train_split_09.jsonl`
- `valid_split_00.jsonl` ~ `valid_split_09.jsonl`
- `test_split_00.jsonl` ~ `test_split_09.jsonl`
- `meta.json`
- `checksums.sha256`

### 3.2 Reference Research

1. **Geom-GCN: Geometric Graph Convolutional Networks**
   - Data and scenario alignment: includes Squirrel, emphasizing the limitations and improvement directions of conventional GNNs under heterophilous graph conditions.
   - Value: provides the `geom_gcn_preprocess=True` context and the 10 public splits used in this task.

2. **A Critical Look at the Evaluation of GNNs under Heterophily: Are We Really Making Progress?**
   - Evaluation protocol alignment: discusses evaluation protocols, implementation details, and comparison fairness issues in heterophilous graph node classification.
   - Value: supports the multi-split aggregation approach used in this task, rather than single-split scoring.

3. **Large Scale Learning on Non-Homophilous Graphs: New Benchmarks and Strong Simple Methods**
   - Task objective alignment: focuses on node classification on non-homophilous graphs and demonstrates the competitiveness of simple methods under rigorous protocols.
   - Value: supports providing the Agent with a lightweight but reasonable graph-structural baseline, rather than only allowing heavy-model approaches.

### 3.3 Scenario Configuration in the Task Package

- Dataset used: Squirrel
- Number of nodes: `5201`
- Number of edges: `217073`
- Feature dimension: `2089`
- Number of classes: `5`
- Evaluation protocol: **evaluate on each of the 10 official splits and average the results**
- Quick mode: when `QUICK_TEST=true`, only the first few splits are used, and each split's node list is truncated proportionally

### 3.4 Consistency and Differences with Paper Settings

Consistencies:

- The dataset name and formal evaluation data are fully consistent, both being Squirrel.
- The problem type is consistent, both being single-label node classification.
- Uses the commonly adopted public split settings from the Geom-GCN community, rather than custom random splits.

Differences:

- This task additionally computes `one_minus_ece`, encouraging prediction calibration.
- This task introduces time penalties and resource penalties to accommodate Agent automated evaluation needs.
- This task exposes graph structure through controlled input and restricts direct reading of underlying data files via audit hooks.

## 4. Directory Structure

```text
045_graph_node_classification/
├── README.md
├── config.yaml
├── runner.py
├── verifier.py
├── solution/
│   ├── problem.md
│   ├── runner.py
│   ├── solution.py
│   └── solution_template.py
├── tools/
│   ├── prepare_data.py
│   └── sanity_check.py
├── data/
│   └── squirrel/
└── outputs/
    └── result.json
```

## 5. Runner Workflow

The formal workflow of `runner.py` is as follows:

1. Read `config.yaml`.
2. Load `nodes_all.jsonl`, `graph.csv`, and `meta.json`.
3. Parse the train/valid/test file paths for the 10 splits according to the configuration.
4. For each split:
   - Construct `train_nodes`, `valid_nodes`, `test_nodes`
   - Mask only the current split's test node labels
   - Pass the graph structure and node information to `Solution.solve(input_data)` as a controlled dictionary
   - Record time, peak memory, and evaluation metrics
5. Average the results across the 10 splits to obtain the formal score.
6. Write detailed results to `outputs/result.json`.
7. Console outputs only a single line: `Score: ...`.

## 6. Input/Output Protocol

The core structure passed to `Solution.solve(input_data)` is as follows:

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
      "feat": [0.1, 0.2],
      "label": 3
    }
  ],
  "train_nodes": [0, 1],
  "valid_nodes": [2, 3],
  "test_nodes": [4, 5],
  "split_id": 0,
  "dataset_meta": {
    "dataset_name": "Squirrel",
    "num_classes": 5,
    "feature_dim": 2089,
    "geom_gcn_preprocess": true
  }
}
```

`Solution.solve(...)` must return:

```json
{
  "predictions": {
    "4": 1,
    "5": 3
  },
  "confidences": {
    "4": 0.81,
    "5": 0.66
  }
}
```

Where:

- `predictions` must cover all test nodes.
- Class IDs must be integers.
- `confidences` is optional; if provided, values must be in `[0, 1]`.

## 7. Scoring Details

### 7.1 Quality Metrics for a Single Split

- `macro_f1`
- `micro_f1`
- `balanced_accuracy`
- `ece`
- `one_minus_ece`

### 7.2 Composite Score for a Single Split

`overall_score = 0.4 * macro_f1 + 0.3 * micro_f1 + 0.2 * balanced_accuracy + 0.1 * one_minus_ece`

### 7.3 Final Score for a Single Split

`final_score = overall_score - time_penalty - resource_penalty`

Where:

- `time_penalty = time_penalty_coef * log(max(1e-6, total_solution_time_sec))`
- `resource_penalty` defaults to a linear peak memory penalty

### 7.4 Formal Score

Formal evaluation computes the metrics and `final_score` for each split individually, then averages these split results to produce the final output score.

## 8. How to Run

### 8.1 Prepare Data

```bash
python tools/prepare_data.py
python tools/sanity_check.py
```

### 8.2 Formal Evaluation

```bash
python solution/runner.py
```

### 8.3 Quick Verification

```bash
QUICK_TEST=true python solution/runner.py
```

### 8.4 Available Dependencies and Hardware Constraints

- Both the Agent and Judge environments have CPU-version PyTorch installed (`torch==2.2.2+cpu`), which can be used for CPU tensor computation, lightweight neural networks, or linear algebra implementations.
- Evaluation strictly prohibits calling GPU-related code or depending on GPU devices, including but not limited to `torch.cuda`, `.cuda()`, `.to("cuda")`, `torch.device("cuda")`, CUDA/MPS/XPU/ROCm, CuPy, PyCUDA, `numba.cuda`, JAX, or TensorFlow GPU backends.
- Formal evaluation hides GPU-visible devices and checks submitted code for common GPU APIs before execution; violations will be deemed invalid submissions.

## 9. Security and Fairness Constraints

- The `solution` is prohibited from directly reading evaluation files under `data/`.
- `runner.py` intercepts direct access to `nodes_all.jsonl`, `graph.csv`, split files, and `meta.json` via audit hooks.
- Graph structure is already exposed in a controlled manner through `input_data["graph"]["edges"]`; there is no need and no permission to bypass the interface to read underlying files.
- Formal evaluation should be conducted under offline conditions to avoid unfair comparisons from external service calls.

## 10. Sanity Check Requirements

`tools/sanity_check.py` checks:

- Whether all required files exist
- Whether `checksums.sha256` matches
- Whether `nodes_all.jsonl` has correct fields, dimensions, and node IDs
- Whether `meta.json` is consistent with the exported data scale
- Whether the 10 splits are pairwise non-overlapping and their union covers all nodes
- Whether `graph.csv` has the correct format and edge count

## 11. Known Limitations

- The Squirrel graph is not large in scale, but split sensitivity is high and single-split results are unstable, so multi-split averages must be used.
- Evaluation protocols for heterophilous graphs remain debated in the community, so priority should be given to maintaining consistency with public splits and public data.
- The provided `solution_template.py` is a lightweight baseline and does not represent the optimal method for this dataset.

## 12. Acceptance Checklist

At a minimum, perform the following checks:

1. `python tools/prepare_data.py`
2. `python tools/sanity_check.py`
3. `QUICK_TEST=true python solution/runner.py`
4. `python solution/runner.py`
5. Verify that `outputs/result.json` contains split-level results and aggregated results
