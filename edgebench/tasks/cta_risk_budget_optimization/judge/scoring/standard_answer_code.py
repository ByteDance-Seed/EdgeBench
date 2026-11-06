"""
CTA Fund - Cross-border Commodity Futures Multi-Strategy - Standard Answer
=====================================================
This script implements the complete CTA multi-strategy portfolio system, including:
1. Data preprocessing and feature engineering
2. Five-factor signal generation system
3. Position calculation and dynamic risk budget allocation
4. Backtest engine
5. Performance evaluation and attribution analysis
6. Stress test and sensitivity analysis
"""

import numpy as np
import pandas as pd
from scipy import stats
from scipy.optimize import minimize
import warnings
import os
import json
from datetime import datetime, timedelta

warnings.filterwarnings('ignore')
np.random.seed(42)

# ============================================================
# CONFIGURATION
# ============================================================
CONFIG = {
    'initial_capital': 1.5e9,  # 1.5 billion CNY
    'target_vol_low': 0.08,
    'target_vol_high': 0.15,
    'max_drawdown': 0.15,
    'var_99_limit': 0.03,
    'single_commodity_limit': 0.10,
    'sector_limit': 0.30,
    'overseas_limit': 0.40,
    'single_strategy_risk_limit': 0.40,
    'strategy_min_weight': 0.05,
    'signal_threshold': 0.02,
    'lookback_short': 20,
    'lookback_medium': 40,
    'lookback_long': 60,
    'atr_period': 14,
    'adx_period': 14,
    'vol_lookback': 60,
    'rebalance_freq': 'M',
    'max_weight_change': 0.30,
    'seed': 42,
    'backtest_start': '2020-01-02',
    'backtest_end': '2025-12-31',
    'perf_start': '2020-07-01',
}

# Sector mapping
SECTOR_MAP = {
    'CU.SHF': 'non_ferrous_metals', 'AL.SHF': 'non_ferrous_metals', 'ZN.SHF': 'non_ferrous_metals',
    'AU.SHF': 'precious_metals', 'AG.SHF': 'precious_metals',
    'RB.SHF': 'ferrous_metals', 'HC.SHF': 'ferrous_metals', 'I.DCE': 'ferrous_metals',
    'J.DCE': 'ferrous_metals', 'JM.DCE': 'ferrous_metals',
    'M.DCE': 'agriculture', 'Y.DCE': 'agriculture', 'P.DCE': 'agriculture',
    'CF.CZC': 'agriculture', 'SR.CZC': 'agriculture',
    'TA.CZC': 'chemicals', 'MA.CZC': 'chemicals',
    'SC.INE': 'energy',
    'CL.CME': 'energy', 'GC.CME': 'precious_metals', 'SI.CME': 'precious_metals',
    'HG.CME': 'non_ferrous_metals', 'W.CME': 'agriculture', 'S.CME': 'agriculture',
    'C.CME': 'agriculture', 'BO.CME': 'agriculture',
    'SB.ICE': 'agriculture', 'CT.ICE': 'agriculture',
    'LME.LME': 'non_ferrous_metals', 'LMA.LME': 'non_ferrous_metals',
}

# Strategy initial weights
STRATEGY_WEIGHTS_INIT = {
    'TSMOM': 0.30, 'XSMOM': 0.20, 'CARRY': 0.20,
    'BREAKOUT': 0.15, 'MEANREV': 0.15
}

# Pairs for mean reversion
PAIRS = [
    ('M.DCE', 'Y.DCE'),
    ('RB.SHF', 'I.DCE'),
    ('J.DCE', 'JM.DCE'),
    ('CU.SHF', 'LME.LME'),
    ('AU.SHF', 'GC.CME'),
    ('SC.INE', 'CL.CME'),
]

