<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.png">
    <img src="assets/logo.jpg" alt="ByteDance Seed" width="420">
  </picture>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/title-dark.svg">
    <img src="assets/title.svg" alt="EdgeBench" width="280">
  </picture>
</p>

<br>

<!-- <p align="center">
  <strong>Measuring How AI Agents Learn from Real-World Environments</strong>
</p>

<p align="center">
  134 real-world tasks &nbsp;|&nbsp; 51 open-source &nbsp;|&nbsp; 6 capability categories &nbsp;|&nbsp; 38,000+ hours of agent interaction
</p> -->

<p align="center">
  <a href="https://edge-bench.org/"><img src="https://img.shields.io/badge/Project-edge--bench.org-blue" alt="Project"></a>
  <a href="https://edge-bench.org/paper.pdf"><img src="https://img.shields.io/badge/Tech%20Report-PDF-red?logo=adobeacrobatreader" alt="Tech Report"></a>
  <a href="https://huggingface.co/datasets/ByteDance-Seed/EdgeBench"><img src="https://img.shields.io/badge/%F0%9F%A4%97%20HuggingFace-Dataset-yellow" alt="Dataset"></a>
  <a href="https://bytedance-seed.github.io/EdgeBench/"><img src="https://img.shields.io/badge/Docs-SForge%20Harness-purple" alt="Docs"></a>
</p>

---

## Overview

**EdgeBench** is a benchmark of **134 real-world tasks** for evaluating how autonomous AI agents *learn from real-world environments*. Instead of measuring one-shot performance, EdgeBench places agents in executable task environments with realistic, multi-level feedback and lets them iterate for **12+ hours** per task — tracking the full trajectory of improvement, not just the final score. We publicly release **51 tasks** along with the full evaluation framework.

