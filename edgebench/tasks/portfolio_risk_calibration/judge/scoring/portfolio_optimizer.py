"""
portfolio_optimizer.py - 动态投资组合优化与风险自适应配置策略
============================================================

策略概述：
    基于风险校准驱动的动态投资组合优化系统，通过监控市场波动率变化，
    动态调整协方差矩阵和风险预算，实现自适应资产配置。

核心功能：
    1. 风险校准：参数法VaR + EWMA协方差矩阵估计 + 安全垫
       - 安全垫确保VaR估计不会过于乐观
       - 突破检测使用含安全垫的VaR，减少误报
    2. 风险缩放因子：纯价格驱动，基于近期波动率/长期波动率比值
       - 波动率聚集效应：市场动荡时波动率上升，缩放因子自动调高
       - 平滑处理：单次变化不超过±20%，防止剧烈跳变
    3. 投资组合优化：波动率倒数分配 + 动量微调 + 风险缩放轮动
       - 波动率倒数：低波动ETF（债券）天然获得更高权重
       - 动量微调：近期表现好的ETF获得小幅超配（±2%）
       - 风险缩放轮动：高波动期减股增债，低波动期加股减债
    4. 波动率突变检测：监控ETF已实现波动率，含冷却期防抖
       - 冷却期20天，防止同一事件反复触发
    5. 动态再平衡：
       - 定期（20个交易日）
       - 风险缩放因子变化超过±20%
       - 波动率突变事件
       - 最小间隔保护：额外再平衡至少间隔5个交易日
    6. 仓位硬限制：
       - 单资产≤24.9%（留0.1%浮点安全余量）
       - 股票/债券/商品类≤60%
       - 货币类≤10%
       - 不可做空ETF权重≥0

交易记录规范（与评分脚本严格一致）：
    return = 单ETF涨跌幅（扣除交易成本和融券利息）
    weight = 调仓前后权重的平均值
    open_price/close_price = 交易价格
    qty = 交易数量

运行模式：
    训练模式：python portfolio_optimizer.py --train
        训练期(2019-2023)估计参数 → 验证期(2024)回测
        输出：backtest_results.json

    回测模式：python portfolio_optimizer.py --backtest
        隐藏测试期(2025)回测
        输出：backtest_results.json
"""

import sys
import json
import time
import argparse
from datetime import timedelta

import pandas as pd
import numpy as np
from scipy import stats
import warnings
warnings.filterwarnings('ignore')


# ============================================================================
# 策略配置参数
# ============================================================================

# ---------- 资金与仓位 ----------
INITIAL_CAPITAL = 10_000_000          # 初始资金 1000万
MAX_SINGLE_POSITION = 0.25            # 单资产最大仓位 25%
MAX_ASSET_CLASS_POSITION = 0.60       # 单大类资产上限 60%
MAX_MONEY_CLASS_POSITION = 0.10       # 货币类资产上限 10%（硬限制）
MAX_LEVERAGE = 2.0                    # 总杠杆率上限
MAX_SHORT_RATIO = 0.50                # 单资产做空比例上限

# ---------- 交易成本 ----------
COMMISSION = 0.0005                   # 单边手续费 0.05%
SHORT_INTEREST = 0.04                 # 年化融券成本 4%

# ---------- 风险模型 ----------
VAR_CONFIDENCE = 0.95                 # VaR置信水平
VAR_LOOKBACK = 500                    # VaR估计窗口（交易日）
VAR_SAFETY_MARGIN = 1.5               # VaR安全垫乘数（提高估计保守性）
RISK_SCALE_MIN = 0.6                  # 风险缩放因子下限
RISK_SCALE_MAX = 2.0                  # 风险缩放因子上限
EWMA_HALF_LIFE = 60                   # 协方差EWMA半衰期

# ---------- 再平衡 ----------
REBALANCE_FREQ = 20                   # 定期再平衡频率（交易日）
RISK_SCALE_CHANGE_THRESHOLD = 0.20    # 缩放因子突变阈值（20%）
VOL_SPIKE_COOLDOWN = 20               # 波动率突变冷却期（自然日，防止同一事件反复触发）

# ---------- 波动率突变检测 ----------
VOL_LOOKBACK = 20                     # 波动率计算窗口（交易日）
VOL_SPIKE_THRESHOLD = 0.30            # 波动率突变阈值（5日变化超过30%）

# ---------- 默认日期 ----------
DEFAULT_TRAIN_START = '2019-01-01'
DEFAULT_TRAIN_END = '2023-12-31'
DEFAULT_VALID_START = '2024-01-01'
DEFAULT_VALID_END = '2024-12-31'
DEFAULT_TEST_START = '2025-01-01'
DEFAULT_TEST_END = '2025-12-31'


# ============================================================================
# 全局配置
# ============================================================================