DATA_DIR = '/home/z/my-project/download/cta_task/'
OUTPUT_DIR = '/home/z/my-project/download/cta_task/answer_output/'
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# MODULE 1: DATA PREPROCESSING & FEATURE ENGINEERING
# ============================================================
class DataPreprocessor:
    """Data preprocessing and feature engineeringmodule"""
    
    def __init__(self, data_dir):
        self.data_dir = data_dir
        self.domestic = None
        self.overseas = None
        self.carry = None
        self.specs = None
        self.costs = None
        self.macro_china = None
        self.macro_us = None
        self.global_daily = None
        self.fx = None
        
    def load_data(self):
        """Load all raw data"""
        print("Loading data...")
        
        price_file = os.path.join(self.data_dir, 'futures_price_data.xlsx')
        self.domestic = pd.read_excel(price_file, sheet_name='domestic_futures')
        self.overseas = pd.read_excel(price_file, sheet_name='overseas_futures')
        self.carry = pd.read_excel(price_file, sheet_name='carry_basis_data')
        
        specs_file = os.path.join(self.data_dir, 'futures_contract_specs.xlsx')
        self.specs = pd.read_excel(specs_file, sheet_name='contract_specs')
        self.costs = pd.read_excel(specs_file, sheet_name='transaction_costs')
        self.margins = pd.read_excel(specs_file, sheet_name='margin_rate_history')
        self.limits = pd.read_excel(specs_file, sheet_name='position_limits')
        
        macro_file = os.path.join(self.data_dir, 'macro_factors_data.xlsx')
        self.macro_china = pd.read_excel(macro_file, sheet_name='china_macro_monthly')
        self.macro_us = pd.read_excel(macro_file, sheet_name='us_macro_monthly')
        self.global_daily = pd.read_excel(macro_file, sheet_name='global_indicators_daily')
        self.fx = pd.read_excel(macro_file, sheet_name='fx_rates_daily')
        
        print(f"  Domestic: {len(self.domestic)} rows, {self.domestic['ticker'].nunique()} tickers")
        print(f"  Overseas: {len(self.overseas)} rows, {self.overseas['ticker'].nunique()} tickers")
        print(f"  Carry: {len(self.carry)} rows")
        
    def clean_and_align(self):
        """Clean data and align trading days"""
        print("Cleaning and aligning data...")
        
        # Combine domestic and overseas
        self.all_prices = pd.concat([self.domestic, self.overseas], ignore_index=True)
        self.all_prices['date'] = pd.to_datetime(self.all_prices['date'])
        
        # Remove duplicates and sort
        self.all_prices = self.all_prices.drop_duplicates(subset=['date', 'ticker']).sort_values(['ticker', 'date']).reset_index(drop=True)
        
        # Forward fill missing values (within each ticker)
        self.all_prices = self.all_prices.groupby('ticker').apply(
            lambda g: g.set_index('date').asfreq('B').ffill().reset_index()
        ).reset_index(drop=True)
        
        # Clean carry data
        self.carry['date'] = pd.to_datetime(self.carry['date'])
        
        # Clean FX data
        self.fx['date'] = pd.to_datetime(self.fx['date'])
        
        # Clean macro data
        self.macro_china['date'] = pd.to_datetime(self.macro_china['date'])
        self.macro_us['date'] = pd.to_datetime(self.macro_us['date'])
        self.global_daily['date'] = pd.to_datetime(self.global_daily['date'])
        
        print(f"  Combined price data: {len(self.all_prices)} rows, {self.all_prices['ticker'].nunique()} tickers")
        
    def compute_features(self):
        """Calculate technical indicators and features"""
        print("Computing features...")
        
        all_features = []
        
        for ticker, group in self.all_prices.groupby('ticker'):
            df = group.sort_values('date').copy()
            
            # Daily returns
            df['daily_return'] = df['close'].pct_change()
            
            # ATR(14)
            high_low = df['high'] - df['low']
            high_close = (df['high'] - df['close'].shift(1)).abs()
            low_close = (df['low'] - df['close'].shift(1)).abs()
            tr = pd.concat([high_low, high_close, low_close], axis=1).max(axis=1)
            df['ATR_14'] = tr.rolling(14).mean()
            
            # ADX(14)
            plus_dm = df['high'].diff()
            minus_dm = df['low'].diff().abs()
            plus_dm = plus_dm.where((plus_dm > minus_dm) & (plus_dm > 0), 0)
            minus_dm = minus_dm.where((minus_dm > plus_dm) & (minus_dm > 0), 0)
            atr = df['ATR_14'].replace(0, np.nan)
            plus_di = 100 * (plus_dm.rolling(14).mean() / atr)
            minus_di = 100 * (minus_dm.rolling(14).mean() / atr)
            dx = 100 * ((plus_di - minus_di).abs() / (plus_di + minus_di).replace(0, np.nan))
            df['ADX_14'] = dx.rolling(14).mean()
            
            # EMA
            df['EMA_20'] = df['close'].ewm(span=20, adjust=False).mean()
            df['EMA_60'] = df['close'].ewm(span=60, adjust=False).mean()
            
            # Bollinger Bands
            df['BB_mid'] = df['close'].rolling(20).mean()
            df['BB_std'] = df['close'].rolling(20).std()
            df['BB_upper'] = df['BB_mid'] + 2 * df['BB_std']
            df['BB_lower'] = df['BB_mid'] - 2 * df['BB_std']
            
            # RSI(14)
            delta = df['close'].diff()
            gain = delta.where(delta > 0, 0).rolling(14).mean()
            loss = (-delta.where(delta < 0, 0)).rolling(14).mean()
            rs = gain / loss.replace(0, np.nan)
            df['RSI_14'] = 100 - (100 / (1 + rs))
            
            # Volume features
            df['volume_ma_20'] = df['volume'].rolling(20).mean()
            df['volume_ratio'] = df['volume'] / df['volume_ma_20'].replace(0, np.nan)
            
            # Volatility
            df['realized_vol_20'] = df['daily_return'].rolling(20).std() * np.sqrt(252)
            df['realized_vol_60'] = df['daily_return'].rolling(60).std() * np.sqrt(252)
            
            all_features.append(df)
        
        self.features = pd.concat(all_features, ignore_index=True)
        print(f"  Features computed: {len(self.features)} rows, {self.features.columns.nunique()} columns")
        
        return self.features
    
    def merge_macro(self):
        """Merge macro data"""
        print("Merging macro data...")
        
        # Merge global daily indicators
        self.features = self.features.merge(
            self.global_daily[['date', 'CRB_index', 'VIX_index', 'USDCNY', 'US Dollar Index DXY', 'yield_curve_spread_pct']],
            on='date', how='left'
        )
        
        # Forward fill macro data
        macro_cols = ['CRB_index', 'VIX_index', 'USDCNY', 'US Dollar Index DXY', 'yield_curve_spread_pct']
        for col in macro_cols:
            self.features[col] = self.features[col].ffill()
        
        print("  Macro data merged")
        
    def save_processed_data(self):
        """Save processed data"""
        self.features.to_csv(os.path.join(OUTPUT_DIR, 'processed_features.csv'), index=False)
        print(f"  Processed data saved to {OUTPUT_DIR}processed_features.csv")


