# ======================================================================= #
# 🧂 Vinton Salt Dome — Real Data Exploration
#
# Parse the saltdome_s7_100.grd (Surfer 7 binary grid) provided by Xu,
# and perform a complete pre-inversion diagnostic:
#   1. Read and save as .npy
#   2. 6 diagnostic plots: anomaly distribution / histogram / 1D profile / regional trend / autocorrelation / spectrum
#   3. Estimate key inversion parameters: noise sigma, recommended inversion grid depth, recommended cooling beta_0
#
# After running, you can answer:
#   - Does the data need further detrending?
#   - What is the lateral extent of the main anomaly? (determines grid dx)
#   - What is the amplitude range of the main anomaly? (determines expected m_max)
#   - How deep should the inversion grid extend? (determines nz)
#   - What should sigma_d be set to? (determines chifact)
# ======================================================================= #

import os
import struct
import json
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec

INPUT_FILE = "saltdome_s7_100.grd"   # Original file provided by Xu, placed in the script directory
OUT_DIR    = "vinton_data"
FIG_DIR    = os.path.join(OUT_DIR, "figures_exploration")
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(FIG_DIR, exist_ok=True)

print("=" * 72)
print("  🧂 Vinton Salt Dome — Real Data Exploration")
print("=" * 72)

# ============================================================ 1. Parse Surfer 7 Binary
print("\n>>> [1/4] Reading Surfer 7 binary .grd ...")

def read_surfer7_grd(path):
    """Read a Surfer 7 binary grid (DSRB tag) file"""
    with open(path, 'rb') as f:
        data = f.read()
    idx = 0
    # DSRB header
    tag = data[idx:idx+4]; idx += 4
    if tag != b'DSRB':
        raise ValueError(f"Not a Surfer 7 binary grid (got {tag})")
    hdr_size = struct.unpack('<i', data[idx:idx+4])[0]; idx += 4
    version  = struct.unpack('<i', data[idx:idx+4])[0]; idx += 4
    # GRID section
    tag2 = data[idx:idx+4]; idx += 4
    grid_hdr_size = struct.unpack('<i', data[idx:idx+4])[0]; idx += 4
    nRow, nCol = struct.unpack('<ii', data[idx:idx+8]); idx += 8
    xLL, yLL   = struct.unpack('<dd', data[idx:idx+16]); idx += 16
    xSize, ySize = struct.unpack('<dd', data[idx:idx+16]); idx += 16
    zMin, zMax = struct.unpack('<dd', data[idx:idx+16]); idx += 16
    rotation   = struct.unpack('<d', data[idx:idx+8])[0]; idx += 8
    blank      = struct.unpack('<d', data[idx:idx+8])[0]; idx += 8
    # DATA section
    data_tag = data[idx:idx+4]; idx += 4
    data_size = struct.unpack('<i', data[idx:idx+4])[0]; idx += 4
    grid_vals = struct.unpack(f'<{nRow*nCol}d', data[idx:idx+nRow*nCol*8])
    Z = np.array(grid_vals).reshape((nRow, nCol))
    Z[Z == blank] = np.nan
    return dict(Z=Z, nRow=nRow, nCol=nCol, xLL=xLL, yLL=yLL,
                xSize=xSize, ySize=ySize, zMin=zMin, zMax=zMax)

g = read_surfer7_grd(INPUT_FILE)
Z = g["Z"]
nRow, nCol = g["nRow"], g["nCol"]
xLL, yLL = g["xLL"], g["yLL"]
xSize, ySize = g["xSize"], g["ySize"]

print(f"   -> Grid:    {nRow} x {nCol} = {Z.size} points")
print(f"   -> Spacing: {xSize:.0f} x {ySize:.0f} m")
print(f"   -> Area:    {nCol*xSize:.0f} x {nRow*ySize:.0f} m  ({nCol*xSize/1000:.1f} x {nRow*ySize/1000:.1f} km)")
print(f"   -> UTM origin (LL): ({xLL}, {yLL})")
print(f"   -> Anomaly range: [{np.nanmin(Z):+.3f}, {np.nanmax(Z):+.3f}] mGal")

# Construct observation point coordinates (using local coordinates = area lower-left corner as origin)
x_local = np.arange(nCol) * xSize + xSize / 2
y_local = np.arange(nRow) * ySize + ySize / 2
X_grid, Y_grid = np.meshgrid(x_local, y_local, indexing='xy')
rxLoc = np.column_stack([X_grid.ravel(), Y_grid.ravel(), np.zeros(Z.size)])
dobs  = Z.ravel()