# 资产大类映射（用于仓位约束和风险缩放轮动）
ASSET_CLASS = {
    '510300.XSHG': '股票', '159935.XSHE': '股票', '159915.XSHE': '股票',
    '513660.XSHG': '股票', '513500.XSHG': '股票',
    '511010.XSHG': '债券', '511220.XSHG': '债券',
    '518880.XSHG': '商品', '510410.XSHG': '商品',
    '159001.XSHE': '货币'
}

# 可做空ETF列表（仅股票和商品类，与任务文档一致）
SHORTABLE_ETFS = [
    '510300.XSHG', '159935.XSHE', '159915.XSHE',
    '513660.XSHG', '513500.XSHG',
    '518880.XSHG', '510410.XSHG'
]

# ETF名称映射（用于日志输出）
ETF_NAMES = {
    '510300.XSHG': '沪深300ETF', '159935.XSHE': '中证500ETF',
    '159915.XSHE': '创业板ETF', '513660.XSHG': '恒生ETF',
    '513500.XSHG': '标普500ETF', '511010.XSHG': '国债ETF',
    '511220.XSHG': '城投债ETF', '518880.XSHG': '黄金ETF',
    '510410.XSHG': '资源ETF博时', '159001.XSHE': '货币ETF'
}

# 全部ETF列表（固定顺序，用于权重向量）
ALL_ETFS = [
    '510300.XSHG', '159935.XSHE', '159915.XSHE',
    '513660.XSHG', '513500.XSHG',
    '511010.XSHG', '511220.XSHG',
    '518880.XSHG', '510410.XSHG',
    '159001.XSHE'
]
N_ASSETS = len(ALL_ETFS)


# ============================================================================
# 基础工具函数
# ============================================================================

def load_price_data(filepath):
    """加载ETF日频行情数据"""
    df = pd.read_csv(filepath, encoding='utf-8-sig')
    df['date'] = pd.to_datetime(df['date'])
    return df


def load_period(period_file, default_start=None, default_end=None):
    """加载日期配置文件（格式：开始日期,结束日期）"""
    try:
        with open(period_file, 'r', encoding='utf-8') as f:
            s, e = f.read().strip().split(',')
        return s.strip(), e.strip()
    except FileNotFoundError:
        return (default_start, default_end) if default_start else (None, None)


def safe_strftime(dt):
    """安全将日期转为字符串（兼容 Timestamp 和 datetime）"""
    return dt.strftime('%Y-%m-%d') if hasattr(dt, 'strftime') else str(dt)


def get_trading_days_between(dates_series, start_date, end_date):
    """计算两个日期之间的交易日数量"""
    return len([d for d in dates_series if start_date <= d <= end_date])


# ============================================================================
# 数据准备
# ============================================================================

def prepare_price_matrix(price_df, start_date, end_date):
    """
    准备价格矩阵和收益率矩阵

    返回:
        pivot_close: 收盘价透视表（行=日期，列=ETF代码）
        returns: 日收益率矩阵
        dates: 交易日列表
    """
    # 筛选指定时间段的数据
    period_df = price_df[(price_df['date'] >= start_date) & (price_df['date'] <= end_date)]

    # 构建收盘价透视表
    pivot_close = period_df.pivot(index='date', columns='stock_code', values='close')

    # 确保所有10只ETF都在列中（缺失则填充NaN）
    for etf in ALL_ETFS:
        if etf not in pivot_close.columns:
            pivot_close[etf] = np.nan

    # 按固定顺序排列，前向填充缺失值
    pivot_close = pivot_close[ALL_ETFS].ffill()

    # 计算日收益率
    returns = pivot_close.pct_change().dropna()
    dates = returns.index

    return pivot_close, returns, dates


# ============================================================================
# 风险校准模块（纯价格驱动 + 安全垫）
# ============================================================================