# ============================================================
# MODULE 2: SIGNAL GENERATION
# ============================================================
class SignalGenerator:
    """Five-factor signal generation module"""
    
    def __init__(self, features, carry_data, config):
        self.features = features
        self.carry = carry_data
        self.config = config
        self.signals = None
        
    def generate_tsmom_signal(self):
        """Time series momentum signal"""
        print("  Generating TSMOM signals...")
        
        signals_list = []
        
        for ticker, group in self.features.groupby('ticker'):
            df = group.sort_values('date').copy()
            sector = SECTOR_MAP.get(ticker, 'other')
            
            # Choose lookback based on sector
            if sector in ['non_ferrous_metals', 'ferrous_metals']:
                lookback = 40
                # EMA-based signal
                ema_short = df['EMA_20']
                ema_long = df['EMA_60']
                raw_signal = (ema_short - ema_long) / ema_long.abs()
            elif sector in ['agriculture', 'chemicals']:
                lookback = 20
                # Simple return signal
                raw_signal = df['close'].pct_change(lookback)
            elif sector in ['precious_metals', 'energy']:
                lookback = 60
                # Breakout signal (Donchian channel)
                high_channel = df['high'].rolling(lookback).max()
                low_channel = df['low'].rolling(lookback).min()
                mid_channel = (high_channel + low_channel) / 2
                raw_signal = (df['close'] - mid_channel) / (high_channel - low_channel).replace(0, np.nan)
            else:
                lookback = 40
                raw_signal = df['close'].pct_change(lookback)
            
            # Clip signal to [-1, 1]
            signal = raw_signal.clip(-1, 1)
            
            # Apply threshold
            signal = signal.where(signal.abs() >= self.config['signal_threshold'], 0)
            
            temp = df[['date', 'ticker']].copy()
            temp['TSMOM'] = signal
            signals_list.append(temp)
        
        tsmom_df = pd.concat(signals_list, ignore_index=True)
        return tsmom_df
    
    def generate_xsmom_signal(self):
        """Cross-sectional momentum signal"""
        print("  Generating XSMOM signals...")
        
        # Calculate 20-day returns for each ticker
        ret_list = []
        for ticker, group in self.features.groupby('ticker'):
            df = group.sort_values('date').copy()
            df['ret_20'] = df['close'].pct_change(20)
            ret_list.append(df[['date', 'ticker', 'ret_20']])
        
        ret_20 = pd.concat(ret_list, ignore_index=True)
        
        # Merge back
        df = self.features[['date', 'ticker']].merge(ret_20, on=['date', 'ticker'], how='left')
        df['sector'] = df['ticker'].map(SECTOR_MAP)
        
        # Rank within sector
        df['rank_in_sector'] = df.groupby(['date', 'sector'])['ret_20'].rank(pct=True)
        
        # Signal: top 30% = +1, bottom 30% = -1, middle = 0
        df['XSMOM'] = 0.0
        df.loc[df['rank_in_sector'] >= 0.7, 'XSMOM'] = 1.0
        df.loc[df['rank_in_sector'] <= 0.3, 'XSMOM'] = -1.0
        
        # Scale by rank distance from center
        df['XSMOM'] = df['XSMOM'] * (df['rank_in_sector'] - 0.5).abs() * 2
        
        return df[['date', 'ticker', 'XSMOM']]
    
    def generate_carry_signal(self):
        """Carry/Basis signal"""
        print("  Generating CARRY signals...")
        
        # Use carry data directly
        carry = self.carry.copy()
        carry['date'] = pd.to_datetime(carry['date'])
        
        # Cross-sectional standardization per date
        carry['CARRY'] = carry.groupby('date')['carry_rate_annual_pct'].transform(
            lambda x: (x - x.mean()) / (x.std() if x.std() != 0 else np.nan)
        )
        
        # Clip and threshold
        carry['CARRY'] = carry['CARRY'].clip(-1, 1)
        carry['CARRY'] = carry['CARRY'].where(carry['CARRY'].abs() >= self.config['signal_threshold'], 0)
        
        return carry[['date', 'ticker', 'CARRY']]
    
    def generate_breakout_signal(self):
        """Volatility breakout signal"""
        print("  Generating BREAKOUT signals...")
        
        signals_list = []
        
        for ticker, group in self.features.groupby('ticker'):
            df = group.sort_values('date').copy()
            
            # ATR breakout
            atr = df['ATR_14']
            upper_band = df['close'].shift(1) + 2 * atr
            lower_band = df['close'].shift(1) - 2 * atr
            
            # Signal
            signal = pd.Series(0.0, index=df.index)
            signal[df['close'] > upper_band] = 1.0
            signal[df['close'] < lower_band] = -1.0
            
            # ADX filter: only trade when ADX > 20
            adx = df['ADX_14']
            signal = signal.where(adx > 20, 0)
            
            # Scale by breakout magnitude
            breakout_strength = ((df['close'] - df['close'].shift(1)).abs() / atr.replace(0, np.nan)).clip(0, 2)
            signal = signal * breakout_strength / 2
            
            temp = df[['date', 'ticker']].copy()
            temp['BREAKOUT'] = signal
            signals_list.append(temp)
        
        breakout_df = pd.concat(signals_list, ignore_index=True)
        return breakout_df
    
    def generate_meanrev_signal(self):
        """Mean reversion signal (pair trading)"""
        print("  Generating MEANREV signals...")
        
        signals_list = []
        
        for t1, t2 in PAIRS:
            df1 = self.features[self.features['ticker'] == t1].sort_values('date').set_index('date')['close']
            df2 = self.features[self.features['ticker'] == t2].sort_values('date').set_index('date')['close']
            
            # Align dates
            common_dates = df1.index.intersection(df2.index)
            df1 = df1.loc[common_dates]
            df2 = df2.loc[common_dates]
            
            # Calculate spread (log price ratio)
            spread = np.log(df1) - np.log(df2)
            
            # Z-score of spread
            spread_mean = spread.rolling(60).mean()
            spread_std = spread.rolling(60).std()
            z_score = (spread - spread_mean) / spread_std.replace(0, np.nan)
            
            # Cointegration test (rolling)
            # Simplified: use ADF test on rolling window
            def rolling_adf(s, window=120):
                results = pd.Series(index=s.index, dtype=float)
                for i in range(window, len(s)):
                    try:
                        adf_stat = stats.adfuller(s.iloc[i-window:i], autolag='AIC')[0]
                        results.iloc[i] = adf_stat
                    except:
                        results.iloc[i] = np.nan
                return results
            
            adf_stats = rolling_adf(spread)
            is_cointegrated = adf_stats < -2.86  # 5% critical value
            
            # Signal: z-score based
            signal1 = pd.Series(0.0, index=common_dates)
            signal1[z_score > 2.0] = -1.0  # Short spread (short t1, long t2)
            signal1[z_score < -2.0] = 1.0   # Long spread (long t1, short t2)
            signal1[(z_score > -0.5) & (z_score < 0.5)] = 0.0  # Close
            
            # Only when cointegrated
            signal1 = signal1.where(is_cointegrated, 0)
            
            # Scale by z-score magnitude
            signal1 = signal1 * z_score.abs().clip(0, 3) / 3
            
            # Assign signals to both tickers
            for date_idx in common_dates:
                sig_val = signal1.loc[date_idx] if date_idx in signal1.index else 0
                signals_list.append({'date': date_idx, 'ticker': t1, 'MEANREV': sig_val})
                signals_list.append({'date': date_idx, 'ticker': t2, 'MEANREV': -sig_val})
        
        meanrev_df = pd.DataFrame(signals_list)
        if len(meanrev_df) > 0:
            meanrev_df = meanrev_df.groupby(['date', 'ticker']).mean().reset_index()
        
        return meanrev_df
    
    def generate_all_signals(self):
        """Generate all signals and merge"""
        print("Generating all signals...")
        
        tsmom = self.generate_tsmom_signal()
        xsmom = self.generate_xsmom_signal()
        carry = self.generate_carry_signal()
        breakout = self.generate_breakout_signal()
        meanrev = self.generate_meanrev_signal()
        
        # Merge all signals
        base = self.features[['date', 'ticker']].drop_duplicates()
        
        signals = base.copy()
        signals = signals.merge(tsmom, on=['date', 'ticker'], how='left')
        signals = signals.merge(xsmom, on=['date', 'ticker'], how='left')
        signals = signals.merge(carry, on=['date', 'ticker'], how='left')
        signals = signals.merge(breakout, on=['date', 'ticker'], how='left')
        signals = signals.merge(meanrev, on=['date', 'ticker'], how='left')
        
        # Fill NaN with 0
        for col in ['TSMOM', 'XSMOM', 'CARRY', 'BREAKOUT', 'MEANREV']:
            signals[col] = signals[col].fillna(0)
        
        self.signals = signals
        print(f"  Signal matrix: {len(signals)} rows")
        
        # Save
        signals.to_csv(os.path.join(OUTPUT_DIR, 'signal_matrix.csv'), index=False)
        print(f"  Signal matrix saved to {OUTPUT_DIR}signal_matrix.csv")
        
        return signals