Analyzing ~38,000 hours of agent interaction on all 134 tasks, we find that **performance follows a log-sigmoid scaling law as a function of interaction time** ($R^2 = 0.998$). See the [tech report](https://edge-bench.org/paper.pdf) for details.

<p align="center">
  <img src="assets/fig_full_136_curve_fit_side_by_side.png" alt="Log-sigmoid scaling fit across 134 tasks" width="800">
</p>

## Leaderboard

### Full Benchmark (134 tasks)

| Model | @2h | @4h | @6h | @8h | @10h | **@12h** |
|:------|:---:|:---:|:---:|:---:|:----:|:--------:|
| **Claude Opus 4.8** | **39.0** | **45.7** | **48.1** | **49.8** | **50.9** | **51.3** |
| GPT-5.5 | 36.8 | 42.1 | 44.5 | 46.3 | 47.6 | 48.4 |
| GPT-5.4 | 29.7 | 34.0 | 36.5 | 38.0 | 38.9 | 39.3 |
| GLM-5.1 | 26.0 | 30.4 | 32.9 | 34.9 | 36.5 | 37.4 |
| DS-V4-Pro | 23.3 | 27.1 | 29.0 | 29.9 | 30.9 | 31.0 |

<details>
<summary><b>Category Scores @12h (134 tasks)</b></summary>

| Model | Scientific & ML | Systems & SE | Optimization | Knowledge | Formal | Games |
|:------|:-------:|:----:|:------------:|:---------:|:----:|:-----:|
| **Claude Opus 4.8** | **48.5** | **67.4** | **36.5** | **47.0** | **55.0** | **39.3** |
| GPT-5.5 | 44.3 | 65.0 | 33.6 | 45.7 | 50.0 | 39.1 |
| GPT-5.4 | 33.5 | 54.1 | 27.9 | 38.8 | 40.8 | 29.0 |
| GLM-5.1 | 33.8 | 50.9 | 26.4 | 43.5 | 24.6 | 29.3 |
| DS-V4-Pro | 30.0 | 43.0 | 21.5 | 37.0 | 14.1 | 16.9 |

</details>

### Open-Source Subset (51 tasks)

| Model | @2h | @4h | @6h | @8h | @10h | **@12h** |
|:------|:---:|:---:|:---:|:---:|:----:|:--------:|
| **Claude Opus 4.8** | **33.2** | **38.4** | **40.6** | **41.9** | **42.9** | **43.6** |
| GPT-5.5 | 31.0 | 35.7 | 37.9 | 39.9 | 41.7 | 42.7 |
| GPT-5.4 | 25.1 | 28.3 | 30.4 | 32.2 | 33.4 | 34.3 |
| GLM-5.1 | 21.4 | 24.2 | 26.7 | 28.2 | 29.1 | 30.3 |
| DS-V4-Pro | 17.1 | 21.0 | 22.8 | 23.5 | 24.6 | 25.1 |

<details>
<summary><b>Category Scores @12h (51 tasks)</b></summary>

| Model | Scientific & ML | Systems & SE | Optimization | Knowledge | Formal | Games |
|:------|:-------:|:----:|:------------:|:---------:|:----:|:-----:|
| **Claude Opus 4.8** | **31.8** | **62.0** | **38.2** | **38.7** | 40.9 | **39.3** |
| GPT-5.5 | 27.7 | 60.5 | 32.3 | 38.4 | **49.0** | 39.1 |
| GPT-5.4 | 25.7 | 50.1 | 29.9 | 31.6 | 30.2 | 29.0 |
| GLM-5.1 | 25.7 | 43.6 | 26.7 | 31.0 | 19.9 | 29.3 |
| DS-V4-Pro | 23.8 | 37.6 | 24.1 | 33.2 | 12.7 | 16.9 |

</details>

<details>
<summary><b>Per-Task Scores by Time Budget (51 tasks)</b></summary>

Each model cell reports scores at `@2h / @4h / @6h / @8h / @10h / @12h`. Missing valid results are shown as `—`.

| Task | Category | Opus 4.8 | GPT-5.5 | GPT-5.4 | GLM-5.1 | DS-V4-Pro |
|:-----|:-------|:---------|:--------|:--------|:--------|:----------|
| bipedalwalker_locomotion_rl | Scientific & ML | 16.7/20.8/22.4/23.3/23.3/23.3 | 14.7/14.9/15.2/15.2/16.0/21.0 | 13.9/13.9/13.9/14.5/14.5/17.5 | 13.9/20.3/21.5/22.5/22.5/22.5 | 8.9/14.8/17.6/20.4/20.4/20.6 |
| capecod_plume_reconstruction | Scientific & ML | 10.0/15.3/17.3/18.0/18.2/19.9 | 11.7/13.7/15.1/16.2/16.4/16.4 | 10.7/11.5/12.2/12.5/12.5/12.6 | 8.6/9.0/9.2/10.3/10.5/10.9 | 7.9/8.5/8.5/8.8/8.8/8.8 |
| dabic_gravity_inversion | Scientific & ML | 9.5/15.2/15.7/17.4/17.5/17.5 | 15.9/16.2/16.7/17.0/17.2/17.3 | 14.6/14.6/15.5/15.5/15.0/15.0 | 9.2/13.7/16.0/16.5/16.5/17.1 | —/12.7/12.7/12.7/13.0/13.8 |
| graph_node_classification | Scientific & ML | 59.4/62.7/65.0/65.6/66.5/66.6 | 54.7/55.1/55.1/55.3/55.9/56.0 | 54.9/56.2/56.5/56.9/57.5/57.6 | 49.4/52.3/52.3/52.3/52.3/52.3 | 46.0/48.2/49.2/51.3/51.7/51.8 |
| ann_vector_search_qps | Systems & SE | 26.2/57.0/58.6/58.7/59.4/59.7 | 22.3/34.3/35.1/36.0/40.0/40.7 | 27.5/30.2/44.5/45.2/49.7/50.2 | 6.7/24.4/25.6/25.6/26.1/38.3 | 9.4/19.6/22.4/22.8/23.8/23.8 |
| arc_compiler_runtime | Systems & SE | 49.3/52.0/52.0/52.0/52.0/52.0 | 55.5/56.5/60.9/70.3/71.0/72.4 | 45.1/46.5/49.8/49.8/50.0/50.0 | 47.7/48.0/48.4/48.7/48.7/48.7 | 40.3/41.7/44.2/44.2/44.2/44.2 |
| exchange_core_throughput | Systems & SE | 40.7/57.0/58.5/58.9/59.7/59.7 | 15.4/37.2/39.9/44.3/51.3/53.2 | 14.3/40.8/41.0/45.2/46.4/47.3 | 29.2/43.7/46.5/48.6/50.3/52.6 | 32.9/33.8/45.0/47.7/48.4/48.6 |
| ffmpeg_swscale_reimplementation | Systems & SE | 9.9/17.6/19.8/20.9/21.1/21.1 | 8.8/14.3/15.1/15.3/15.3/15.3 | 5.4/8.5/9.4/11.6/13.3/13.9 | 0.3/0.3/0.4/2.2/2.2/2.2 | 0.1/1.9/2.0/3.8/3.8/3.8 |
| git_rewrite_in_zig | Systems & SE | 22.0/22.8/22.8/22.8/23.1/23.1 | 16.1/16.9/17.7/18.2/18.2/18.4 | 9.6/13.8/14.0/14.2/14.2/15.4 | 12.0/20.2/23.3/23.4/23.4/23.5 | 8.5/13.5/16.0/17.6/17.8/17.9 |
| integer_compression_codec | Systems & SE | 69.4/69.7/74.8/74.9/75.2/75.3 | 61.1/67.6/73.9/73.9/74.3/74.4 | 38.6/40.9/41.2/42.2/42.2/42.3 | 23.5/27.3/28.5/28.7/28.9/28.9 | 15.9/16.0/16.2/16.2/16.2/16.2 |
| juliet_vulnerability_analyzer | Systems & SE | 71.9/74.9/75.4/75.6/75.6/75.6 | 81.0/83.2/85.4/86.8/87.4/89.8 | 52.9/66.1/74.3/76.0/76.8/77.2 | 59.3/60.7/62.8/63.5/63.5/63.5 | 46.8/63.1/66.1/66.2/66.2/66.2 |
| rust_multicrate_reconstruction | Systems & SE | —/—/—/—/—/— | 27.5/42.6/53.1/54.9/57.8/57.8 | 16.7/19.9/21.3/21.4/21.4/21.4 | 24.8/24.8/25.2/25.2/37.5/38.5 | 20.5/21.7/22.7/23.1/23.5/23.6 |
| schemathesis_config_modernization | Systems & SE | 82.5/85.0/86.1/87.4/87.4/87.7 | 79.1/82.2/82.9/83.2/83.6/84.0 | 67.2/68.8/68.8/71.7/71.7/71.9 | 58.3/59.7/60.4/61.2/61.7/61.7 | 54.3/54.3/55.3/55.3/55.3/55.6 |
| schemathesis_datagen_pipeline | Systems & SE | 68.0/70.2/70.2/70.2/70.2/70.2 | 54.6/54.6/56.7/56.7/56.7/56.7 | 56.6/56.6/56.6/56.6/56.6/56.6 | 62.1/64.2/64.2/67.0/67.0/67.0 | 47.9/50.1/52.3/52.3/52.3/52.3 |
| schemathesis_reporting_observability | Systems & SE | 73.9/75.6/76.2/76.2/76.2/76.2 | 76.6/76.6/76.6/76.6/77.1/77.1 | 70.0/73.7/74.7/75.7/76.2/76.2 | 61.9/61.9/61.9/61.9/61.9/61.9 | 59.4/62.4/63.0/63.0/65.0/65.0 |
| vliw_kernel_optimization | Systems & SE | 74.0/76.0/77.7/79.5/79.6/80.9 | 71.6/75.7/77.1/79.5/83.1/85.6 | 75.7/77.0/77.2/78.7/79.1/79.1 | 5.6/9.5/27.5/35.0/35.9/35.9 | 0.2/24.9/28.1/33.0/33.9/34.1 |
| ad_placement_optimization | Optimization | 65.2/66.1/66.9/67.1/67.4/67.7 | 44.0/53.3/59.5/61.6/62.9/62.9 | 41.8/42.4/43.1/47.7/47.9/48.1 | 48.7/52.7/53.3/56.5/58.5/58.8 | 25.5/28.5/35.2/35.8/36.2/36.2 |
| apple_incremental_game | Optimization | 42.7/44.9/45.9/48.6/49.9/50.6 | 26.6/29.8/30.6/32.7/33.1/33.6 | 28.3/30.3/32.0/33.3/33.9/34.9 | 19.0/19.0/19.1/19.1/19.1/19.1 | 19.6/19.7/19.7/19.7/19.7/19.7 |
| equivalence_class_divide_and_conquer | Optimization | 11.2/15.3/17.0/20.1/20.8/21.3 | 11.8/15.5/15.8/21.3/22.2/22.4 | 14.5/17.0/18.3/18.7/20.2/20.3 | 3.8/4.2/10.0/8.0/10.6/10.6 | 0.7/1.8/3.2/3.2/3.4/3.4 |
| grid_turing_robot | Optimization | 34.7/37.1/37.3/39.6/40.3/40.3 | 40.4/41.6/41.9/42.0/42.1/42.2 | 26.8/26.8/27.2/28.9/28.9/28.9 | 20.0/21.0/24.6/24.6/24.6/25.7 | 23.7/24.1/24.1/24.1/24.2/24.2 |
| jagua_nesting_optimization | Optimization | 11.2/17.8/24.5/31.4/41.0/44.2 | 15.9/19.4/20.0/20.6/21.3/21.6 | 22.4/23.0/23.9/24.0/24.1/24.1 | 8.9/9.0/10.0/12.2/12.3/12.4 | 10.7/20.2/23.7/26.7/28.1/28.4 |
| molecular_self_assembly | Optimization | 22.4/33.4/34.0/34.1/34.4/34.7 | 20.2/20.3/20.5/20.7/20.7/20.7 | 20.8/21.1/21.1/21.5/21.5/21.6 | 10.0/12.5/12.9/13.0/13.1/13.2 | 19.4/21.7/21.8/21.8/21.9/21.9 |
| order_addition_permutation_optimization | Optimization | 22.6/31.6/34.0/34.4/35.7/36.4 | 16.7/20.5/21.5/22.4/23.0/23.3 | 1.6/10.6/13.1/14.0/14.2/14.3 | 2.0/2.1/23.6/25.8/25.8/33.2 | 4.6/16.5/17.8/22.9/25.4/30.8 |
| smt_solver | Optimization | 10.3/17.4/19.0/23.1/23.3/23.9 | 7.2/7.8/8.4/8.6/8.6/8.6 | 6.7/7.9/8.9/9.1/9.1/9.2 | 2.7/2.7/2.7/2.7/2.7/3.6 | 1.4/2.8/3.3/3.3/3.3/3.3 |
| treant_forest | Optimization | 14.5/15.9/16.1/16.2/16.4/18.0 | 12.1/14.2/14.9/15.2/15.5/15.6 | 12.2/12.2/12.7/13.0/13.2/13.3 | 8.0/11.6/11.7/14.1/14.5/16.9 | 6.8/8.1/9.7/10.1/12.7/13.5 |
| tree_block_partitioning | Optimization | 21.5/30.1/32.4/36.8/37.7/37.7 | 28.8/31.1/33.0/33.0/35.0/36.4 | 23.1/26.8/28.8/32.9/34.3/34.3 | 12.1/15.4/17.1/19.3/20.3/23.4 | 11.2/11.8/11.9/11.9/14.6/16.1 |
| triangulation_coloring_optimization | Optimization | 70.8/71.4/71.9/73.2/73.3/73.4 | 73.7/74.3/74.5/75.0/75.1/75.2 | 74.1/74.2/74.3/74.3/74.3/74.3 | 68.8/71.2/71.6/72.0/72.7/73.0 | 56.1/58.0/59.0/59.1/59.1/59.3 |
| vehicle_routing_time_windows | Optimization | 72.5/72.6/72.9/73.6/73.7/74.0 | 88.7/89.0/89.4/89.7/89.7/90.8 | 85.3/88.6/88.7/89.5/89.5/89.6 | 76.6/76.6/76.6/76.6/76.6/77.9 | 54.7/76.8/81.9/82.2/82.9/83.1 |
| vibrating_path_graph_coloring | Optimization | 19.7/21.1/21.4/22.5/24.5/25.3 | 10.1/10.5/10.6/10.7/10.7/11.4 | 18.1/19.4/19.8/23.4/23.6/24.1 | 9.6/18.3/20.3/22.9/22.9/22.9 | 12.4/14.4/19.3/19.4/21.8/22.1 |
| warehouse_forklift_routing | Optimization | 7.7/9.5/10.4/10.5/11.1/11.2 | 9.8/11.0/11.8/11.9/12.1/12.6 | 0.0/0.0/0.0/0.0/0.0/0.0 | —/0.0/0.0/0.6/0.7/0.5 | 0.0/0.0/0.0/0.0/0.0/0.0 |
| wireless_electricity_layout | Optimization | 6.5/13.7/14.4/14.5/14.5/14.5 | 6.2/6.9/7.1/7.1/7.1/7.2 | 10.9/11.1/11.1/11.1/11.1/11.1 | 7.2/9.4/6.6/8.1/9.4/9.5 | 0.0/0.0/0.0/0.0/0.0/0.0 |
| college_english_exam_bank | Knowledge | 24.8/28.3/34.8/35.5/35.8/39.8 | 24.5/35.5/35.5/35.5/37.8/37.8 | 30.7/30.7/31.3/34.0/34.0/34.5 | 22.2/26.0/29.3/30.0/32.3/32.5 | 19.2/21.7/22.5/22.7/29.2/34.7 |
| cta_risk_budget_optimization | Knowledge | 42.7/44.8/45.3/45.3/45.3/46.1 | 43.8/45.8/46.7/46.7/46.7/46.7 | 46.0/49.0/49.0/49.0/49.8/49.8 | 38.1/44.8/49.0/49.6/49.6/49.6 | 44.0/45.6/46.9/46.9/48.1/48.1 |
| k12_math_recommendation | Knowledge | 23.6/38.5/41.4/42.0/43.7/44.3 | 38.5/42.4/42.9/43.5/43.9/44.0 | 25.9/29.0/30.0/30.8/31.1/31.4 | 24.8/25.7/31.9/32.5/32.7/32.7 | 25.6/26.3/26.8/25.7/26.0/26.3 |
| portfolio_risk_calibration | Knowledge | 20.1/21.6/23.0/23.6/23.6/24.5 | 17.3/21.3/22.7/23.5/24.4/25.0 | 6.0/9.6/10.7/10.7/10.7/10.7 | 0.0/8.4/8.5/8.9/9.2/9.4 | 10.4/16.3/16.6/16.7/23.7/23.7 |
| carleson_formalization | Formal | 4.3/7.7/11.0/12.7/15.0/16.8 | 6.0/9.5/13.2/16.5/25.3/26.5 | 1.8/3.5/4.6/5.4/6.3/7.1 | 1.0/1.7/2.0/2.2/2.2/2.2 | 0.8/1.3/2.0/2.0/2.3/2.5 |
| combinatorial_games_formalization | Formal | 14.5/23.2/27.6/32.1/34.5/35.5 | 12.0/18.8/24.6/27.2/33.4/38.2 | 5.9/8.3/11.5/13.5/16.3/17.8 | 6.7/9.8/14.3/14.9/16.2/16.2 | 4.3/6.7/7.3/7.4/7.7/7.8 |
| flt_regular_formalization | Formal | 31.0/41.8/50.6/50.6/50.6/50.6 | 43.7/48.3/50.6/66.7/75.1/75.1 | 1.5/19.5/28.4/41.8/46.0/48.3 | 14.4/13.4/16.5/18.8/18.8/38.7 | 5.7/11.9/14.6/14.9/17.2/17.6 |
| lean_analysis_proofs | Formal | 17.9/25.1/28.6/30.2/32.6/33.0 | 16.8/23.2/28.4/33.9/39.0/42.5 | 3.6/8.1/10.8/12.9/15.5/16.4 | 5.2/5.9/5.9/5.9/5.9/5.9 | 5.8/7.3/8.2/8.8/9.3/9.5 |
| new_foundations_consistency | Formal | 28.9/36.2/50.0/62.7/64.2/65.1 | 13.7/38.2/55.1/56.4/65.1/66.5 | 3.3/12.2/14.9/20.5/30.7/39.8 | 2.2/3.3/5.1/21.9/24.6/27.0 | 2.2/3.4/6.5/7.2/10.5/11.4 |
| ordinal_notation_well_foundedness | Formal | 10.6/18.4/24.7/24.7/24.7/24.7 | 13.7/24.7/24.7/24.7/24.7/24.7 | 1.2/5.5/13.7/15.3/18.4/21.6 | 2.0/3.5/5.1/5.9/5.9/5.9 | 3.5/3.5/4.7/4.7/4.7/4.7 |
| pfr_formalization | Formal | 32.4/36.9/38.8/40.2/45.6/46.3 | 30.7/38.3/41.9/47.6/52.7/60.0 | 10.2/13.7/27.1/34.0/35.9/38.9 | 8.3/14.9/22.5/26.5/31.3/33.5 | 9.9/14.7/16.5/17.8/18.5/19.1 |
| sphere_eversion_formalization | Formal | 41.7/47.4/49.1/50.4/54.1/55.4 | 45.0/51.1/55.0/55.9/56.9/58.5 | 13.3/20.2/32.7/43.7/50.4/51.4 | 15.5/24.2/26.7/28.7/30.2/30.2 | 2.9/14.1/22.3/24.9/28.6/29.3 |
| anchorhead_text_adventure | Games | 13.3/19.3/19.7/20.3/22.3/22.3 | 15.0/26.3/31.7/34.3/35.3/36.3 | 5.0/11.7/13.0/13.3/14.7/17.7 | 10.7/17.3/19.7/20.3/20.3/20.3 | 2.0/6.0/7.3/8.0/12.3/14.7 |
| dcss_dungeon_ai | Games | 4.2/4.9/5.9/6.3/6.3/8.3 | 8.9/9.7/10.0/10.0/13.3/13.4 | 2.6/5.6/5.6/5.6/6.1/6.1 | 2.8/3.0/3.3/3.3/5.1/7.6 | 2.8/3.6/4.4/4.5/5.1/5.7 |
| nethack_dungeon_agent | Games | 29.7/35.3/36.7/37.3/41.9/41.9 | 16.6/17.6/18.1/20.6/21.3/22.5 | 10.9/14.1/15.2/15.8/17.0/20.4 | 2.3/2.3/15.3/21.6/21.6/21.6 | 1.0/1.4/2.9/3.2/3.2/3.3 |
| openrct2_theme_park_ai | Games | 24.4/24.4/26.0/26.0/27.5/27.5 | 28.5/28.6/32.7/37.3/37.4/37.6 | 23.0/23.1/23.1/23.1/23.1/23.1 | 35.1/36.2/36.2/36.2/36.2/36.2 | 24.4/24.4/24.4/26.0/26.0/26.0 |
| openttd_transport_ai | Games | 50.0/50.4/50.6/51.7/51.8/52.0 | 10.1/11.6/13.2/21.9/25.6/28.1 | 10.8/11.4/11.6/11.9/11.9/11.9 | 0.0/0.0/0.0/0.0/0.0/0.0 | 4.8/9.2/9.3/12.3/15.2/15.2 |
| trinity_text_adventure | Games | 25.0/28.0/29.3/30.0/30.0/30.0 | 22.3/26.7/28.7/36.3/36.3/40.0 | 16.3/19.7/22.7/23.3/23.7/27.0 | 16.0/18.7/24.3/26.0/26.7/26.7 | 16.3/16.3/17.7/20.0/20.0/20.3 |
| tryst_text_adventure | Games | 18.1/33.8/36.7/40.0/40.0/44.3 | 32.1/42.4/44.3/48.6/55.2/55.7 | 19.5/20.0/20.0/31.0/38.6/44.3 | 18.6/28.6/36.2/40.5/42.9/43.3 | 8.6/11.4/11.4/11.4/11.4/13.8 |
| wesnoth_tactical_ai | Games | 84.0/85.3/87.7/87.7/87.7/88.0 | 64.7/73.0/76.3/78.0/78.3/79.3 | 79.7/79.7/80.3/80.3/81.3/81.3 | 75.7/78.3/78.3/78.3/78.3/78.3 | 17.0/36.3/36.3/36.3/36.3/36.3 |

</details>

## Task Taxonomy

EdgeBench contains **134 realistic, diverse tasks** spanning six capability categories, of which **51 are publicly released**. Each task is designed as a day-scale challenge with a performance ceiling high enough that no current agent can saturate it. Recorded human expert effort averages **57.2 hours** per task (up to 320 hours).

<p align="center">
  <img src="assets/edgebench_taxonomy.png" alt="EdgeBench Task Taxonomy" width="850">
</p>

## Evaluation Harness: SForge

EdgeBench is powered by [**SForge**](https://bytedance-seed.github.io/EdgeBench/), a two-container evaluation harness built for long-horizon agent evaluation. Each task materializes as isolated **work** and **judge** Docker images — the agent only sees the work environment, while hidden tests run in ephemeral judge containers.

Key mechanisms:
- **Two-container isolation** — work and judge environments are fully separated, preventing evaluation hacking at its root
- **Iterative evaluation with feedback** — agents don't submit once at the end for a one-shot score; instead they submit throughout the run, receive granular feedback (pass rates, failing tests, scores), and improve in a closed loop until timeout — the best result across all submissions is the final score
- **Long-horizon execution** — stop hooks prevent premature agent exit, auto-resume recovers from transient failures, and the Kubernetes backend enables parallel runs at scale

### Quick Start

```bash
# Install (requires Docker Engine running on a Linux host)
pip install sforge

# 1. Download task definitions
sforge fetch-tasks edgebench

# 2. Pull pre-built Docker images
sforge pull --task ad_placement_optimization --registry seededge

# 3. Start judge server (separate terminal)
sforge serve

# 4. Run an agent
SFORGE_AGENT_API_KEY="sk-xxx" \
  sforge run --task ad_placement_optimization --agent claude-code \
    --model "claude-opus-4-8[1m]" --timeout 43200 --run-id edgebench-001
```

**Step-by-step examples:**
- [Single task on local Docker](examples/single-task-docker/) — run one task end-to-end with Docker
- [All tasks on Kubernetes](examples/all-tasks-k8s/) — run the full suite on a K8s cluster with experiment YAML

**Evaluating your own model / agent:**
- **Your own model** — the built-in Claude Code and Codex scaffolds work with any compatible API endpoint: point `SFORGE_AGENT_API_BASE_URL` at your endpoint, set your key via `SFORGE_AGENT_API_KEY`, and pass your model name via `--model`. See [Supported Agents](https://bytedance-seed.github.io/EdgeBench/en/guide/agents#using-third-party-models).
- **Your own agent scaffold** — just add a new agent under [`sforge/harness/agent/`](sforge/harness/agent/) (a small `Agent` subclass declaring how to install and launch it) and register it in the factory, then run with `--agent <your-agent>`. See [Custom Agents](https://bytedance-seed.github.io/EdgeBench/en/guide/agents#custom-agents).

Full documentation: [bytedance-seed.github.io/EdgeBench](https://bytedance-seed.github.io/EdgeBench/)

## Citation

If you find EdgeBench useful in your research, please cite our tech report:

```bibtex
@misc{edgebench2026,
  title  = {EdgeBench: Unveiling Scaling Laws of Learning from Real-World Environments},
  author = {Deyao Zhu and Xin Zhou and Shengling Qin and Xuekai Zhu and Hangliang Ding and Shu Zhong and others},
  year   = {2026},
  url    = {https://edge-bench.org/paper.pdf},
}
```

## License

- **EdgeBench Tasks** (task datasets) are released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- **SForge** (evaluation harness code) is released under the [Apache License 2.0](LICENSE).

## Contact

> To evaluate on the full 134-task suite, please contact [zhongshu@bytedance.com](mailto:zhongshu@bytedance.com).

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.png">
    <img src="assets/logo.jpg" alt="ByteDance Seed" width="200">
  </picture>
  <br>
  <sub>Built by <a href="https://github.com/ByteDance-Seed">ByteDance Seed</a></sub>
</p>