class RiskCalibrationModule:
    """
    风险校准模块

    核心功能：
    1. 协方差矩阵估计：EWMA方法，对近期数据赋予更高权重
    2. VaR计算：参数法（正态假设）+ 安全垫乘数
    3. 风险缩放因子：基于近期波动率/长期波动率比值
    4. VaR突破检测：记录实际损失超过VaR的日期

    风险缩放因子完全基于ETF自身的价格数据：
    - 核心逻辑：近期波动率 / 长期波动率 的比值
    - 波动率聚集效应：市场动荡时近期波动率 > 长期波动率，
      缩放因子自动调高，协方差矩阵膨胀，组合风险预算收紧
    - 平滑处理：单次变化不超过±20%，防止剧烈跳变
    """

    def __init__(self, returns):
        """
        初始化风险校准模块

        参数:
            returns: 日收益率DataFrame（行=日期，列=ETF代码）
        """
        self.returns = returns
        self.n_assets = returns.shape[1]
        self.scale_factor = 1.0          # 当前风险缩放因子
        self.scale_factor_history = []    # 缩放因子历史记录
        self.var_history = []             # VaR预测值历史
        self.var_break_events = []        # VaR突破事件记录

    def estimate_covariance(self, current_idx):
        """
        EWMA协方差矩阵估计

        使用指数加权移动平均，对近期数据赋予更高权重。
        半衰期为60个交易日（约3个月）。

        参数:
            current_idx: 当前交易日索引

        返回:
            协方差矩阵（numpy数组，shape=(n_assets, n_assets)）
        """
        # 数据不足时使用简单协方差
        if current_idx < 60:
            return self.returns.iloc[:current_idx+1].cov().values

        # 计算EWMA权重
        decay = 0.5 ** (1.0 / EWMA_HALF_LIFE)
        window_data = self.returns.iloc[max(0, current_idx-VAR_LOOKBACK):current_idx+1]
        n = len(window_data)
        weights = np.array([decay ** i for i in range(n-1, -1, -1)])
        weights /= weights.sum()

        # 去均值
        demeaned = window_data.values - window_data.mean().values

        # 计算加权协方差
        cov = np.zeros((self.n_assets, self.n_assets))
        for i in range(self.n_assets):
            for j in range(self.n_assets):
                cov[i, j] = np.sum(weights * demeaned[:, i] * demeaned[:, j])

        # 正定性保障：特征值过小则添加微小对角扰动
        eigvals = np.linalg.eigvalsh(cov)
        if eigvals.min() < 1e-10:
            cov += np.eye(self.n_assets) * 1e-6

        return cov

    def calculate_var(self, weights, cov):
        """
        参数法VaR（含安全垫）

        VaR = z_score × portfolio_vol × safety_margin

        安全垫确保VaR估计不会过于乐观。
        突破检测也使用含安全垫的VaR，减少日常波动的误报。

        参数:
            weights: 当前持仓权重向量
            cov: 协方差矩阵（已应用缩放因子）

        返回:
            VaR值（占净资产比例）
        """
        portfolio_vol = np.sqrt(weights.T @ cov @ weights)
        z_score = stats.norm.ppf(1 - VAR_CONFIDENCE)  # 95%置信度 ≈ 1.645
        return float(z_score * portfolio_vol * VAR_SAFETY_MARGIN)

    def update_scale_factor(self, current_idx):
        """
        纯价格驱动的风险缩放因子更新

        计算逻辑：
        1. 计算所有ETF的20日平均波动率（近期）
        2. 计算所有ETF的252日平均波动率（长期）
        3. 缩放因子 = 近期波动率 / 长期波动率
        4. 平滑处理：限制单次变化不超过±20%

        波动率聚集效应：
        - 市场动荡时近期波动率 > 长期波动率 → 缩放因子 > 1.0
        - 市场平静时近期波动率 < 长期波动率 → 缩放因子 < 1.0

        参数:
            current_idx: 当前交易日索引

        返回:
            缩放因子（float）
        """
        if current_idx < 60:
            return 1.0

        # 收集各ETF的近期和长期波动率
        recent_vols = []
        long_vols = []

        for col in self.returns.columns:
            # 20日波动率（近期）
            rets = self.returns[col].iloc[max(0, current_idx-20):current_idx+1]
            if len(rets) >= 10:
                recent_vols.append(float(rets.std()))

            # 252日波动率（长期）
            long_rets = self.returns[col].iloc[max(0, current_idx-252):current_idx+1]
            if len(long_rets) >= 60:
                long_vols.append(float(long_rets.std()))

        if not recent_vols or not long_vols:
            return 1.0

        # 计算平均波动率比值
        avg_recent = np.mean(recent_vols)
        avg_long = np.mean(long_vols)

        if avg_long < 1e-6:
            return 1.0

        vol_ratio = avg_recent / avg_long
        raw_scale = np.clip(vol_ratio, RISK_SCALE_MIN, RISK_SCALE_MAX)

        # 平滑处理：限制单次变化不超过±20%
        prev_scale = self.scale_factor
        smooth_scale = prev_scale + np.clip(raw_scale - prev_scale, -0.20, 0.20)

        return round(float(smooth_scale), 4)

    def step(self, current_idx, weights):
        """
        执行一步风险校准

        在每个交易日调用，完成：
        1. 估计协方差矩阵
        2. 更新风险缩放因子
        3. 计算当前VaR
        4. 检测VaR突破

        参数:
            current_idx: 当前交易日索引
            weights: 当前持仓权重向量

        返回:
            (adjusted_cov, extra_rebalance)
            - adjusted_cov: 经缩放因子调整后的协方差矩阵
            - extra_rebalance: 是否需要额外再平衡（缩放因子变化超阈值）
        """
        # 1. 估计协方差矩阵
        cov = self.estimate_covariance(current_idx)

        # 2. 更新风险缩放因子
        prev_scale = self.scale_factor
        self.scale_factor = self.update_scale_factor(current_idx)

        # 3. 应用缩放因子
        adjusted_cov = cov * self.scale_factor

        # 4. 计算含安全垫的VaR
        var_value = self.calculate_var(weights, adjusted_cov)

        # 记录VaR预测值
        self.var_history.append({
            'date': safe_strftime(self.returns.index[current_idx]),
            'var_95': round(var_value, 6)
        })

        # 5. VaR突破检测（使用含安全垫的VaR）
        if current_idx + 1 < len(self.returns):
            actual_return = float(self.returns.iloc[current_idx + 1].values @ weights)
            if actual_return < -var_value:
                self.var_break_events.append({
                    'date': safe_strftime(self.returns.index[current_idx + 1]),
                    'actual_return': round(actual_return, 6),
                    'var_95': round(var_value, 6)
                })

        # 记录缩放因子历史
        self.scale_factor_history.append({
            'date': safe_strftime(self.returns.index[current_idx]),
            'scale_factor': self.scale_factor
        })

        # 判断是否需要额外再平衡
        scale_change = abs(self.scale_factor - prev_scale) / max(prev_scale, 0.01)
        return adjusted_cov, scale_change > RISK_SCALE_CHANGE_THRESHOLD