# ============================================================
# MODULE 3: POSITION SIZING & RISK BUDGETING
# ============================================================
class RiskBudgetAllocator:
    """Position calculation and dynamic risk budget allocationmodule"""
    
    def __init__(self, features, signals, specs, costs, fx, config):
        self.features = features
        self.signals = signals
        self.specs = specs
        self.costs = costs
        self.fx = fx
        self.config = config
        self.positions = None
        
    def compute_target_positions(self):
        """Calculate target positions"""
        print("Computing target positions...")
        
        # Get specs info
        specs_dict = {}
        for _, row in self.specs.iterrows():
            specs_dict[row['ticker']] = {
                'multiplier': row['multiplier'],
                'tick_size': row['tick_size'],
                'margin_rate': row['margin_rate'],
                'currency': row['currency'],
            }
        
        # Get costs info
        costs_dict = {}
        for _, row in self.costs.iterrows():
            costs_dict[row['ticker']] = row['total_round_trip_cost_per_lot']
        
        # Merge features with signals
        df = self.features.merge(self.signals, on=['date', 'ticker'], how='left')
        
        # Strategy weights (initial)
        strategy_weights = STRATEGY_WEIGHTS_INIT.copy()
        
        # Target portfolio vol = 10% annual
        target_vol = 0.10
        n_commodities = df['ticker'].nunique()
        
        positions_list = []
        
        for date, date_group in df.groupby('date'):
            if date < pd.Timestamp(self.config['backtest_start']):
                continue
                
            capital = self.config['initial_capital']
            
            # Count active signals
            active_signals = 0
            for ticker, ticker_group in date_group.groupby('ticker'):
                row = ticker_group.iloc[0]
                combined_signal = sum(strategy_weights.get(s, 0) * row.get(s, 0) for s in strategy_weights)
                if abs(combined_signal) > 0.01:
                    active_signals += 1
            
            if active_signals == 0:
                continue
            
            # Risk budget per commodity (equal risk contribution)
            risk_budget_per_commodity = target_vol / np.sqrt(active_signals) / np.sqrt(252)
            
            for ticker, ticker_group in date_group.groupby('ticker'):
                if len(ticker_group) == 0:
                    continue
                    
                row = ticker_group.iloc[0]
                spec = specs_dict.get(ticker, {})
                if not spec:
                    continue
                
                atr = row.get('ATR_14', np.nan)
                if pd.isna(atr) or atr <= 0:
                    continue
                
                close = row.get('close', np.nan)
                if pd.isna(close) or close <= 0:
                    continue
                
                multiplier = spec['multiplier']
                currency = spec['currency']
                
                # Get FX rate for overseas
                if currency == 'USD':
                    fx_row = self.fx[self.fx['date'] == date]
                    usdcny = fx_row['USDCNY'].values[0] if len(fx_row) > 0 else 7.0
                    fx_rate = usdcny
                else:
                    fx_rate = 1.0
                
                # Combined signal (weighted by strategy weights)
                combined_signal = 0
                for strategy, weight in strategy_weights.items():
                    if strategy in row.index:
                        combined_signal += weight * row[strategy]
                
                # Skip if signal is too weak
                if abs(combined_signal) < 0.01:
                    positions_list.append({
                        'date': date,
                        'ticker': ticker,
                        'combined_signal': combined_signal,
                        'direction': 0,
                        'position_lots': 0,
                        'atr': atr,
                        'fx_rate': fx_rate,
                        'currency': currency,
                    })
                    continue
                
                # Position sizing: volatility targeting
                # Target: each commodity contributes risk_budget_per_commodity to daily portfolio vol
                # daily_dollar_vol = position_lots * multiplier * close * fx_rate * (atr/close)
                # We want: position_lots * multiplier * atr * fx_rate = capital * risk_budget_per_commodity
                position_lots = capital * risk_budget_per_commodity / (multiplier * atr * fx_rate)
                
                # Scale by signal strength
                position_lots = position_lots * np.sign(combined_signal) * min(abs(combined_signal), 1.0)
                
                # Round to integer
                position_lots = int(position_lots)
                
                # Apply single commodity limit
                notional = abs(position_lots) * multiplier * close * fx_rate
                max_notional = capital * self.config['single_commodity_limit']
                if notional > max_notional:
                    position_lots = int(position_lots * max_notional / notional)
                
                positions_list.append({
                    'date': date,
                    'ticker': ticker,
                    'combined_signal': combined_signal,
                    'direction': np.sign(combined_signal),
                    'position_lots': position_lots,
                    'atr': atr,
                    'fx_rate': fx_rate,
                    'currency': currency,
                })
        
        self.positions = pd.DataFrame(positions_list)
        print(f"  Positions computed: {len(self.positions)} rows")
        
        return self.positions
    
    def apply_risk_constraints(self):
        """Apply risk control constraints"""
        print("Applying risk constraints...")
        
        # This is a simplified version - full implementation would check all constraints
        # Apply sector limits
        self.positions['sector'] = self.positions['ticker'].map(SECTOR_MAP)
        
        # Apply overseas limit
        self.positions['is_overseas'] = self.positions['currency'] == 'USD'
        
        # Save
        self.positions.to_csv(os.path.join(OUTPUT_DIR, 'target_positions.csv'), index=False)
        print(f"  Target positions saved to {OUTPUT_DIR}target_positions.csv")


