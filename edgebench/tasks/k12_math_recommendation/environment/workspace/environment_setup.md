# Environment Setup Guide

This file describes the complete environment required for the Agent to perform this task, to be used together with `requirements.txt`.

## 1. Base Environment

| Item | Requirement |
|---|---|
| Python | 3.10 ~ 3.12 |
| OS | Linux / macOS / Windows all fine |
| CPU | 4 cores or more (for CPU training of deep models) |
| Memory | >= 16 GB |
| GPU | **Not required** |
| Disk | ~2 GB (including model cache) |
| Internet | **Not allowed** (all dependencies must be installed before the task starts) |

## 2. Installing Dependencies

**Recommended (pip)**:

```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install --upgrade pip
pip install -r requirements.txt
# The CPU build of PyTorch needs an extra wheel index:
pip install torch --index-url https://download.pytorch.org/whl/cpu
```

**Conda (optional)**:

```bash
conda create -n kt_agent python=3.11 -y
conda activate kt_agent
pip install -r requirements.txt
pip install torch --index-url https://download.pytorch.org/whl/cpu
```

## 3. Dependency Tiers

| Tier | Purpose | Required? |
|---|---|---|
| numpy / pandas / scikit-learn / scipy / networkx | Basic data processing, ML, graph algorithms | **Required** |
| torch (CPU) | Deep KT models such as DKT/SAKT/AKT | Recommended |
| lightgbm / xgboost | Feature-engineering baselines, PFA methods | Recommended |
| pymc / arviz | BKT Bayesian inference | Optional |
| gensim | Question/knowledge-point embeddings | Optional |
| tqdm / joblib / pyyaml | Logging, parallelism, config files | Suggested |

## 4. Verify Installation

```bash
python -c "import numpy, pandas, sklearn, scipy, networkx; print('core OK')"
python -c "import torch; print('torch', torch.__version__, 'cuda:', torch.cuda.is_available())"
# Expected output: cuda: False (CUDA not needed)
```

## 5. Specialized Software

This task **does not depend on any specialized software** (no MATLAB/SPSS/Tableau/BI tools, etc.). Everything can be done within the open-source Python ecosystem; no AI-interface software approval is needed.