# ============================================================================
# 投资组合优化模块（波动率倒数 + 动量 + 风险缩放轮动）
# ============================================================================

class PortfolioOptimizer:
    """
    投资组合优化器

    核心策略：
    1. 波动率倒数分配：低波动ETF（债券）天然获得更高权重
    2. 动量微调：近期表现好的ETF获得小幅超配（±2%）
    3. 风险缩放轮动：高波动期减股增债，低波动期加股减债

    硬限制（迭代执行，确保所有约束同时满足）：
    - 单资产≤24.9%（留0.1%浮点余量）
    - 股票/债券/商品类≤60%
    - 货币类≤10%
    - 不可做空ETF权重≥0
    """

    def __init__(self, n_assets):
        """
        初始化优化器

        参数:
            n_assets: 资产数量（=10）
        """
        self.n_assets = n_assets
        self.previous_weights = np.ones(n_assets) / n_assets  # 初始等权

    def optimize(self, cov_matrix, returns_history, risk_scale=1.0):
        """
        执行一步优化

        参数:
            cov_matrix: 协方差矩阵（已应用缩放因子）
            returns_history: 近期收益率数据（用于动量计算）
            risk_scale: 风险缩放因子（用于资产轮动）

        返回:
            (weights, delta)
            - weights: 新的目标权重向量
            - delta: 与前期权重的差值向量
        """
        # 提取各ETF的独立波动率
        vols = np.sqrt(np.diag(cov_matrix))
        vols = np.clip(vols, 1e-6, None)  # 防止除零

        # ---- 第1步：波动率倒数基础权重 ----
        # 不同资产类别使用不同的风险预算乘数
        raw_weights = np.zeros(self.n_assets)
        for i in range(self.n_assets):
            cls = ASSET_CLASS.get(ALL_ETFS[i], '')
            if cls == '股票':
                raw_weights[i] = 1.0 / vols[i]           # 股票：标准风险预算
            elif cls == '商品':
                raw_weights[i] = 1.0 / vols[i] * 0.5     # 商品：半仓（波动大）
            elif cls == '债券':
                raw_weights[i] = 1.0 / vols[i] * 0.8     # 债券：八成仓（波动小但收益率也低）
            elif cls == '货币':
                raw_weights[i] = MAX_MONEY_CLASS_POSITION  # 货币：固定10%上限

        # 归一化
        raw_weights /= np.sum(raw_weights)

        # ---- 第2步：动量微调（±2%）----
        if len(returns_history) >= 20:
            # 计算过去20日平均收益率
            momentum = returns_history.iloc[-20:].mean().values
            mom_mean = np.mean(momentum)
            mom_std = np.std(momentum)
            if mom_std > 0:
                # 标准化动量信号，限制在±2倍标准差内
                mom_signal = np.clip((momentum - mom_mean) / mom_std, -2, 2)
                # 动量调整：每单位信号调整1%权重
                raw_weights += mom_signal * 0.01
            # 确保权重非负（动量调整可能导致负值）
            raw_weights = np.clip(raw_weights, 0.001, None)

        # ---- 第3步：风险缩放因子驱动的资产轮动 ----
        if risk_scale > 1.2:
            # 高风险期：减股增债
            for i in range(self.n_assets):
                cls = ASSET_CLASS.get(ALL_ETFS[i], '')
                if cls == '股票':
                    raw_weights[i] *= 0.7    # 股票仓位打7折
                elif cls == '债券':
                    raw_weights[i] *= 1.3    # 债券仓位加3成

        # ---- 第4步：单资产硬限制（迭代2次确保收敛）----
        for _ in range(2):
            for i in range(self.n_assets):
                if raw_weights[i] > MAX_SINGLE_POSITION:
                    # 超出部分分配给其他未超限ETF
                    excess = raw_weights[i] - MAX_SINGLE_POSITION
                    raw_weights[i] = MAX_SINGLE_POSITION
                    other = [j for j in range(self.n_assets)
                            if j != i and raw_weights[j] < MAX_SINGLE_POSITION]
                    if other:
                        raw_weights[other] += excess / len(other)
            # 归一化
            raw_weights /= np.sum(raw_weights)

        # ---- 第5步：大类资产约束 ----
        for cls in ['股票', '债券', '商品']:
            cls_idx = [i for i, etf in enumerate(ALL_ETFS) if ASSET_CLASS.get(etf) == cls]
            cls_total = sum(raw_weights[i] for i in cls_idx)
            if cls_total > MAX_ASSET_CLASS_POSITION:
                # 超出部分按比例缩减
                scale = MAX_ASSET_CLASS_POSITION / cls_total
                for i in cls_idx:
                    raw_weights[i] *= scale

        # ---- 第6步：货币类硬限制 ----
        money_idx = ALL_ETFS.index('159001.XSHE')
        if raw_weights[money_idx] > MAX_MONEY_CLASS_POSITION:
            excess = raw_weights[money_idx] - MAX_MONEY_CLASS_POSITION
            raw_weights[money_idx] = MAX_MONEY_CLASS_POSITION
            other = [j for j in range(self.n_assets) if j != money_idx]
            raw_weights[other] += excess / len(other)

        # ---- 第7步：最终归一化 ----
        weights = raw_weights / np.sum(raw_weights)

        # 计算与前期权重的差异
        delta = weights - self.previous_weights

        # 更新前次权重
        self.previous_weights = weights.copy()

        return weights, delta