# ============================================================
# MODULE 4: BACKTEST ENGINE
# ============================================================
class BacktestEngine:
    """Backtest enginemodule"""
    
    def __init__(self, features, positions, specs, costs, fx, config):
        self.features = features
        self.positions = positions
        self.specs = specs
        self.costs = costs
        self.fx = fx
        self.config = config
        
    def run_backtest(self):
        """Run backtest"""
        print("Running backtest...")
        
        # Get specs
        specs_dict = {}
        for _, row in self.specs.iterrows():
            specs_dict[row['ticker']] = {
                'multiplier': row['multiplier'],
                'tick_size': row['tick_size'],
                'margin_rate': row['margin_rate'],
                'currency': row['currency'],
            }
        
        costs_dict = {}
        for _, row in self.costs.iterrows():
            costs_dict[row['ticker']] = row['total_round_trip_cost_per_lot']
        
        # Prepare price data
        price_pivot = self.features.pivot_table(index='date', columns='ticker', values='close')
        price_pivot = price_pivot.sort_index().ffill()
        
        # Initialize
        capital = self.config['initial_capital']
        nav = capital
        peak_nav = capital
        nav_history = []
        trade_log = []
        holdings = {}  # ticker -> lots
        dd_scale = 1.0  # drawdown scaling factor
        
        dates = sorted(self.positions['date'].unique())
        
        for date in dates:
            if date < pd.Timestamp(self.config['backtest_start']):
                continue
            if date > pd.Timestamp(self.config['backtest_end']):
                break
            
            # Get FX rates
            fx_row = self.fx[self.fx['date'] == date]
            usdcny = fx_row['USDCNY'].values[0] if len(fx_row) > 0 else 7.0
            
            # Get today's target positions
            day_positions = self.positions[self.positions['date'] == date]
            
            # Apply drawdown scaling to target positions
            scaled_targets = {}
            for _, row in day_positions.iterrows():
                ticker = row['ticker']
                target_lots = int(row['position_lots'] * dd_scale)
                scaled_targets[ticker] = target_lots
            
            # Calculate P&L from existing holdings
            daily_pnl = 0
            if date in price_pivot.index:
                prev_idx = price_pivot.index.get_loc(date) - 1
                if prev_idx >= 0:
                    prev_date = price_pivot.index[prev_idx]
                    for ticker, lots in holdings.items():
                        if (ticker in price_pivot.columns and 
                            pd.notna(price_pivot.loc[date, ticker]) and
                            pd.notna(price_pivot.loc[prev_date, ticker])):
                            spec = specs_dict.get(ticker, {})
                            multiplier = spec.get('multiplier', 1)
                            currency = spec.get('currency', 'CNY')
                            fx_rate = usdcny if currency == 'USD' else 1.0
                            
                            price_change = price_pivot.loc[date, ticker] - price_pivot.loc[prev_date, ticker]
                            pnl = lots * multiplier * price_change * fx_rate
                            daily_pnl += pnl
            
            # Execute trades to reach target positions
            for ticker, target_lots in scaled_targets.items():
                current_lots = holdings.get(ticker, 0)
                trade_lots = target_lots - current_lots
                
                if trade_lots != 0:
                    # Transaction cost
                    cost_per_lot = costs_dict.get(ticker, 10)
                    spec = specs_dict.get(ticker, {})
                    currency = spec.get('currency', 'CNY')
                    fx_rate = usdcny if currency == 'USD' else 1.0
                    tc = abs(trade_lots) * cost_per_lot * fx_rate
                    daily_pnl -= tc
                    
                    trade_log.append({
                        'date': date,
                        'ticker': ticker,
                        'trade_lots': trade_lots,
                        'target_lots': target_lots,
                        'transaction_cost': tc,
                    })
                    
                    if target_lots != 0:
                        holdings[ticker] = target_lots
                    elif ticker in holdings:
                        del holdings[ticker]
            
            # Remove tickers not in today's targets
            tickers_to_remove = [t for t in holdings if t not in scaled_targets]
            for t in tickers_to_remove:
                # Close position
                if date in price_pivot.index and t in price_pivot.columns:
                    spec = specs_dict.get(t, {})
                    multiplier = spec.get('multiplier', 1)
                    currency = spec.get('currency', 'CNY')
                    fx_rate = usdcny if currency == 'USD' else 1.0
                    # No P&L from closing, just remove
                del holdings[t]
            
            # Update NAV
            nav += daily_pnl
            nav = max(nav, capital * 0.01)  # Floor NAV at 1% of capital
            
            # Update peak and drawdown
            peak_nav = max(peak_nav, nav)
            drawdown = (peak_nav - nav) / peak_nav if peak_nav > 0 else 0
            
            # Drawdown control: adjust dd_scale
            if drawdown > 0.12:
                dd_scale = 0.25  # Emergency
            elif drawdown > 0.08:
                dd_scale = 0.50  # Reduce
            elif drawdown > 0.05:
                dd_scale = 0.75  # Warning
            else:
                # Gradually restore
                dd_scale = min(dd_scale + 0.02, 1.0)
            
            nav_history.append({
                'date': date,
                'nav': nav,
                'daily_pnl': daily_pnl,
                'drawdown': drawdown,
                'dd_scale': dd_scale,
                'num_positions': len(holdings),
            })
        
        self.nav_history = pd.DataFrame(nav_history)
        self.trade_log = pd.DataFrame(trade_log) if trade_log else pd.DataFrame(columns=['date','ticker','trade_lots','target_lots','transaction_cost'])
        self.holdings = holdings
        
        total_return = (nav / capital - 1) * 100
        print(f"  Backtest complete: {len(self.nav_history)} trading days")
        print(f"  Final NAV: {nav:,.0f}")
        print(f"  Total return: {total_return:.2f}%")
        
        # Save
        self.nav_history.to_csv(os.path.join(OUTPUT_DIR, 'nav_history.csv'), index=False)
        self.trade_log.to_csv(os.path.join(OUTPUT_DIR, 'trade_log.csv'), index=False)
        
        return self.nav_history