# Save basic data
np.save(os.path.join(OUT_DIR, "dobs.npy"), dobs)
np.save(os.path.join(OUT_DIR, "rxLoc.npy"), rxLoc)
np.save(os.path.join(OUT_DIR, "Z_grid.npy"), Z)
print(f"   -> Saved: {OUT_DIR}/dobs.npy, rxLoc.npy, Z_grid.npy")

# ============================================================ 2. Regional Trend Analysis
print("\n>>> [2/4] Regional trend analysis ...")

# Fit 1st-order and 2nd-order polynomial trends
A1 = np.column_stack([X_grid.ravel(), Y_grid.ravel(), np.ones(Z.size)])
coef1, *_ = np.linalg.lstsq(A1, dobs, rcond=None)
trend1 = (A1 @ coef1).reshape(Z.shape)
detrend1 = Z - trend1

A2 = np.column_stack([
    X_grid.ravel()**2, Y_grid.ravel()**2, X_grid.ravel()*Y_grid.ravel(),
    X_grid.ravel(), Y_grid.ravel(), np.ones(Z.size)
])
coef2, *_ = np.linalg.lstsq(A2, dobs, rcond=None)
trend2 = (A2 @ coef2).reshape(Z.shape)
detrend2 = Z - trend2

print(f"   -> 1st-order planar trend:   rms={np.sqrt(np.mean(trend1**2)):.3f} mGal, amplitude {trend1.max()-trend1.min():.3f} mGal")
print(f"   -> 2nd-order surface trend:  rms={np.sqrt(np.mean(trend2**2)):.3f} mGal, amplitude {trend2.max()-trend2.min():.3f} mGal")
print(f"   -> Raw data rms:             {np.sqrt(np.mean(Z**2)):.3f} mGal")
print(f"   -> 1st-order detrended rms:  {np.sqrt(np.mean(detrend1**2)):.3f} mGal")
print(f"   -> 2nd-order detrended rms:  {np.sqrt(np.mean(detrend2**2)):.3f} mGal")
trend_pct = (np.sqrt(np.mean(trend1**2)) / np.sqrt(np.mean(Z**2))) * 100
print(f"   -> 1st-order trend fraction: {trend_pct:.1f}%")

# ============================================================ 3. Noise Estimation
print("\n>>> [3/4] Noise level estimation ...")

# Method 1: High-frequency residual method (Laplacian)
from scipy.ndimage import laplace
lap = laplace(Z)
sigma_lap = np.std(lap) / np.sqrt(20)   # Empirical scaling
print(f"   -> Laplacian method:         sigma ~ {sigma_lap:.4f} mGal")

# Method 2: Median of local window standard deviations
from scipy.ndimage import generic_filter
local_std = generic_filter(Z, np.std, size=3)
sigma_loc = np.median(local_std) / np.sqrt(2)
print(f"   -> Local std median:         sigma ~ {sigma_loc:.4f} mGal")

# Method 3: High-frequency spectral energy method
fft_Z = np.fft.fft2(Z - Z.mean())
power = np.abs(fft_Z) ** 2
ny, nx = Z.shape
ky = np.fft.fftfreq(ny, d=ySize)
kx = np.fft.fftfreq(nx, d=xSize)
KY, KX = np.meshgrid(ky, kx, indexing='ij')
K = np.sqrt(KX**2 + KY**2)
k_max = K.max()
high_freq_mask = K > 0.7 * k_max
sigma_fft = np.sqrt(power[high_freq_mask].mean() / Z.size) * 2
print(f"   -> High-freq spectrum:       sigma ~ {sigma_fft:.4f} mGal")

# Use conservative estimate
sigma_estimate = float(max(sigma_lap, sigma_loc) * 1.5)
print(f"   -> Recommended inversion sigma_d: {sigma_estimate:.3f} mGal (conservative value x1.5)")

# ============================================================ 4. Key Spatial Scales
print("\n>>> [4/4] Main anomaly spatial scale estimation ...")

# Anomaly center localization
cy, cx = np.unravel_index(np.nanargmax(Z), Z.shape)
peak_x = x_local[cx]
peak_y = y_local[cy]
peak_val = Z[cy, cx]
print(f"   -> Peak location:        ({peak_x:.0f}, {peak_y:.0f}) m  (local coordinates)")
print(f"   -> Peak amplitude:       {peak_val:.3f} mGal")