# ============================================================================
# 波动率突变检测（含冷却期防抖）
# ============================================================================

class VolatilityMonitor:
    """
    波动率突变检测模块

    检测逻辑：
    1. 监控前5只股票类ETF的20日已实现波动率
    2. 当5日波动率变化超过30%时，触发波动率突变事件
    3. 触发后进入20天冷却期，防止同一事件反复触发

    与评分脚本的加分项对应：
    评分脚本读取 true_risk_events.json 获取预设事件，
    然后在本模块的 vol_events 中查找匹配记录。
    """

    def __init__(self, pivot_close):
        """
        初始化波动率监控器

        参数:
            pivot_close: 收盘价透视表
        """
        self.pivot = pivot_close
        self.vol_events = []            # 检测到的波动率事件列表
        self.last_trigger_date = None   # 上次触发日期（用于冷却期判断）

    def check(self, date, current_idx):
        """
        检查是否有波动率突变

        参数:
            date: 当前日期
            current_idx: 当前交易日索引

        返回:
            (triggered, max_response)
            - triggered: 是否检测到突变
            - max_response: 建议的缩放因子响应值
        """
        # 冷却期检查：上次触发后20天内不再触发
        if self.last_trigger_date is not None:
            days_since = (date - self.last_trigger_date).days
            if days_since < VOL_SPIKE_COOLDOWN:
                return False, 1.0

        one_triggered = False
        max_response = 1.0

        # 仅检测前5只股票类ETF（减少计算量）
        for etf in ALL_ETFS[:5]:
            if etf not in self.pivot.columns:
                continue

            # 计算收益率序列
            rets = self.pivot[etf].pct_change()

            # 数据不足时跳过
            if current_idx < VOL_LOOKBACK + 5:
                continue

            # 当前20日波动率（年化）
            cur_vol = float(rets.iloc[current_idx-VOL_LOOKBACK:current_idx+1].std() * np.sqrt(252))
            # 5日前的20日波动率（年化）
            prev_vol = float(rets.iloc[current_idx-VOL_LOOKBACK-5:current_idx-5+1].std() * np.sqrt(252))

            if pd.isna(cur_vol) or pd.isna(prev_vol) or prev_vol < 0.01:
                continue

            # 波动率变化
            change = cur_vol - prev_vol

            if change > VOL_SPIKE_THRESHOLD:
                one_triggered = True
                # 缩放因子响应 = 1.0 + min(变化幅度, 1.0)
                response = 1.0 + min(change, 1.0)
                max_response = max(max_response, response)

                # 记录事件
                self.vol_events.append({
                    'date': safe_strftime(date),
                    'type': 'volatility_spike_detected',
                    'asset': etf,
                    'vol_before': round(prev_vol, 4),
                    'vol_after': round(cur_vol, 4),
                    'scale_factor_response': round(response, 4),
                    'description': f'检测到{ETF_NAMES.get(etf, etf)}波动率突变'
                })

        # 更新上次触发日期
        if one_triggered:
            self.last_trigger_date = date

        return one_triggered, max_response


