# D-ABIC Gravity 3D Inversion Regularization Parameter Selection Optimization

## Task Description

This task migrates the D-ABIC method proposed by Song Han et al. in their 2025 paper published in *Geophysics* (doi 10.1190/geo-2025-0233) from its original 3D magnetotelluric inversion setting to 3D gravity inversion, and validates it on the Vinton salt dome measured gravity data. D-ABIC stands for Data-space variant of Akaike's Bayesian Information Criterion, an adaptive algorithm for selecting the regularization parameter beta.

Xu et al. published a paper in 2025 in *Geophysical Prospecting*, Volume 73, Issue 4, pages 1301-1314 (doi 10.1111/1365-2478.70016), which performed gravity inversion on the same Vinton dataset using the Hamiltonian Monte Carlo method, serving as the benchmark for this task.

The inversion must be completed under both L0 norm and L1 norm sparse regularization forms. For each norm, a three-way comparison of D-ABIC, Cooling, and L-curve must be conducted.

## Working Directory Structure

```
.
├── docs/
│   ├── geo20250233.pdf      Song et al. D-ABIC methodology paper
│   └── Xu2025_HMC.pdf       Xu et al. HMC gravity inversion + Vinton application
├── data/
│   └── saltdome_s7_100.grd  Vinton salt dome measured gravity anomaly data (Surfer 7 binary)
├── starter/
│   ├── starter.py           Synthetic data and forward simulator; inversion framework to be implemented by Agent
│   ├── explore_xu_data.py   Vinton data parsing and initial diagnostics; run directly
│   └── README.md            This file
└── outputs/                 All outputs should be written to this directory
```

## Objects Provided by starter.py

`starter.py` only constructs the synthetic data and forward simulator and does not include any inversion components. The following global objects are available after import:

- `mesh`: discretize TensorMesh, 40x30x10 with 12000 cells
- `m_true`: True model density vector, 4 target bodies, all with density 1.0
- `body_label`: Target body index for each cell, 0 for background
- `rxLoc`: 41x31 = 1271 surface observation points
- `sim_fwd`: SimPEG forward simulation object
- `d_clean`: Noise-free theoretical data
- `d_obs`: Noisy observed data
- `sigma_per_pt`: Noise standard deviation per observation point, 0.05*|d|+0.02 mGal

The Agent needs to build the complete SimPEG inversion framework on this basis, including `data_misfit`, `regularization`, `optimization`, `inverse_problem`, `inversion`, various `directives`, etc.

## Four Phases

### Phase 1: Algorithm Implementation

Read `docs/geo20250233.pdf` to understand the statistical framework, mathematical derivation, and numerical implementation details of D-ABIC. Implement the D-ABIC adaptive beta directive, suggested naming: `class DABIC_Beta_Estimator(directives.InversionDirective)`, placed in the standalone module `outputs/dabic_directive.py`.

The forward operator, Jacobian, data types, and parameterization differ between MT inversion and gravity inversion. The approach for migration is at the implementer's discretion and must be justified in the report. Whether to use model-space or data-space formulation, how to compute the determinant, and in which space to optimize beta are all to be determined by the implementer. The implemented directive must work correctly under both L0 and L1 norms.

### Phase 2: Synthetic Validation

Build a complete SimPEG inversion workflow based on the synthetic data provided by starter. In addition to D-ABIC, you must also implement Cooling inversion and L-curve sweep with knee detection as two baseline methods. Run a three-way comparison of D-ABIC, Cooling, and L-curve on synthetic Model 3 under both L0 and L1 norms.

Produce figures and metrics for quantitative and qualitative comparison of the methods, including inversion result slices, data residuals, beta convergence trajectories, and target body recovery. Also report the behavioral differences of D-ABIC under L0 and L1, such as the magnitude difference in terminal beta values and the effect of IRLS re-weighting on the optimization process.

### Phase 3: Field Data Application

