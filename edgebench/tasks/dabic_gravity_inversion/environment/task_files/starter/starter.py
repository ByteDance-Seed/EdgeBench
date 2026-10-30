"""
starter.py — D-ABIC 重力反演任务骨架

提供:
  - 合成 Model 3 网格与密度模型 (mesh, m_true, body_label)
  - 测点 (rxLoc)
  - 观测数据 (d_clean, d_obs, sigma_per_pt)
  - 前向模拟对象 (sim_fwd)

Agent 需基于以上数据, 在 SimPEG 框架下完整实现:
  - Cooling 反演 baseline
  - L-curve 扫描与拐点检测 baseline
  - D-ABIC β 自适应寻优
均须在 L0 与 L1 两种范数下运行.

参考资料:
  - Song Han 等 2025 Geophysics doi 10.1190/geo-2025-0233 提出 D-ABIC
  - Xu 等 2025 Geophysical Prospecting doi 10.1111/1365-2478.70016 给出 HMC 对照
"""

from __future__ import annotations

import numpy as np
from discretize import TensorMesh
from simpeg import maps
from simpeg.potential_fields import gravity


# ============================================================
# 合成 Model 3 几何 (Xu 2025 四体密度模型)
# ============================================================

mesh = TensorMesh([[(100, 40)], [(100, 30)], [(100, 10)]], x0="00N")
X, Y, Z = mesh.cell_centers[:, 0], mesh.cell_centers[:, 1], mesh.cell_centers[:, 2]
nC = mesh.nC

m_true = np.zeros(nC)
mask1 = (X >= 900) & (X <= 2000) & (Y >= 2100) & (Y <= 2500) \
        & (Z >= -700) & (Z <= -200)
mask2 = (((X >= 1000) & (X <= 1700) & (Y >= 500) & (Y <= 800)) |
         ((X >= 1400) & (X <= 1700) & (Y >= 800) & (Y <= 1600))) \
        & (Z >= -500) & (Z <= -200)
mask3 = (X >= 2700) & (X <= 3200) & (Y >= 1500) & (Y <= 2100) \
        & (Z >= -600) & (Z <= -300)
mask4 = (X >= 2400) & (X <= 2800) & (Y >= 700) & (Y <= 1100) \
        & (Z >= -700) & (Z <= -200)
m_true[mask1] = 1.0
m_true[mask2] = 1.0
m_true[mask3] = 1.0
m_true[mask4] = 1.0

body_label = np.zeros(nC, dtype=np.int8)
body_label[mask1] = 1
body_label[mask2] = 2
body_label[mask3] = 3
body_label[mask4] = 4


# ============================================================
# 测点网格 (41 × 31)
# ============================================================

nx_rx, ny_rx = 41, 31
xr, yr = np.meshgrid(
    np.linspace(0, 4000, nx_rx),
    np.linspace(0, 3000, ny_rx),
)
rxLoc = np.c_[xr.flatten(), yr.flatten(), np.zeros(xr.size)]
N_data = rxLoc.shape[0]


# ============================================================
# 前向模拟 + 加噪 (随机种子固定为 42)
# ============================================================

sim_fwd = gravity.simulation.Simulation3DIntegral(
    survey=gravity.survey.Survey(
        gravity.sources.SourceField(
            receiver_list=[gravity.receivers.Point(rxLoc)]
        )
    ),
    mesh=mesh,
    rhoMap=maps.IdentityMap(mesh),
    store_sensitivities="ram",
)
d_clean = sim_fwd.dpred(m_true)
np.random.seed(42)
sigma_per_pt = 0.05 * np.abs(d_clean) + 0.02
d_obs = d_clean + sigma_per_pt * np.random.randn(len(d_clean))


if __name__ == "__main__":
    print("=" * 60)
    print(" starter.py 自检 — 合成 Model 3")
    print("=" * 60)
    print(f"  Mesh:     shape={mesh.shape_cells}, nC={nC}")
    print(f"  Stations: N={N_data}")
    print(f"  Bodies:   4 个, 密度 1.0, 非零单元 {int((m_true > 0).sum())}")
    print(f"  Signal:   [{d_clean.min():+.3f}, {d_clean.max():+.3f}] mGal")
    print(f"  Noise σ:  [{sigma_per_pt.min():.4f}, {sigma_per_pt.max():.4f}] mGal")
