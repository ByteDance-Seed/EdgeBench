# D-ABIC 重力三维反演正则化参数选取优化方法

## 任务说明

本任务把 Song Han 等 2025 年发表于 *Geophysics* 的论文 doi 10.1190/geo-2025-0233 中提出的 D-ABIC 方法，从原始的三维大地电磁反演场景迁移到三维重力反演，并在 Vinton 盐丘实测重力数据上验证。D-ABIC 全称 Data-space variant of Akaike's Bayesian Information Criterion，是一种正则化参数 β 的自适应选取算法。

Xu 等 2025 年发表于 *Geophysical Prospecting* 第 73 卷第 4 期 1301 至 1314 页、doi 10.1111/1365-2478.70016 的论文在同一份 Vinton 数据上用 Hamiltonian Monte Carlo 方法做了重力反演，作为本任务的对照基准。

反演须在 L0 范数与 L1 范数两种稀疏正则化形式下分别完成。对每种范数都要跑出 D-ABIC、Cooling、L-curve 三方对比。

## 工作目录结构

```
.
├── docs/
│   ├── geo20250233.pdf      Song 等 D-ABIC 方法论文
│   └── Xu2025_HMC.pdf       Xu 等 HMC 重力反演 + Vinton 应用
├── data/
│   └── saltdome_s7_100.grd  Vinton 盐丘实测重力异常数据 (Surfer 7 二进制)
├── starter/
│   ├── starter.py           合成数据与前向模拟器, 反演框架由 Agent 实现
│   ├── explore_xu_data.py   Vinton 数据解析与初步诊断, 直接运行即可
│   └── README.md            本文件
└── outputs/                 所有产出写入此目录
```

## starter.py 提供的对象

`starter.py` 只构建合成数据与前向模拟器，不包含任何反演组件。导入后即可使用的全局对象：

- `mesh`：discretize TensorMesh，40×30×10 共 12000 个单元格
- `m_true`：真模型密度向量，4 个目标体，密度均为 1.0
- `body_label`：每个单元归属的目标体编号，0 为背景
- `rxLoc`：41×31 共 1271 个地表测点
- `sim_fwd`：SimPEG 前向模拟对象
- `d_clean`：无噪声理论数据
- `d_obs`：带噪观测数据
- `sigma_per_pt`：每个测点的噪声标准差，0.05·|d|+0.02 mGal

Agent 需在此基础上自行搭建 SimPEG 反演框架，包括 `data_misfit`、`regularization`、`optimization`、`inverse_problem`、`inversion`、各种 `directives` 等。

## 四个阶段

### 第一阶段 算法实现

阅读 `docs/geo20250233.pdf`，把握 D-ABIC 的统计框架、数学推导与数值实现要点。实现 D-ABIC β 自适应 directive，建议命名为 `class DABIC_Beta_Estimator(directives.InversionDirective)` 并放到 `outputs/dabic_directive.py` 独立模块中。

MT 反演与重力反演的前向算子、雅可比、数据类型、参数化均不同。迁移时的处理方式由实现者决定，并须在报告中说明依据。是否采用模型空间形式还是数据空间形式、行列式如何计算、β 在哪个空间寻优，自行判断。所实现的 directive 须在 L0 与 L1 两种范数下均能正常工作。

### 第二阶段 合成验证

基于 starter 提供的合成数据，自行搭建完整的 SimPEG 反演流程。除了 D-ABIC 之外，还需自行实现 Cooling 反演与 L-curve 扫描＋拐点检测两套 baseline。在合成 Model 3 上分别在 L0 与 L1 两种范数下跑通 D-ABIC、Cooling、L-curve 三方对比。

输出可定量与定性比较各方法效果的图与指标，包括反演结果切片、数据残差、β 收敛轨迹、目标体恢复情况。还需报告 L0 与 L1 下 D-ABIC 的行为差异，例如 β 终值的量级差、IRLS 重加权对寻优过程的影响。

### 第三阶段 实测应用