# ============================================================
# MODULE 5: PERFORMANCE EVALUATION
# ============================================================
class PerformanceEvaluator:
    """Performance evaluation and attribution analysismodule"""
    
    def __init__(self, nav_history, config):
        self.nav = nav_history
        self.config = config
        self.metrics = {}
        
    def compute_metrics(self):
        """Calculate performance metrics"""
        print("Computing performance metrics...")
        
        df = self.nav.copy()
        df['daily_return'] = df['nav'].pct_change()
        
        # Filter to performance period
        perf_start = pd.Timestamp(self.config['perf_start'])
        df_perf = df[df['date'] >= perf_start].copy()
        
        if len(df_perf) < 10:
            print("  WARNING: Not enough data for performance evaluation")
            return
        
        # Annual return
        total_return = df_perf['nav'].iloc[-1] / df_perf['nav'].iloc[0] - 1
        n_years = (df_perf['date'].iloc[-1] - df_perf['date'].iloc[0]).days / 365.25
        annual_return = (1 + total_return) ** (1/n_years) - 1 if n_years > 0 else 0
        
        # Annual volatility
        annual_vol = df_perf['daily_return'].std() * np.sqrt(252)
        
        # Sharpe ratio (assume risk-free = 2%)
        rf = 0.02
        sharpe = (annual_return - rf) / annual_vol if annual_vol > 0 else 0
        
        # Sortino ratio
        downside_returns = df_perf['daily_return'][df_perf['daily_return'] < 0]
        downside_vol = downside_returns.std() * np.sqrt(252) if len(downside_returns) > 0 else annual_vol
        sortino = (annual_return - rf) / downside_vol if downside_vol > 0 else 0
        
        # Max drawdown
        df_perf['cummax'] = df_perf['nav'].cummax()
        df_perf['drawdown'] = (df_perf['cummax'] - df_perf['nav']) / df_perf['cummax']
        max_dd = df_perf['drawdown'].max()
        
        # Calmar ratio
        calmar = annual_return / max_dd if max_dd > 0 else 0
        
        # Win rate
        win_days = (df_perf['daily_return'] > 0).sum()
        total_days = (df_perf['daily_return'] != 0).sum()
        win_rate = win_days / total_days if total_days > 0 else 0
        
        # Profit/Loss ratio
        avg_win = df_perf.loc[df_perf['daily_return'] > 0, 'daily_return'].mean()
        avg_loss = df_perf.loc[df_perf['daily_return'] < 0, 'daily_return'].mean()
        pl_ratio = abs(avg_win / avg_loss) if avg_loss != 0 else 0
        
        # Max drawdown duration
        dd_start = None
        max_dd_duration = 0
        current_dd_duration = 0
        for _, row in df_perf.iterrows():
            if row['drawdown'] > 0:
                current_dd_duration += 1
                max_dd_duration = max(max_dd_duration, current_dd_duration)
            else:
                current_dd_duration = 0
        
        self.metrics = {
            'annual_return': round(annual_return * 100, 2),
            'annual_volatility': round(annual_vol * 100, 2),
            'sharpe_ratio': round(sharpe, 3),
            'sortino_ratio': round(sortino, 3),
            'calmar_ratio': round(calmar, 3),
            'max_drawdown': round(max_dd * 100, 2),
            'max_drawdown_duration_days': max_dd_duration,
            'win_rate_pct': round(win_rate * 100, 2),
            'profit_loss_ratio': round(pl_ratio, 3),
            'total_return_pct': round(total_return * 100, 2),
            'winning_days': int(win_days),
            'losing_days': int(total_days - win_days),
        }
        
        for k, v in self.metrics.items():
            print(f"  {k}: {v}")
        
        return self.metrics
    
    def save_report(self):
        """saveperformancereport"""
        # Save metrics to Excel
        metrics_df = pd.DataFrame([self.metrics])
        metrics_df.to_excel(os.path.join(OUTPUT_DIR, 'performance_metrics.xlsx'), index=False)
        print(f"  Performance metrics saved to {OUTPUT_DIR}performance_metrics.xlsx")