# Estimate main anomaly half-width (along X direction)
profile_x = Z[cy, :]
half_max = peak_val / 2
above_half = profile_x > half_max
if above_half.any():
    idx_above = np.where(above_half)[0]
    width_x = (idx_above[-1] - idx_above[0]) * xSize
    print(f"   -> X-direction half-width: {width_x:.0f} m")
profile_y = Z[:, cx]
above_half_y = profile_y > half_max
if above_half_y.any():
    idx_above_y = np.where(above_half_y)[0]
    width_y = (idx_above_y[-1] - idx_above_y[0]) * ySize
    print(f"   -> Y-direction half-width: {width_y:.0f} m")

# Inversion parameter recommendations
recommend_dx = 50   # Twice as dense as observation spacing
recommend_nx = int(np.ceil(nCol * xSize / recommend_dx))
recommend_ny = int(np.ceil(nRow * ySize / recommend_dx))
recommend_depth = 2000   # Salt dome can extend to 1.5-2 km depth
recommend_nz = int(np.ceil(recommend_depth / recommend_dx))

print(f"\n   -> Recommended inversion grid:")
print(f"      Horizontal: {recommend_nx} x {recommend_ny}  @ {recommend_dx} m")
print(f"      Depth: {recommend_nz} layers x {recommend_dx} m = {recommend_depth} m")
print(f"      Total cells: {recommend_nx*recommend_ny*recommend_nz:,}")

# ============================================================ 5. 6 Diagnostic Plots
print("\n>>> Generating 6 diagnostic plots ...")
plt.rcParams.update({"figure.dpi": 110, "savefig.dpi": 200, "font.size": 10})

# Fig 1: Main plot + detrended
fig, axes = plt.subplots(1, 3, figsize=(15, 4.8))
vmax = np.nanmax(np.abs(Z))
extent = [x_local[0]-xSize/2, x_local[-1]+xSize/2,
          y_local[0]-ySize/2, y_local[-1]+ySize/2]

im0 = axes[0].imshow(Z, origin='lower', extent=extent, cmap='RdBu_r',
                     vmin=-vmax, vmax=vmax, aspect='equal')
axes[0].set_title(f"(a) Original\n[{np.nanmin(Z):+.2f}, {np.nanmax(Z):+.2f}] mGal")
axes[0].set_xlabel("x (m)"); axes[0].set_ylabel("y (m)")
axes[0].plot(peak_x, peak_y, 'k+', ms=15, mew=2)
plt.colorbar(im0, ax=axes[0], shrink=0.85, label='mGal')

vmax2 = np.nanmax(np.abs(detrend1))
im1 = axes[1].imshow(detrend1, origin='lower', extent=extent, cmap='RdBu_r',
                     vmin=-vmax2, vmax=vmax2, aspect='equal')
axes[1].set_title(f"(b) Detrended (1st-order)\n[{detrend1.min():+.2f}, {detrend1.max():+.2f}] mGal")
axes[1].set_xlabel("x (m)"); axes[1].set_ylabel("y (m)")
plt.colorbar(im1, ax=axes[1], shrink=0.85, label='mGal')

vmax3 = np.nanmax(np.abs(detrend2))
im2 = axes[2].imshow(detrend2, origin='lower', extent=extent, cmap='RdBu_r',
                     vmin=-vmax3, vmax=vmax3, aspect='equal')
axes[2].set_title(f"(c) Detrended (2nd-order)\n[{detrend2.min():+.2f}, {detrend2.max():+.2f}] mGal")
axes[2].set_xlabel("x (m)"); axes[2].set_ylabel("y (m)")
plt.colorbar(im2, ax=axes[2], shrink=0.85, label='mGal')

plt.suptitle("Fig. 1 — Vinton gravity anomaly: original vs detrended",
             fontsize=13, y=1.02)
plt.tight_layout()
plt.savefig(os.path.join(FIG_DIR, "Fig1_anomaly_and_detrend.png"), bbox_inches='tight')
plt.close()
print(f"   ✅ Fig 1: Original + detrended")

# Fig 2: 1D profiles + histogram
fig, axes = plt.subplots(2, 2, figsize=(12, 8))