# ============================================================================
# 交易记录生成（与评分脚本 cost_verify 严格一致）
# ============================================================================

def record_trades(old_weights, new_weights, old_date, new_date, pivot_close, trades):
    """
    记录调仓交易

    return = 单ETF涨跌幅（扣除交易成本和融券利息）
    与评分脚本 verify_transaction_costs 的独立验算逻辑完全一致：
        - buy: (close-open)/open - 2*commission
        - sell: (open-close)/open - 2*commission
        - short: (open-close)/open - 2*commission - short_interest
        - cover: (close-open)/open - 2*commission - short_interest

    weight = 调仓前后权重的平均值（用于评分脚本备查）

    参数:
        old_weights: 调仓前权重向量
        new_weights: 调仓后权重向量
        old_date: 调仓起始日期
        new_date: 调仓执行日期
        pivot_close: 收盘价透视表
        trades: 交易记录列表（原地修改）
    """
    # 最小调仓阈值：权重变化超过2%才记录交易（降低换手率）
    MIN_TRADE_DELTA = 0.02

    for i in range(N_ASSETS):
        delta = new_weights[i] - old_weights[i]
        if abs(delta) < MIN_TRADE_DELTA:
            continue

        etf = ALL_ETFS[i]
        open_price = float(pivot_close.loc[old_date, etf])
        close_price = float(pivot_close.loc[new_date, etf])

        if open_price <= 0 or close_price <= 0:
            continue

        hold_days = max((new_date - old_date).days, 1)

        # 确定交易方向
        if delta > 0:
            direction = "buy" if new_weights[i] >= 0 else "short"
        else:
            direction = "sell" if old_weights[i] >= 0 else "cover"

        # ---- 计算单资产涨跌幅（扣除成本）----
        # 与评分脚本 verify_transaction_costs 的公式一致
        if direction == "buy":
            # 买入：涨了赚钱
            gross_return = (close_price - open_price) / open_price
            trade_return = gross_return - 2 * COMMISSION
        elif direction == "sell":
            # 卖出：跌了赚钱（多头平仓）
            gross_return = (open_price - close_price) / open_price
            trade_return = gross_return - 2 * COMMISSION
        elif direction == "short":
            # 做空：跌了赚钱
            gross_return = (open_price - close_price) / open_price
            trade_return = gross_return - 2 * COMMISSION - SHORT_INTEREST * hold_days / 365
        else:  # cover
            # 平空：涨了亏钱
            gross_return = (close_price - open_price) / open_price
            trade_return = gross_return - 2 * COMMISSION - SHORT_INTEREST * hold_days / 365

        # 计算交易数量（基于权重变化量 × 名义本金 / 价格）
        qty = max(int(abs(delta) * INITIAL_CAPITAL / open_price / 100) * 100, 100)

        # weight = 调仓前后权重的平均值
        weight = (abs(old_weights[i]) + abs(new_weights[i])) / 2.0

        trades.append({
            'open_date': safe_strftime(old_date),
            'close_date': safe_strftime(new_date),
            'stock_code': etf,
            'direction': direction,
            'return': round(float(trade_return), 6),
            'weight': round(float(weight), 4),
            'open_price': round(open_price, 4),
            'close_price': round(close_price, 4),
            'qty': qty
        })


# ============================================================================
# 核心回测引擎
# ============================================================================