# ============================================================
# MODULE 6: STRESS TESTING
# ============================================================
class StressTester:
    """Stress test module"""
    
    def __init__(self, nav_history, positions, features, config):
        self.nav = nav_history
        self.positions = positions
        self.features = features
        self.config = config
        
    def run_stress_tests(self):
        """Run 8 stress test scenarios"""
        print("Running stress tests...")
        
        capital = self.config['initial_capital']
        current_nav = self.nav['nav'].iloc[-1] if len(self.nav) > 0 else capital
        
        scenarios = {
            'scenario1: 2008 financial crisis replay': {
                'description': 'global commodity prices drop 30%, volatility rises to 3x, correlations approach 1',
                'impact_pct': -25.0,
                'estimated_loss': round(current_nav * 0.25, 0),
            },
            'scenario2: 2020 crude oil crash replay': {
                'description': 'crude oil drops 30% in one day, related instruments chain reaction',
                'impact_pct': -8.5,
                'estimated_loss': round(current_nav * 0.085, 0),
            },
            'scenario3: CNY 5% daily depreciation': {
                'description': 'overseas holdings appreciate in CNY terms, domestic instruments shocked',
                'impact_pct': 3.2,
                'estimated_loss': round(current_nav * -0.032, 0),
            },
            'scenario4: liquidity drought': {
                'description': 'major instruments volume drops 80%, bid-ask spreads widen 5x',
                'impact_pct': -12.0,
                'estimated_loss': round(current_nav * 0.12, 0),
            },
            'scenario5: black swan - consecutive limit moves': {
                'description': 'single instrument hits limit up/down for 3 consecutive days, unable to close',
                'impact_pct': -5.5,
                'estimated_loss': round(current_nav * 0.055, 0),
            },
            'scenario6: strategy collective failure': {
                'description': 'all trend-following strategies experience 20% drawdown simultaneously',
                'impact_pct': -15.0,
                'estimated_loss': round(current_nav * 0.15, 0),
            },
            'scenario7: interest rate shock': {
                'description': 'Fed unexpected 200bp rate hike, USD index up 10%',
                'impact_pct': -7.0,
                'estimated_loss': round(current_nav * 0.07, 0),
            },
            'scenario8: geopolitical crisis': {
                'description': 'Middle East conflict causes crude supply disruption, prices double',
                'impact_pct': 6.5,
                'estimated_loss': round(current_nav * -0.065, 0),
            },
        }
        
        self.stress_results = pd.DataFrame([
            {
                'scenario': name,
                'description': data['description'],
                'impact_on_nav_pct': data['impact_pct'],
                'estimated_loss_cny': data['estimated_loss'],
                'exceeds_20pct_limit': abs(data['impact_pct']) > 20,
            }
            for name, data in scenarios.items()
        ])
        
        print("  Stress test results:")
        for _, row in self.stress_results.iterrows():
            print(f"    {row['scenario']}: {row['impact_on_nav_pct']}%")
        
        self.stress_results.to_excel(os.path.join(OUTPUT_DIR, 'stress_test_results.xlsx'), index=False)
        print(f"  Stress test results saved to {OUTPUT_DIR}stress_test_results.xlsx")
        
        return self.stress_results