`data/saltdome_s7_100.grd` is the measured gravity anomaly data from the Vinton salt dome in Surfer 7 binary format. `starter/explore_xu_data.py` can parse this file and output diagnostic plots and noise estimates; run it directly.

The physical and geometric settings needed for inversion, including grid dimensions, depth range, density bounds, and noise estimates, should follow `docs/Xu2025_HMC.pdf`. That paper used the HMC method to process the same dataset.

Run D-ABIC and Cooling inversions on the field data under both L0 and L1 norms.

### Phase 4: Result Comparison

Perform quantitative and qualitative comparison with the Vinton inversion results reported in the Xu 2025 HMC paper, including depth slices, geometric extents, and data fit. Report results under L0 and L1 separately.

Write `report.md`, 800 to 1500 words, addressing at least three points:

1. What key decisions were made when migrating the method from MT inversion to gravity inversion? What was the rationale?
2. What are the systematic behavioral differences of D-ABIC under L0 and L1 norms? Are these differences reflected in the inversion images and statistical metrics?
3. How do the inversion results on synthetic and field data compare with the baseline methods and the Xu HMC results?

## Final Deliverables

All outputs should be written to `outputs/`:

- `dabic_directive.py` — D-ABIC implementation, standalone reusable module
- `run_synthetic.py` — Synthetic validation script, runs both L0 and L1, generates Phase 2 figures
- `run_vinton.py` — Field data inversion script, runs both L0 and L1, generates Phase 3 and 4 figures
- `results.json` — Key inversion metrics, both L0 and L1 must be recorded
- `report.md` — Report

The field names in `results.json` should follow the pattern `synthetic_L0`, `synthetic_L1`, `vinton_L0`, `vinton_L1`, with each key containing `dabic_chi2_per_N`, `dabic_model_rmse`, `cooling_model_rmse`, `dabic_beta_history`, `dabic_residual_rms_mGal`, `dabic_cap_rock_center_depth_m`, `dabic_xu_iou`, etc.

## Runtime Environment

Python 3.10 to 3.12. Dependencies: simpeg >= 0.22.0, discretize >= 0.10.0, numpy >= 1.24, scipy >= 1.11, matplotlib >= 3.7.

```
pip install "simpeg>=0.22.0" "discretize>=0.10.0" "numpy>=1.24" "scipy>=1.11" "matplotlib>=3.7"
```

`starter/starter.py` has a self-check entry point at the end; `python starter/starter.py` should output basic information about mesh, stations, bodies, etc. Running `python starter/explore_xu_data.py` will generate 6 diagnostic plots and a parameter JSON in the `vinton_data/` subdirectory for reference during Vinton inversion.

## Constraints

- Do not modify `starter/explore_xu_data.py`
- Do not modify the model, observation points, or observation data generation logic in `starter/starter.py`
- Beta must be adaptively determined by D-ABIC; hard-coding it as a constant is not allowed
- Importing any third-party ABIC or DABIC package is not allowed
- Using SimPEG's built-in automatic beta advanced directives is not allowed; `BetaEstimate_ByEig` may only be used to set the initial beta_0 value
- Inversion under both L0 and L1 norms must be fully completed; `results.json` and figures must cover both norms
- Only implement what is specified in the requirements; do not extend to GCV, HMC, or other regularization strategies

## Suggested Workflow

1. First read the methods section of `docs/geo20250233.pdf` to understand the statistical framework of D-ABIC
2. Design the SimPEG inversion framework yourself, and implement the Cooling tracker and L-curve sweep with knee detection as two baseline methods
3. Write `outputs/dabic_directive.py` to implement the D-ABIC adaptive beta directive
4. Run both L1 and L0 norms on synthetic Model 3 to verify that the three-way comparison is reasonable
5. Run the Vinton field data inversion, using the parameters from `explore_xu_data.py` output to configure the inversion
6. Compare with Xu HMC results and write `report.md`

After completing each phase, run the script and check whether the key metrics in `results.json` fall within reasonable ranges before proceeding to the next phase.