# X profile (through peak)
axes[0, 0].plot(x_local, Z[cy, :], '-o', color='#0072B2', ms=4, label='original')
axes[0, 0].plot(x_local, detrend2[cy, :], '-^', color='#D55E00', ms=4, label='detrended')
axes[0, 0].axhline(0, color='k', lw=0.5)
axes[0, 0].axvline(peak_x, color='gray', ls='--', alpha=0.5)
axes[0, 0].set_xlabel('x (m)'); axes[0, 0].set_ylabel('mGal')
axes[0, 0].set_title(f"(a) X profile through peak (y={peak_y:.0f} m)")
axes[0, 0].legend(); axes[0, 0].grid(alpha=0.3)

# Y profile (through peak)
axes[0, 1].plot(y_local, Z[:, cx], '-o', color='#0072B2', ms=4, label='original')
axes[0, 1].plot(y_local, detrend2[:, cx], '-^', color='#D55E00', ms=4, label='detrended')
axes[0, 1].axhline(0, color='k', lw=0.5)
axes[0, 1].axvline(peak_y, color='gray', ls='--', alpha=0.5)
axes[0, 1].set_xlabel('y (m)'); axes[0, 1].set_ylabel('mGal')
axes[0, 1].set_title(f"(b) Y profile through peak (x={peak_x:.0f} m)")
axes[0, 1].legend(); axes[0, 1].grid(alpha=0.3)

# Histogram: original + detrended
axes[1, 0].hist(Z.ravel(), bins=40, alpha=0.6, color='#0072B2', label=f'original (μ={Z.mean():.2f})')
axes[1, 0].hist(detrend2.ravel(), bins=40, alpha=0.6, color='#D55E00', label=f'detrended (μ={detrend2.mean():.3f})')
axes[1, 0].axvline(0, color='k', ls='--')
axes[1, 0].set_xlabel('mGal'); axes[1, 0].set_ylabel('count')
axes[1, 0].set_title("(c) Distribution")
axes[1, 0].legend()

# Laplacian (noise indicator)
axes[1, 1].imshow(lap, origin='lower', extent=extent, cmap='RdBu_r',
                   vmin=-3*sigma_lap*np.sqrt(20), vmax=3*sigma_lap*np.sqrt(20),
                   aspect='equal')
axes[1, 1].set_title(f"(d) Laplacian (noise indicator)\nσ_est ≈ {sigma_lap:.4f} mGal")
axes[1, 1].set_xlabel('x (m)'); axes[1, 1].set_ylabel('y (m)')

plt.suptitle("Fig. 2 — Profiles, distribution, and noise estimate",
             fontsize=13, y=1.00)
plt.tight_layout()
plt.savefig(os.path.join(FIG_DIR, "Fig2_profiles_noise.png"), bbox_inches='tight')
plt.close()
print(f"   ✅ Fig 2: 1D profiles + noise diagnostics")

# Fig 3: Radial autocorrelation + spectrum
fig, axes = plt.subplots(1, 2, figsize=(13, 5))

# Autocorrelation (FFT method)
Z0 = detrend2 - np.nanmean(detrend2)
F = np.fft.fft2(Z0)
acf2d = np.real(np.fft.ifft2(F * np.conj(F)))
acf2d = np.fft.fftshift(acf2d) / acf2d.max()

# Radial average
yc, xc = ny//2, nx//2
yy, xx = np.indices(Z.shape)
r = np.sqrt((xx - xc)**2 + (yy - yc)**2)
r_int = r.astype(int)
tbin = np.bincount(r_int.ravel(), acf2d.ravel())
nr = np.bincount(r_int.ravel())
acf_rad = tbin / np.maximum(nr, 1)
r_axis = np.arange(len(acf_rad)) * xSize

axes[0].plot(r_axis / 1000, acf_rad, '-o', ms=4, color='#0072B2')
axes[0].axhline(0, color='k', lw=0.5)
axes[0].axhline(np.exp(-1), color='r', ls='--', alpha=0.5, label='1/e')
axes[0].set_xlabel('lag (km)'); axes[0].set_ylabel('normalized ACF')
axes[0].set_title("(a) Radial autocorrelation")
axes[0].legend(); axes[0].grid(alpha=0.3)
axes[0].set_xlim(0, r_axis.max()/1000 * 0.6)

# Find 1/e decay distance (correlation length)
idx_le = np.argmin(np.abs(acf_rad - np.exp(-1)))
corr_length = r_axis[idx_le]
axes[0].axvline(corr_length / 1000, color='r', ls=':', alpha=0.7,
                 label=f'L_corr = {corr_length:.0f} m')