`data/saltdome_s7_100.grd` 是 Vinton 盐丘的实测重力异常数据，Surfer 7 二进制格式。`starter/explore_xu_data.py` 可解析该文件并输出诊断图与噪声估计，直接运行即可。

反演所需的物理与几何设置，包括网格尺寸、深度范围、密度边界、噪声估计等，参考 `docs/Xu2025_HMC.pdf`。该论文用 HMC 方法处理了同一份数据。

对实测数据分别在 L0 与 L1 范数下跑 D-ABIC 与 Cooling 两套反演。

### 第四阶段 结果对比

与 Xu 2025 HMC 论文报告的 Vinton 反演结果做定量与定性对比，包括深度切片、几何范围、数据拟合情况。L0 与 L1 下的结果分别报告。

撰写 `report.md`，篇幅 800 至 1500 字，至少说明三件事：

1. 把方法从 MT 反演移植到重力反演时做了哪些关键决策？依据是什么？
2. L0 与 L1 范数下 D-ABIC 的行为有何系统性差异？这些差异是否反映在反演图像与统计指标上？
3. 合成数据与实测数据上得到的反演结果，与 baseline 方法及 Xu HMC 结果相比有何异同？

## 最终交付物

所有产出写到 `outputs/`：

- `dabic_directive.py` — D-ABIC 实现，独立可复用模块
- `run_synthetic.py` — 合成验证脚本，同时跑 L0 与 L1，生成第二阶段的图
- `run_vinton.py` — 实测反演脚本，同时跑 L0 与 L1，生成第三、四阶段的图
- `results.json` — 关键反演指标，L0 与 L1 都要记录
- `report.md` — 报告

`results.json` 的字段名建议形如 `synthetic_L0`、`synthetic_L1`、`vinton_L0`、`vinton_L1`，每个 key 下记录 `dabic_chi2_per_N`、`dabic_model_rmse`、`cooling_model_rmse`、`dabic_beta_history`、`dabic_residual_rms_mGal`、`dabic_cap_rock_center_depth_m`、`dabic_xu_iou` 等。

## 运行环境

Python 3.10 至 3.12。依赖包：simpeg >= 0.22.0、discretize >= 0.10.0、numpy >= 1.24、scipy >= 1.11、matplotlib >= 3.7。

```
pip install "simpeg>=0.22.0" "discretize>=0.10.0" "numpy>=1.24" "scipy>=1.11" "matplotlib>=3.7"
```

`starter/starter.py` 末尾有自检入口，`python starter/starter.py` 应输出 mesh、stations、bodies 等基本信息。运行 `python starter/explore_xu_data.py` 会在 `vinton_data/` 子目录下生成 6 张诊断图与一份参数 JSON，供 Vinton 反演参考。

## 约束条件

- 不要修改 `starter/explore_xu_data.py`
- 不要修改 `starter/starter.py` 中的模型、测点、观测数据生成逻辑
- β 必须由 D-ABIC 自适应给出，不允许硬编码为常数
- 不允许 import 任何第三方 ABIC 或 DABIC 包
- 不允许使用 SimPEG 内置的自动 β 高级 directive，`BetaEstimate_ByEig` 仅可用于设置 β₀ 初值
- L0 与 L1 范数下的反演都必须完整完成，`results.json` 与图件须覆盖两种范数
- 只实现规格要求的内容，不要扩展到 GCV、HMC 等其他正则化策略

## 工作流程建议

1. 先读 `docs/geo20250233.pdf` 的方法部分，理解 D-ABIC 的统计框架
2. 自行设计 SimPEG 反演框架，并实现 Cooling tracker 与 L-curve 扫描两套 baseline
3. 写 `outputs/dabic_directive.py`，实现 D-ABIC β 自适应 directive
4. 在合成 Model 3 上分别跑 L1 与 L0 范数，验证三方对比是否合理
5. 跑 Vinton 实测，参考 `explore_xu_data.py` 输出的参数设置反演
6. 与 Xu HMC 结果对比，写 `report.md`

每完成一个阶段，跑一次脚本，检查 `results.json` 中关键指标是否落在合理范围，再进入下一阶段。