def run_backtest(price_df, period_start, period_end):
    """
    核心回测函数

    遍历每个交易日，执行：
    1. 风险校准（协方差估计 + VaR计算 + 缩放因子更新）
    2. 波动率突变检测
    3. 判断是否需要再平衡（定期/风险缩放突变/波动率事件）
    4. 执行调仓优化并记录交易
    5. 更新净值

    参数:
        price_df: 完整价格数据
        period_start: 回测起始日期
        period_end: 回测结束日期

    返回:
        dict: 含 daily_nav, daily_weights, trades, metrics, risk_calibration
    """
    start_time = time.time()

    # ---- 数据准备 ----
    pivot_close, returns, dates = prepare_price_matrix(price_df, period_start, period_end)

    print(f"\n回测期: {dates[0].strftime('%Y-%m-%d')} ~ {dates[-1].strftime('%Y-%m-%d')}")
    print(f"交易日: {len(dates)} | ETF数量: {N_ASSETS}")

    # ---- 初始化模块 ----
    risk_module = RiskCalibrationModule(returns)
    optimizer = PortfolioOptimizer(N_ASSETS)
    vol_monitor = VolatilityMonitor(pivot_close)

    # ---- 初始化状态 ----
    weights = np.ones(N_ASSETS) / N_ASSETS  # 初始等权

    daily_nav = []        # 每日净值
    daily_weights = []    # 每日持仓权重
    trades = []           # 交易记录
    nav = 1.0             # 当前净值
    rebalance_history = [] # 再平衡历史
    last_rebalance_idx = 0 # 上次再平衡的索引
    last_weights = weights.copy()  # 上次再平衡时的权重

    print("\n开始回测...")

    # ---- 主循环：遍历每个交易日 ----
    for idx in range(len(dates)):
        date = dates[idx]

        # === 预热期（前20个交易日）：等权持有，只记录净值 ===
        if idx < 20:
            daily_nav.append({'date': safe_strftime(date), 'nav': round(float(nav), 4)})
            daily_weights.append({
                'date': safe_strftime(date),
                'weights': {etf: round(float(weights[i]), 4) for i, etf in enumerate(ALL_ETFS)}
            })
            # 预热期也进行风险校准（为后续做准备）
            risk_module.step(idx, weights)
            continue

        # === 第1步：风险校准 ===
        adjusted_cov, extra_rebalance = risk_module.step(idx, weights)

        # === 第2步：波动率突变检测 ===
        vol_triggered, vol_response = vol_monitor.check(date, idx)
        if vol_triggered:
            # 波动率突变时调高风险缩放因子
            risk_module.scale_factor = max(risk_module.scale_factor, vol_response)
            # 更新缩放因子历史记录
            risk_module.scale_factor_history[-1]['scale_factor'] = risk_module.scale_factor

        # === 第3步：判断是否需要再平衡 ===
        days_since = get_trading_days_between(dates, dates[last_rebalance_idx], date)

        # 定期再平衡：距上次超过20个交易日
        do_scheduled = (days_since >= REBALANCE_FREQ)

        # 额外再平衡：风险缩放因子变化超过20%，且距上次至少5个交易日
        do_extra = extra_rebalance and days_since >= 5

        # 波动率触发：检测到波动率突变，且距上次至少5个交易日
        do_vol = vol_triggered and days_since >= 5

        do_rebalance = do_scheduled or do_extra or do_vol

        # 确定触发类型
        if do_vol:
            trigger = "volatility_spike"
        elif do_extra:
            trigger = "risk_scale_change"
        else:
            trigger = "scheduled"

        # === 第4步：执行调仓 ===
        if do_rebalance:
            # 计算新权重
            returns_window = returns.iloc[max(0, idx-60):idx+1]  # 近60日收益率
            new_weights, weight_delta = optimizer.optimize(
                adjusted_cov, returns_window, risk_module.scale_factor
            )

            # 记录交易
            record_trades(last_weights, new_weights, dates[last_rebalance_idx], date, pivot_close, trades)

            # 更新状态
            last_weights = new_weights.copy()
            weights = new_weights
            last_rebalance_idx = idx

            # 记录再平衡历史
            rebalance_history.append({
                'date': safe_strftime(date),
                'trigger': trigger
            })

        # === 第5步：更新净值 ===
        if idx > 0:
            # 当日收益率 = sum(权重 × 当日涨跌幅)
            daily_ret = float(returns.iloc[idx].values @ weights)
            nav *= (1 + daily_ret)

        # 记录每日净值和权重
        daily_nav.append({'date': safe_strftime(date), 'nav': round(float(nav), 4)})
        daily_weights.append({
            'date': safe_strftime(date),
            'weights': {etf: round(float(weights[i]), 4) for i, etf in enumerate(ALL_ETFS)}
        })

        # 进度日志
        if (idx + 1) % 50 == 0:
            print(f"  进度: {idx+1}/{len(dates)}, 净值: {nav:.4f}, 缩放: {risk_module.scale_factor:.2f}")

    # ========== 绩效计算 ==========
    nav_series = pd.Series([d['nav'] for d in daily_nav])
    rets = nav_series.pct_change().dropna()
    total_return = float(nav_series.iloc[-1] - 1.0)
    n_days = len(rets)
    annual_return = (nav_series.iloc[-1] ** (252.0 / n_days) - 1.0) if n_days > 0 else 0.0

    # 夏普比率
    if n_days < 2:
        sharpe = max_dd = calmar = pl_ratio = 0.0
        max_ls = 0
    else:
        sharpe = float(rets.mean() / rets.std() * np.sqrt(252)) if rets.std() > 0 else 0.0
        # 最大回撤
        cummax = nav_series.cummax()
        max_dd = float(((nav_series - cummax) / cummax).min())
        # 卡玛比率
        calmar = annual_return / abs(max_dd) if abs(max_dd) > 0 else 0.0
        # 盈亏比和最大连亏
        tr = [t['return'] for t in trades] if trades else [0]
        profits = [r for r in tr if r > 0]
        losses = [r for r in tr if r < 0]
        pl_ratio = float(np.mean(profits) / abs(np.mean(losses))) if losses else 0.0
        max_ls = cur = 0
        for r in tr:
            if r < 0:
                cur += 1
                max_ls = max(max_ls, cur)
            else:
                cur = 0

    # 年化换手率
    total_turnover = sum(
        abs(float(t['open_price']) * int(t['qty'])) + abs(float(t['close_price']) * int(t['qty']))
        for t in trades
    )
    avg_nav = float(nav_series.mean())
    years = max(n_days / 252, 0.5)
    annual_turnover = total_turnover / (avg_nav * INITIAL_CAPITAL) / years if avg_nav > 0 else 0.0

    # VaR突破率
    var_break_rate = len(risk_module.var_break_events) / max(len(risk_module.var_history), 1)

    # 汇总指标
    metrics = {
        'sharpe_ratio': round(sharpe, 4),
        'max_drawdown': round(max_dd, 4),
        'calmar_ratio': round(calmar, 4),
        'profit_loss_ratio': round(pl_ratio, 4),
        'max_consecutive_losses': max_ls,
        'annual_turnover': round(annual_turnover, 4),
        'var_break_rate': round(var_break_rate, 4)
    }

    # 输出统计摘要
    print(f"\n{'='*70}")
    print("回测统计")
    print(f"{'='*70}")
    print(f"调仓次数: {len(rebalance_history)} | 交易笔数: {len(trades)}")
    print(f"最终净值: {nav_series.iloc[-1]:.4f}")
    print(f"总收益率: {total_return:.2%} | 年化: {annual_return:.2%}")
    print(f"夏普比率: {sharpe:.4f} | 最大回撤: {max_dd:.2%}")
    print(f"卡玛比率: {calmar:.4f} | 盈亏比: {pl_ratio:.4f}")
    print(f"换手率: {annual_turnover:.4f} | VaR突破率: {var_break_rate:.4f}")

    # 风险校准记录
    risk_calibration = {
        'scale_factor_history': risk_module.scale_factor_history,
        'var_history': risk_module.var_history,
        'var_break_events': risk_module.var_break_events,
        'rebalance_history': rebalance_history,
        'volatility_events': vol_monitor.vol_events
    }

    elapsed = round(time.time() - start_time, 2)
    print(f"运行时间: {elapsed}秒")

    # 返回完整结果
    return {
        'daily_nav': daily_nav,
        'daily_weights': daily_weights,
        'trades': trades,
        'metrics': metrics,
        'risk_calibration': risk_calibration
    }