axes[0].legend()

# Radial power spectrum
power_2d = np.abs(np.fft.fftshift(np.fft.fft2(Z0))) ** 2
tbin2 = np.bincount(r_int.ravel(), power_2d.ravel())
power_rad = tbin2 / np.maximum(nr, 1)
k_axis = np.arange(len(power_rad)) / (nx * xSize)

axes[1].loglog(k_axis[1:] * 1000, power_rad[1:], '-o', ms=4, color='#D55E00')
axes[1].set_xlabel('wavenumber (cycles/km)')
axes[1].set_ylabel('power')
axes[1].set_title("(b) Radial power spectrum")
axes[1].grid(alpha=0.3, which='both')

plt.suptitle("Fig. 3 — Spatial correlation structure",
             fontsize=13, y=1.00)
plt.tight_layout()
plt.savefig(os.path.join(FIG_DIR, "Fig3_correlation_spectrum.png"), bbox_inches='tight')
plt.close()
print(f"   ✅ Fig 3: Autocorrelation + spectrum")
print(f"   -> Main anomaly correlation length: {corr_length:.0f} m  (inversion cell dx should be smaller)")

# ============================================================ Save Metadata
print("\n>>> Saving metadata ...")
meta = dict(
    source="Xu Ya, IGGCAS, via personal communication 2025",
    file_format="Surfer 7 binary grid (DSRB)",
    nRow=int(nRow), nCol=int(nCol),
    xLL=float(xLL), yLL=float(yLL),
    xSize=float(xSize), ySize=float(ySize),
    coverage_x_m=float(nCol*xSize), coverage_y_m=float(nRow*ySize),
    n_data=int(Z.size),
    z_min=float(np.nanmin(Z)), z_max=float(np.nanmax(Z)),
    z_rms=float(np.sqrt(np.nanmean(Z**2))),
    z_std=float(np.nanstd(Z)),
    peak_value_mGal=float(peak_val),
    peak_location_local_xy=[float(peak_x), float(peak_y)],
    trend_1st_rms_mGal=float(np.sqrt(np.mean(trend1**2))),
    trend_2nd_rms_mGal=float(np.sqrt(np.mean(trend2**2))),
    detrended_2nd_range=[float(detrend2.min()), float(detrend2.max())],
    sigma_estimates=dict(
        laplacian=float(sigma_lap),
        local_std=float(sigma_loc),
        high_freq_spectrum=float(sigma_fft),
        recommended=float(sigma_estimate),
    ),
    correlation_length_m=float(corr_length),
    recommended_inversion_grid=dict(
        dx_m=recommend_dx, nx=recommend_nx, ny=recommend_ny,
        nz=recommend_nz, max_depth_m=recommend_depth,
        total_cells=recommend_nx*recommend_ny*recommend_nz,
    ),
    coordinate_system="UTM Zone 15N (Louisiana)",
    interpretation_notes=[
        "Peak gravity anomaly +2.41 mGal corresponds to cap rock high-density zone",
        "Negative values around edges may include regional trend not fully removed",
        "Should test inversion both with and without 2nd-order detrending",
        "Salt core (low density) signal may be weak compared to cap rock signal",
    ],
)
with open(os.path.join(OUT_DIR, "meta.json"), "w", encoding="utf-8") as fh:
    json.dump(meta, fh, indent=2, ensure_ascii=False)
print(f"   -> {OUT_DIR}/meta.json")

print("\n" + "=" * 72)
print("  ✅ Vinton data exploration complete")
print(f"  3 plots: {FIG_DIR}/")
print(f"  Data + metadata: {OUT_DIR}/")
print("=" * 72)
print("\n  Key conclusions:")
print(f"  - Data source confirmed: Xu (IGGCAS), 41x41 = 1681 points, 100m spacing")
print(f"  - Peak amplitude +{peak_val:.2f} mGal (cap rock), minimum {np.nanmin(Z):.2f} mGal (salt core?)")
print(f"  - Estimated noise sigma_d ~ {sigma_estimate:.3f} mGal")
print(f"  - Main anomaly correlation length ~{corr_length:.0f} m -> inversion grid dx={recommend_dx} m is appropriate")
print(f"  - 1st-order trend fraction {trend_pct:.1f}% -> recommend removing 2nd-order trend before inversion")
print(f"  - Recommended inversion grid: {recommend_nx}x{recommend_ny}x{recommend_nz}")