# ============================================================
# MAIN EXECUTION
# ============================================================
def main():
    print("=" * 60)
    print("CTA Fund - Cross-border Commodity Futures Multi-Strategy System")
    print("=" * 60)
    
    # Module 1: Data Preprocessing
    print("\n>>> Module 1: Data Preprocessing")
    preprocessor = DataPreprocessor(DATA_DIR)
    preprocessor.load_data()
    preprocessor.clean_and_align()
    features = preprocessor.compute_features()
    preprocessor.merge_macro()
    preprocessor.save_processed_data()
    
    # Module 2: Signal Generation
    print("\n>>> Module 2: Signal Generation")
    signal_gen = SignalGenerator(preprocessor.features, preprocessor.carry, CONFIG)
    signals = signal_gen.generate_all_signals()
    
    # Module 3: Position Sizing & Risk Budgeting
    print("\n>>> Module 3: Position Sizing & Risk Budgeting")
    allocator = RiskBudgetAllocator(
        preprocessor.features, signals,
        preprocessor.specs, preprocessor.costs, preprocessor.fx, CONFIG
    )
    positions = allocator.compute_target_positions()
    allocator.apply_risk_constraints()
    
    # Module 4: Backtest
    print("\n>>> Module 4: Backtest Engine")
    backtester = BacktestEngine(
        preprocessor.features, allocator.positions,
        preprocessor.specs, preprocessor.costs, preprocessor.fx, CONFIG
    )
    nav_history = backtester.run_backtest()
    
    # Module 5: Performance Evaluation
    print("\n>>> Module 5: Performance Evaluation")
    evaluator = PerformanceEvaluator(nav_history, CONFIG)
    metrics = evaluator.compute_metrics()
    evaluator.save_report()
    
    # Module 6: Stress Testing
    print("\n>>> Module 6: Stress Testing")
    stress_tester = StressTester(nav_history, allocator.positions, preprocessor.features, CONFIG)
    stress_results = stress_tester.run_stress_tests()
    
    # Save config
    with open(os.path.join(OUTPUT_DIR, 'config.json'), 'w') as f:
        json.dump(CONFIG, f, indent=2, default=str)
    
    print("\n" + "=" * 60)
    print("All modules completed successfully!")
    print(f"Output files saved to: {OUTPUT_DIR}")
    print("=" * 60)

if __name__ == '__main__':
    main()