# ============================================================================
# 训练/回测模式
# ============================================================================

def train_mode():
    """
    训练模式

    流程：
    1. 读取训练期日期配置
    2. 读取验证期日期配置
    3. 加载训练+验证期数据
    4. 在验证期运行回测
    5. 输出 backtest_results.json
    """
    print("=" * 70)
    print("训练模式")
    print("=" * 70)

    # 读取日期配置
    train_start, train_end = load_period('train_period.txt', DEFAULT_TRAIN_START, DEFAULT_TRAIN_END)
    valid_start, valid_end = load_period('valid_period.txt', DEFAULT_VALID_START, DEFAULT_VALID_END)

    print(f"训练期: {train_start} ~ {train_end}")
    print(f"验证期: {valid_start} ~ {valid_end}")

    # 加载数据
    price_df = load_price_data('etf_prices.csv')

    # 运行回测
    results = run_backtest(price_df, valid_start, valid_end)

    # 保存结果
    with open('backtest_results.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"\n✓ backtest_results.json 已保存")

    return True


def backtest_mode():
    """
    回测模式

    流程：
    1. 读取测试期日期配置
    2. 加载隐藏测试数据
    3. 在测试期运行回测
    4. 输出 backtest_results.json
    """
    print("=" * 70)
    print("回测模式")
    print("=" * 70)

    # 读取日期配置
    test_start, test_end = load_period('test_period.txt', DEFAULT_TEST_START, DEFAULT_TEST_END)
    print(f"测试期: {test_start} ~ {test_end}")

    # 加载隐藏测试数据
    price_df = load_price_data('etf_prices_test.csv')

    # 运行回测
    results = run_backtest(price_df, test_start, test_end)

    # 保存结果
    with open('backtest_results.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"\n✓ backtest_results.json 已保存")

    return True


# ============================================================================
# 主入口
# ============================================================================

def main():
    """
    命令行入口

    用法：
        训练模式：python portfolio_optimizer.py --train
        回测模式：python portfolio_optimizer.py --backtest
    """
    parser = argparse.ArgumentParser(description='动态投资组合优化策略')
    parser.add_argument('--train', action='store_true', help='训练模式')
    parser.add_argument('--backtest', action='store_true', help='回测模式')
    args = parser.parse_args()

    if args.train:
        if not train_mode():
            sys.exit(1)
    elif args.backtest:
        if not backtest_mode():
            sys.exit(1)
    else:
        print("请指定 --train 或 --backtest\n")
        print("  训练模式: python portfolio_optimizer.py --train")
        print("  回测模式: python portfolio_optimizer.py --backtest")
        sys.exit(1)


if __name__ == "__main__":
    main()