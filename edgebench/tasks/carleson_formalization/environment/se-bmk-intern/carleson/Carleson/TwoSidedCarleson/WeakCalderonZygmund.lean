module

public import Mathlib.Analysis.Normed.Group.Basic
public import Carleson.ToMathlib.HardyLittlewood
public import Carleson.TwoSidedCarleson.Basic

@[expose] public section

open MeasureTheory Set Bornology Function Metric Filter Topology
open ENNReal hiding one_lt_two
open scoped NNReal

noncomputable section

/-- `K` is a two-sided Calderon-Zygmund kernel.
In the formalization `K x y` is defined everywhere, even for `x = y`.
The assumptions on `K` show that `K x x = 0`. -/
class IsTwoSidedKernel {X : Type*} [PseudoMetricSpace X] [MeasureSpace X] (a : outParam ℕ)
    (K : X → X → ℂ) extends IsOneSidedKernel a K where
  enorm_K_sub_le' {x x' y : X} (h : 2 * dist x x' ≤ dist x y) :
    ‖K x y - K x' y‖ₑ ≤ (edist x x' / edist x y) ^ (a : ℝ)⁻¹ * (C_K a / vol x y)

export IsTwoSidedKernel (enorm_K_sub_le')

variable {X : Type*} {a : ℕ} [MetricSpace X] [DoublingMeasure X (defaultA a : ℕ)]
variable {τ C r R : ℝ} {q q' : ℝ≥0}
variable {F G : Set X}
variable {K : X → X → ℂ} {x x' : X} [IsTwoSidedKernel a K]
variable {f : X → ℂ} {α : ℝ≥0∞}

/-! ## Section 10.2 and Lemma 10.0.3

Question: -/

/-- The constant used in `nontangential_from_simple`.
I(F) think the constant needs to be fixed in the blueprint. -/
irreducible_def C10_2_1 (a : ℕ) : ℝ≥0 := 2 ^ (4 * a)

/-- Lemma 10.2.1, formulated differently.
The blueprint version is basically this after unfolding `HasBoundedWeakType`, `wnorm` and `wnorm'`.
-/
theorem maximal_theorem :
    HasBoundedWeakType (globalMaximalFunction volume 1 : (X → ℂ) → X → ℝ≥0∞) 1 1 volume volume
      (C10_2_1 a) := by
  sorry

-- Lemma 10.2.1, as formulated in the blueprint
variable (α) in
private theorem maximal_theorem' (hf : BoundedFiniteSupport f) :
    α * volume {x | α < ‖globalMaximalFunction volume 1 f x‖ₑ} ≤
    (C10_2_1 a) * eLpNorm f 1 volume := by
  sorry

-- Alternate version of `maximal_theorem'`
private theorem maximal_theorem'' (hα : 0 < α) (hf : BoundedFiniteSupport f) :
    volume {x | α < ‖globalMaximalFunction volume 1 f x‖ₑ} ≤
    (C10_2_1 a) * eLpNorm f 1 volume / α := by
  sorry

/-- Lemma 10.2.2. -/
theorem lebesgue_differentiation {f : X → ℂ} (hf : BoundedFiniteSupport f) :
    ∀ᵐ x ∂volume, ∃ (c : ℕ → X) (r : ℕ → ℝ),
    Tendsto (fun i ↦ ⨍ y in ball (c i) (r i), f y ∂volume) atTop (𝓝 (f x)) ∧
    Tendsto r atTop (𝓝[>] 0) ∧
    ∀ i, x ∈ ball (c i) (r i) := by
  sorry

/-! Lemma 10.2.3 is in Mathlib: `Pairwise.countable_of_isOpen_disjoint`. -/

section Depth

/-- `δ(x)` in the blueprint. The depth of a point `x` in a set `O` is the supremum of radii of
balls centred on `x` that are subsets of `O`. -/
def depth (O : Set X) (x : X) : ℝ≥0∞ :=
  ⨆ r : ℝ≥0, ⨆ (_ : ball x r ⊆ O), r

variable {O : Set X} {x y : X}

lemma depth_lt_iff_not_disjoint {d : ℝ} :
    depth O x < ENNReal.ofReal d ↔ ¬Disjoint (ball x d) Oᶜ := by
  sorry

lemma le_depth_iff_subset {d : ℝ} : ENNReal.ofReal d ≤ depth O x ↔ ball x d ⊆ O := by
  sorry

/-- A point's depth in an open set `O` is positive iff it lies in `O`. -/
lemma depth_pos_iff_mem (hO : IsOpen O) : 0 < depth O x ↔ x ∈ O := by
  sorry

lemma depth_eq_zero_iff_notMem (hO : IsOpen O) : depth O x = 0 ↔ x ∉ O := by
  sorry

/-- A point has finite depth in `O` iff `O` is not the whole space. -/
lemma depth_lt_top_iff_ne_univ : depth O x < ⊤ ↔ O ≠ univ := by
  sorry

/-- A "triangle inequality" for depths. -/
lemma depth_le_edist_add_depth : depth O x ≤ edist x y + depth O y := by
  sorry

lemma depth_bound_1 (hO : O ≠ univ)
    (h : ¬Disjoint (ball x ((depth O x).toReal / 6)) (ball y ((depth O y).toReal / 6))) :
    x ∈ ball y (3 * ((depth O y).toReal / 6)) := by
  sorry

lemma depth_bound_2 (hO : O ≠ univ) (h : x ∈ ball y (3 * ((depth O y).toReal / 6))) :
    (depth O x).toReal / 6 + dist x y ≤ 8 * (depth O y).toReal / 6 := by
  sorry

lemma depth_bound_3 (hO : O ≠ univ) (h : x ∈ ball y (3 * ((depth O y).toReal / 6))) :
    (depth O y).toReal / 6 + dist y x ≤ 8 * (depth O x).toReal / 6 := by
  sorry

lemma ball_covering_bounded_intersection
    (hO : IsOpen O ∧ O ≠ univ) {U : Set X} (countU : U.Countable)
    (pdU : U.PairwiseDisjoint fun c ↦ ball c ((depth O c).toReal / 6)) {x : X} (mx : x ∈ O) :
    {c ∈ U | x ∈ ball c (3 * ((depth O c).toReal / 6))}.encard ≤ (2 ^ (6 * a) : ℕ) := by
  sorry

/-- Lemma 10.2.4, but following the blueprint exactly (with a countable set of centres rather than
functions from `ℕ`). -/
lemma ball_covering' (hO : IsOpen O ∧ O ≠ univ) :
    ∃ (U : Set X) (r : X → ℝ), U.Countable ∧ (U.PairwiseDisjoint fun c ↦ ball c (r c)) ∧
      ⋃ c ∈ U, ball c (3 * r c) = O ∧ (∀ c ∈ U, ¬Disjoint (ball c (7 * r c)) Oᶜ) ∧
      ∀ x ∈ O, {c ∈ U | x ∈ ball c (3 * r c)}.encard ≤ (2 ^ (6 * a) : ℕ) := by
  sorry

omit [DoublingMeasure X (defaultA a)] in
lemma ball_covering_finite (hO : IsOpen O ∧ O ≠ univ) {U : Set X} {r' : X → ℝ} (fU : U.Finite)
    (pdU : U.PairwiseDisjoint fun c ↦ ball c (r' c)) (U₃ : ⋃ c ∈ U, ball c (3 * r' c) = O)
    (U₇ : ∀ c ∈ U, ¬Disjoint (ball c (7 * r' c)) Oᶜ)
    (Ubi : ∀ x ∈ O, {c ∈ U | x ∈ ball c (3 * r' c)}.encard ≤ (2 ^ (6 * a) : ℕ)) :
    ∃ (c : ℕ → X) (r : ℕ → ℝ), (univ.PairwiseDisjoint fun i ↦ ball (c i) (r i)) ∧
      ⋃ i, ball (c i) (3 * r i) = O ∧ (∀ i, 0 < r i → ¬Disjoint (ball (c i) (7 * r i)) Oᶜ) ∧
      ∀ x ∈ O, {i | x ∈ ball (c i) (3 * r i)}.encard ≤ (2 ^ (6 * a) : ℕ) := by
  sorry

/-- Lemma 10.2.4. -/
theorem ball_covering (hO : IsOpen O ∧ O ≠ univ) :
    ∃ (c : ℕ → X) (r : ℕ → ℝ), (univ.PairwiseDisjoint fun i ↦ ball (c i) (r i)) ∧
      ⋃ i, ball (c i) (3 * r i) = O ∧ (∀ i, 0 < r i → ¬Disjoint (ball (c i) (7 * r i)) Oᶜ) ∧
      ∀ x ∈ O, {i | x ∈ ball (c i) (3 * r i)}.encard ≤ (2 ^ (6 * a) : ℕ) := by
  sorry

end Depth

/-! ### Lemma 10.2.5

Lemma 10.2.5 has an annoying case distinction between the case `E_α ≠ X` (general case) and
`E_α = X` (finite case). It isn't easy to get rid of this case distinction.

In the formalization we state most properties of Lemma 10.2.5 twice, once for each case
(in some cases the condition is vacuous in the finite case, and then we omit it)

We could have tried harder to uniformize the cases, but in the finite case there is really only set
`B*_j`, and in the general case it is convenient to index `B*_j` by the natural numbers.
-/

/-- The property specifying whether we are in the "general case". -/
def GeneralCase (f : X → ℂ) (α : ℝ≥0∞) : Prop :=
  ∃ x, α ≥ globalMaximalFunction (X := X) volume 1 f x

/-- In the finite case, the volume of `X` is finite. -/
lemma volume_lt_of_not_GeneralCase
    (hf : BoundedFiniteSupport f) (h : ¬ GeneralCase f α) (hα : 0 < α) :
    volume (univ : Set X) < ∞ := by
  sorry

private lemma isFiniteMeasure_of_not_generalCase
    (hf : BoundedFiniteSupport f) (h : ¬ GeneralCase f α) (hα : 0 < α) :
    IsFiniteMeasure (volume : Measure X) := by
  sorry

lemma isOpen_MB_preimage_Ioi (hX : GeneralCase f α) :
    IsOpen (globalMaximalFunction (X := X) volume 1 f ⁻¹' Ioi α) ∧
    globalMaximalFunction (X := X) volume 1 f ⁻¹' Ioi α ≠ univ := by
  sorry

/-- The center of B_j in the proof of Lemma 10.2.5 (general case). -/
def czCenter (hX : GeneralCase f α) (i : ℕ) : X :=
  ball_covering (isOpen_MB_preimage_Ioi hX) |>.choose i

/-- The radius of B_j in the proof of Lemma 10.2.5 (general case). -/
def czRadius (hX : GeneralCase f α) (i : ℕ) : ℝ :=
  ball_covering (isOpen_MB_preimage_Ioi hX) |>.choose_spec.choose i

/-- The ball B_j in the proof of Lemma 10.2.5 (general case). -/
abbrev czBall (hX : GeneralCase f α) (i : ℕ) : Set X :=
  ball (czCenter hX i) (czRadius hX i)

/-- The ball B_j' introduced below Lemma 10.2.5 (general case). -/
abbrev czBall6 (hX : GeneralCase f α) (i : ℕ) : Set X :=
  ball (czCenter hX i) (6 * czRadius hX i)

/-- The ball B_j* in Lemma 10.2.5 (general case). -/
abbrev czBall3 (hX : GeneralCase f α) (i : ℕ) : Set X :=
  ball (czCenter hX i) (3 * czRadius hX i)

/-- The ball B_j** in the proof of Lemma 10.2.5 (general case). -/
abbrev czBall7 (hX : GeneralCase f α) (i : ℕ) : Set X :=
  ball (czCenter hX i) (7 * czRadius hX i)

lemma czBall_pairwiseDisjoint {hX : GeneralCase f α} :
    univ.PairwiseDisjoint fun i ↦ ball (czCenter hX i) (czRadius hX i) := by
  sorry

lemma iUnion_czBall3 {hX : GeneralCase f α} :
    ⋃ i, czBall3 hX i = globalMaximalFunction volume 1 f ⁻¹' Ioi α := by
  sorry

lemma not_disjoint_czBall7 {hX : GeneralCase f α} {i : ℕ} (hi : 0 < czRadius hX i) :
    ¬Disjoint (czBall7 hX i) (globalMaximalFunction volume 1 f ⁻¹' Ioi α)ᶜ := by
  sorry

private lemma czBall_subset_czBall {hX : GeneralCase f α} {i : ℕ} {b c : ℝ}
    (hb : 0 ≤ b := by norm_num) (hbc : b ≤ c := by norm_num) :
    ball (czCenter hX i) (b * czRadius hX i) ⊆ ball (czCenter hX i) (c * czRadius hX i) := by
  by_cases hr : czRadius hX i ≥ 0
  · exact ball_subset_ball <| mul_le_mul_of_nonneg_right hbc hr
  · simp [ball_eq_empty.mpr <| mul_nonpos_of_nonneg_of_nonpos hb (le_of_not_ge hr)]

/-- Part of Lemma 10.2.5 (general case). -/
lemma encard_czBall3_le {hX : GeneralCase f α} {y : X} :
    {i | y ∈ czBall3 hX i}.encard ≤ (2 ^ (6 * a) : ℕ) := by
  sorry

lemma mem_czBall3_finite {hX : GeneralCase f α} {y : X} :
    {i | y ∈ czBall3 hX i}.Finite := by
  sorry

/-- `Q_i` in the proof of Lemma 10.2.5 (general case). -/
def czPartition (hX : GeneralCase f α) (i : ℕ) : Set X :=
  czBall3 hX i \ ((⋃ j < i, czPartition hX j) ∪ ⋃ j > i, czBall hX j)

@[measurability]
private lemma MeasurableSet.czPartition (hX : GeneralCase f α) (i : ℕ) :
    MeasurableSet (czPartition hX i) := by
  sorry

lemma czBall_subset_czPartition {hX : GeneralCase f α} {i : ℕ} :
    czBall hX i ⊆ czPartition hX i := by
  sorry

lemma czPartition_subset_czBall3 {hX : GeneralCase f α} {i : ℕ} :
    czPartition hX i ⊆ czBall3 hX i := by
  sorry

private lemma czPartition_subset_czBall7 {hX : GeneralCase f α} {i : ℕ} :
    czPartition hX i ⊆ czBall7 hX i := by
  sorry

lemma czPartition_pairwiseDisjoint {hX : GeneralCase f α} :
    univ.PairwiseDisjoint fun i ↦ czPartition hX i := by
  sorry

lemma czPartition_pairwiseDisjoint' {hX : GeneralCase f α}
    {x : X} {i j : ℕ} (hi : x ∈ czPartition hX i) (hj : x ∈ czPartition hX j) :
    i = j := by
  sorry

private lemma czPartition_pairwise_disjoint_on {hX : GeneralCase f α} :
    Pairwise (Disjoint on czPartition hX) := by
  sorry

lemma iUnion_czPartition {hX : GeneralCase f α} :
    ⋃ i, czPartition hX i = globalMaximalFunction volume 1 f ⁻¹' Ioi α := by
  sorry

private lemma globalMaximalFunction_preimage_finite
    (hα : 0 < α) (hf : BoundedFiniteSupport f) :
    volume (globalMaximalFunction volume 1 f ⁻¹' Ioi α) < ∞ := by
  sorry

private lemma volume_czPartition_lt_top (hX : GeneralCase f α) (i : ℕ) :
    volume (czPartition hX i) < ∞ := by
  sorry

private lemma volume_czBall7_le (hX : GeneralCase f α) (i : ℕ) :
    volume (czBall7 hX i) ≤ 2 ^ (3 * a) * volume (czPartition hX i) := by
  sorry

private lemma volume_czBall3_le (hX : GeneralCase f α) (i : ℕ) :
    volume (czBall3 hX i) ≤ 2 ^ (2 * a) * volume (czBall hX i) := by
  sorry

-- Inequality (10.2.30)
private lemma laverage_czBall7_le (hX : GeneralCase f α) (i : ℕ) :
    ⨍⁻ x in czBall7 hX i, ‖f x‖ₑ ∂volume ≤ α := by
  sorry

open scoped Classical in
variable (f) in
/-- The function `g` in Lemma 10.2.5. (both cases) -/
def czApproximation (α : ℝ≥0∞) (x : X) : ℂ :=
  if hX : GeneralCase f α then
    if hx : ∃ j, x ∈ czPartition hX j then ⨍ y in czPartition hX hx.choose, f y else f x
  else ⨍ y, f y

lemma czApproximation_def_of_mem {hX : GeneralCase f α} {x : X}
    {i : ℕ} (hx : x ∈ czPartition hX i) :
    czApproximation f α x = ⨍ y in czPartition hX i, f y := by
  sorry

lemma czApproximation_def_of_notMem {x : X} (hX : GeneralCase f α)
    (hx : x ∉ globalMaximalFunction volume 1 f ⁻¹' Ioi α) :
    czApproximation f α x = f x := by
  sorry

lemma czApproximation_def_of_volume_lt {x : X}
    (hX : ¬ GeneralCase f α) : czApproximation f α x = ⨍ y, f y := by
  sorry

private lemma lintegral_czPartition_le {hX : GeneralCase f α} (i : ℕ) :
    ∫⁻ x in czPartition hX i, ‖czApproximation f α x‖ₑ ≤
    ∫⁻ x in czPartition hX i, ‖f x‖ₑ := by
  sorry

/-- The function `b_i` in Lemma 10.2.5 (general case). -/
def czRemainder' (hX : GeneralCase f α) (i : ℕ) (x : X) : ℂ :=
  (czPartition hX i).indicator (f - czApproximation f α) x

private lemma czRemainder'_eq_zero (hX : GeneralCase f α) {i : ℕ} (hi : czRadius hX i ≤ 0) :
    czRemainder' hX i = 0 := by
  sorry

variable (f) in
/-- The function `b = ∑ⱼ bⱼ` introduced below Lemma 10.2.5.
In the finite case, we also use this as the function `b = b₁` in Lemma 10.2.5.
We choose a more convenient definition, but prove in `tsum_czRemainder'` that this is the same. -/
def czRemainder (α : ℝ≥0∞) (x : X) : ℂ :=
  f x - czApproximation f α x

/-- Part of Lemma 10.2.5, this is essentially (10.2.16) (both cases). -/
lemma tsum_czRemainder' (hX : GeneralCase f α) (x : X) :
    ∑' i, czRemainder' hX i x = czRemainder f α x := by
  sorry

open scoped Classical in
/-- Part of Lemma 10.2.5 (both cases). -/
lemma aemeasurable_czApproximation {hf : AEMeasurable f} : AEMeasurable (czApproximation f α) := by
  sorry

protected lemma AEMeasurable.czRemainder' {hf : AEMeasurable f} (hX : GeneralCase f α) (i : ℕ) :
    AEMeasurable (czRemainder' hX i) := by
  sorry

/-- Part of Lemma 10.2.5 (both cases). -/
@[fun_prop]
protected lemma BoundedFiniteSupport.czApproximation {α : ℝ≥0∞} (hα : 0 < α)
    (hf : BoundedFiniteSupport f) : BoundedFiniteSupport (czApproximation f α) := by
  sorry

@[fun_prop]
protected lemma BoundedFiniteSupport.czRemainder (hα : 0 < α) {hf : BoundedFiniteSupport f} :
    BoundedFiniteSupport (czRemainder f α) := by
  sorry

protected lemma BoundedFiniteSupport.czRemainder' (hα : 0 < α) {hf : BoundedFiniteSupport f}
    (hX : GeneralCase f α) (i : ℕ) :
    BoundedFiniteSupport (czRemainder' hX i) := by
  sorry

protected lemma AEMeasurable.czRemainder (hα : 0 < α) {hf : BoundedFiniteSupport f} :
    AEMeasurable (czRemainder f α) := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.16) (both cases).
This is true by definition, the work lies in `tsum_czRemainder'` -/
lemma czApproximation_add_czRemainder {x : X} :
    czApproximation f α x + czRemainder f α x = f x := by
  sorry

private lemma α_le_mul_α : α ≤ 2 ^ (3 * a) * α := by
  sorry

-- Equation (10.2.17), finite case
private lemma enorm_czApproximation_le_finite
    (hα : ⨍⁻ x, ‖f x‖ₑ ≤ α) (hX : ¬ GeneralCase f α) :
    ∀ᵐ x, ‖czApproximation f α x‖ₑ ≤ 2 ^ (3 * a) * α := by
  sorry

/-- Equation (10.2.17) specialized to the general case. -/
lemma enorm_czApproximation_le_infinite {hf : BoundedFiniteSupport f} (hX : GeneralCase f α) :
    ∀ᵐ x, ‖czApproximation f α x‖ₑ ≤ 2 ^ (3 * a) * α := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.17) (both cases). -/
lemma enorm_czApproximation_le
    {hf : BoundedFiniteSupport f} (hα : ⨍⁻ x, ‖f x‖ₑ ≤ α) :
    ∀ᵐ x, ‖czApproximation f α x‖ₑ ≤ 2 ^ (3 * a) * α := by
  sorry

-- Equation (10.2.18), finite case
private lemma eLpNorm_czApproximation_le_finite
    (hf : BoundedFiniteSupport f) (hα : 0 < α) (hX : ¬ GeneralCase f α) :
    eLpNorm (czApproximation f α) 1 volume ≤ eLpNorm f 1 volume := by
  sorry

-- Equation (10.2.18), infinite case
private lemma eLpNorm_czApproximation_le_infinite (hX : GeneralCase f α) :
    eLpNorm (czApproximation f α) 1 volume ≤ eLpNorm f 1 volume := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.18) (both cases). -/
lemma eLpNorm_czApproximation_le
    {hf : BoundedFiniteSupport f} (hα : 0 < α) :
    eLpNorm (czApproximation f α) 1 volume ≤ eLpNorm f 1 volume := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.19) (general case). -/
lemma support_czRemainder'_subset {hX : GeneralCase f α} {i : ℕ} :
    support (czRemainder' hX i) ⊆ czBall3 hX i := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.20) (general case). -/
lemma integral_czRemainder' {hX : GeneralCase f α} {i : ℕ} :
    ∫ x, czRemainder' hX i x = 0 := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.20) (finite case). -/
lemma integral_czRemainder {hf : BoundedFiniteSupport f}
    (hX : ¬ GeneralCase f α) (hα : 0 < α) :
    ∫ x, czRemainder f α x = 0 := by
  sorry

-- Inequality (10.2.32)
private lemma ineq_10_2_32 (hf : BoundedFiniteSupport f) {hX : GeneralCase f α}
    {i : ℕ} :
    eLpNorm (czRemainder' hX i) 1 volume ≤ 2 * (∫⁻ x in czPartition hX i, ‖f x‖ₑ) := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.21) (general case). -/
lemma eLpNorm_czRemainder'_le {hf : BoundedFiniteSupport f} {hX : GeneralCase f α}
    {i : ℕ} :
    eLpNorm (czRemainder' hX i) 1 volume ≤ 2 ^ (2 * a + 1) * α * volume (czBall3 hX i) := by
  sorry

-- Weaker version of `eLpNorm_czRemainder'_le` which is used repeatedly below
private lemma eLpNorm_restrict_czRemainder'_le {hf : BoundedFiniteSupport f} {hX : GeneralCase f α}
    {i : ℕ} :
    ∫⁻ y in czBall3 hX i, ‖czRemainder' hX i y‖ₑ ≤ 2 ^ (2 * a + 1) * α * volume (czBall3 hX i) := by
  sorry

-- Used to prove `eLpNorm_czRemainder_le` and `tsum_eLpNorm_czRemainder_le`
private lemma eLpNorm_czRemainder_le'
    (hf : BoundedFiniteSupport f) (hX : ¬ GeneralCase f α) (hα : ⨍⁻ x, ‖f x‖ₑ < α) :
    eLpNorm (czRemainder f α) 1 volume ≤ 2 * ∫⁻ x, ‖f x‖ₑ := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.21) (finite case). -/
lemma eLpNorm_czRemainder_le {hf : BoundedFiniteSupport f}
    (hX : ¬ GeneralCase f α) (hα : ⨍⁻ x, ‖f x‖ₑ < α) :
    eLpNorm (czRemainder f α) 1 volume ≤ 2 ^ (2 * a + 1) * α * volume (univ : Set X) := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.22) (general case). -/
lemma tsum_volume_czBall3_le (hf : BoundedFiniteSupport f)
    (hX : GeneralCase f α) (hα : 0 < α) :
    ∑' i, volume (czBall3 hX i) ≤ 2 ^ (6 * a) / α * eLpNorm f 1 volume := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.22) (finite case). -/
lemma volume_univ_le (hf : BoundedFiniteSupport f) (hX : ¬GeneralCase f α) (hα : 0 < α) :
    volume (univ : Set X) ≤ 2 ^ (4 * a) / α * eLpNorm f 1 volume := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.23) (general case). -/
lemma tsum_eLpNorm_czRemainder'_le {hf : BoundedFiniteSupport f} (hX : GeneralCase f α) :
    ∑' i, eLpNorm (czRemainder' hX i) 1 volume ≤ 2 * eLpNorm f 1 volume := by
  sorry

/-- Part of Lemma 10.2.5, equation (10.2.23) (finite case). -/
lemma tsum_eLpNorm_czRemainder_le
    {hf : BoundedFiniteSupport f} (hX : ¬ GeneralCase f α) (hα : ⨍⁻ x, ‖f x‖ₑ < α) :
    eLpNorm (czRemainder f α) 1 volume ≤ 2 * eLpNorm f 1 volume := by
  sorry

/- ### Lemmas 10.2.6 - 10.2.9 -/

/-- The constant `c` introduced below Lemma 10.2.5. -/
irreducible_def c10_0_3 (a : ℕ) : ℝ≥0 := (2 ^ (a ^ 3 + 12 * a + 4))⁻¹

open scoped Classical in
variable (f) in
/-- The set `Ω` introduced below Lemma 10.2.5. -/
def Ω (α : ℝ≥0∞) : Set X :=
  if hX : GeneralCase f α then ⋃ i, czBall6 hX i else univ

private lemma czBall3_subset_of_mem_Ω (hX : GeneralCase f α) (hx : x ∈ (Ω f α)ᶜ) (j : ℕ) :
    czBall3 hX j ⊆ (ball x (czRadius hX j))ᶜ := by
  sorry

private lemma six_mul_czRadius_le_of_mem_Ω (hx : x ∈ (Ω f α)ᶜ) (hX : GeneralCase f α) (j : ℕ) :
    6 * czRadius hX j ≤ dist x (czCenter hX j) := by
  sorry

/-- The constant used in `estimate_good`. -/
irreducible_def C10_2_6 (a : ℕ) : ℝ≥0 := 2 ^ (2 * a ^ 3 + 3 * a + 2) * c10_0_3 a

variable (a) in
/-- Auxiliary constant used in the proofs of `estimate_good`, `estimate_bad` and
`distribution_czOperatorBound`. -/
@[no_expose] def α' (α : ℝ≥0∞) : ℝ≥0∞ := c10_0_3 a * α

private lemma α'_pos {α : ℝ≥0∞} (hα : 0 < α) : 0 < α' a α := by
  sorry

private lemma div_α'_eq {p : ℝ≥0∞} : p / α' a α = p / c10_0_3 a / α := by
  sorry

/-- Lemma 10.2.6 -/
lemma estimate_good (hf : BoundedFiniteSupport f) (hα : ⨍⁻ x, ‖f x‖ₑ / c10_0_3 a < α)
    (hT : HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a)) :
    distribution (czOperator K r (czApproximation f (α' a α))) (α / 2) volume ≤
    C10_2_6 a / α * eLpNorm f 1 volume := by
  sorry

/-- The constant used in `czOperatorBound`. -/
irreducible_def C10_2_7 (a : ℕ) : ℝ≥0 := 2 ^ (a ^ 3 + 2 * a + 1) * c10_0_3 a

private abbrev czOperatorBoundSummand (hX : GeneralCase f (α' a α)) (i : ℕ) (x : X) : ℝ≥0∞ :=
  C10_2_7 a * α * (((3 * czRadius hX i).toNNReal / nndist x (czCenter hX i)) ^ (a : ℝ)⁻¹ *
    volume (czBall3 hX i)) / volume (ball x (dist x (czCenter hX i)))

/-- The function `F` defined in Lemma 10.2.7. -/
def czOperatorBound (hX : GeneralCase f (α' a α)) (x : X) : ℝ≥0∞ :=
  C10_2_7 a * α * ∑' i, ((3 * czRadius hX i).toNNReal / nndist x (czCenter hX i)) ^ (a : ℝ)⁻¹ *
    volume (czBall3 hX i) / volume (ball x (dist x (czCenter hX i)))

private lemma czOperatorBound_eq (hX : GeneralCase f (α' a α)) (x : X) :
    czOperatorBound hX x = ∑' i, czOperatorBoundSummand hX i x := by
  sorry

private def 𝒥₁ (r : ℝ) (x : X) (hX : GeneralCase f (α' a α)) : Set ℕ :=
  {j | r + 3 * czRadius hX j ≤ dist x (czCenter hX j) }

private def 𝒥₂ (r : ℝ) (x : X) (hX : GeneralCase f (α' a α)) : Set ℕ :=
  {j | r - 3*czRadius hX j ≤ dist x (czCenter hX j) ∧ dist x (czCenter hX j) < r + 3*czRadius hX j }

private def 𝒥₃ (r : ℝ) (x : X) (hX : GeneralCase f (α' a α)) : Set ℕ :=
  {j | dist x (czCenter hX j) < r - 3*czRadius hX j }

private lemma union_𝒥 (r : ℝ) (x : X) (hX : GeneralCase f (α' a α)) :
    𝒥₁ r x hX ∪ 𝒥₂ r x hX ∪ 𝒥₃ r x hX = univ := by
  sorry

-- Auxiliary bound used to prove `lemma_10_2_7_bound`
private lemma lemma_10_2_7_bound' (hx : x ∈ (Ω f (α' a α))ᶜ) (hX : GeneralCase f (α' a α)) (j : ℕ)
    {g : X → ℂ} (g_aemeas : AEMeasurable g (volume.restrict (czBall3 hX j)))
    (hg : ∫⁻ y in czBall3 hX j, ‖g y‖ₑ ≤ 2 ^ (2 * a + 1) * (α' a α) * volume (czBall3 hX j)) :
    ∫⁻ y in czBall3 hX j, ‖K x y - K x (czCenter hX j)‖ₑ * ‖g y‖ₑ ≤
    czOperatorBoundSummand hX j x := by
  sorry

-- Bound used twice in the proof of Lemma 10.2.7
private lemma lemma_10_2_7_bound (hx : x ∈ (Ω f (α' a α))ᶜ) (hX : GeneralCase f (α' a α)) (j : ℕ)
    {g : X → ℂ} (g_int : IntegrableOn g (czBall3 hX j)) (hg0 : ∫ y in czBall3 hX j, g y = 0)
    (hg : ∫⁻ y in czBall3 hX j, ‖g y‖ₑ ≤ 2 ^ (2 * a + 1) * (α' a α) * volume (czBall3 hX j)) :
    ‖∫ y in czBall3 hX j, K x y * g y‖ₑ ≤ czOperatorBoundSummand hX j x := by
  sorry

private lemma 𝒥₁_bound (hf : BoundedFiniteSupport f) (hα : 0 < α) (hx : x ∈ (Ω f (α' a α))ᶜ)
    (hX : GeneralCase f (α' a α)) {j : ℕ} (hj : j ∈ 𝒥₁ r x hX) :
    ‖czOperator K r (czRemainder' hX j) x‖ₑ ≤ czOperatorBoundSummand hX j x := by
  sorry

private lemma tsum_𝒥₁ (hf : BoundedFiniteSupport f) (hα : 0 < α)
    (hX : GeneralCase f (α' a α)) (hx : x ∈ (Ω f (α' a α))ᶜ) :
    ∑' (j : ↑(𝒥₁ r x hX)), ‖czOperator K r (czRemainder' hX ↑j) x‖ₑ ≤ czOperatorBound hX x := by
  sorry

-- The value dⱼ defined below inequality (10.2.48)
variable (r) (x) in
private def d (hX : GeneralCase f (α' a α)) (j : ℕ) :=
  ⨍ y in czBall3 hX j, (ball x r)ᶜ.indicator (czRemainder' hX j) y

private lemma integrableOn_d (hX : GeneralCase f (α' a α)) (j : ℕ) :
    Integrable (fun _ ↦ d r x hX j) (volume.restrict (czBall3 hX j)) := by
  sorry

private lemma enorm_d_le (hf : BoundedFiniteSupport f) (hX : GeneralCase f (α' a α)) (j : ℕ) :
    ‖d r x hX j‖ₑ ≤ 2 ^ (2 * a + 1) * α' a α := by
  sorry

-- The next two functions are integrands involved in the 𝒥₂ section of the proof of Lemma 10.2.7
variable (r) (x) in
private abbrev g₀ (hX : GeneralCase f (α' a α)) (j : ℕ) (y : X) :=
  (ball x r)ᶜ.indicator (czRemainder' hX j) y

variable (r) (x) in
private abbrev g (hX : GeneralCase f (α' a α)) (j : ℕ) (y : X) :=
  g₀ r x hX j y - d r x hX j

private lemma integrableOn_g₀ (hf : BoundedFiniteSupport f) (hα : 0 < α)
    (hX : GeneralCase f (α' a α)) (j : ℕ) : IntegrableOn (g₀ r x hX j) (czBall3 hX j) := by
  sorry

private lemma lintegral_enorm_g₀_le (hf : BoundedFiniteSupport f)
    (hX : GeneralCase f (α' a α)) (j : ℕ) :
    ∫⁻ y in czBall3 hX j, ‖g₀ r x hX j y‖ₑ ≤ 2 ^ (2*a + 1) * α' a α * volume (czBall3 hX j) := by
  sorry

variable (r) (x) in
private lemma integrableOn_g (hα : 0 < α) (hf : BoundedFiniteSupport f)
    (hX : GeneralCase f (α' a α)) (j : ℕ) : IntegrableOn (g r x hX j) (czBall3 hX j) := by
  sorry

private lemma integral_g (hf : BoundedFiniteSupport f) (hα : 0 < α) (hX : GeneralCase f (α' a α))
    (j : ℕ) : ∫ y in czBall3 hX j, g r x hX j y = 0 := by
  sorry

private lemma lintegral_enorm_half_g (hf : BoundedFiniteSupport f) (hα : 0 < α)
    (hX : GeneralCase f (α' a α)) (j : ℕ) :
    ∫⁻ y in czBall3 hX j, ‖2⁻¹ * g r x hX j y‖ₑ ≤
    2 ^ (2 * a + 1) * α' a α * volume (czBall3 hX j) := by
  sorry

-- The bounds on `‖czOperator K r (czRemainder' hX j) x‖ₑ` used for the `𝒥₂` estimate (even
-- though this part of the estimate doesn't require j ∈ 𝒥₂).
private lemma 𝒥₂_bound (hf : BoundedFiniteSupport f) (hα : 0 < α) (hx : x ∈ (Ω f (α' a α))ᶜ)
    (hX : GeneralCase f (α' a α)) {j : ℕ} :
    ‖czOperator K r (czRemainder' hX j) x‖ₑ ≤ 2 * czOperatorBoundSummand hX j x +
      2 ^ (2 * a + 1) * (α' a α) * ∫⁻ y in czBall3 hX j, ‖K x y‖ₑ := by
  sorry

-- The set `A` defined between (10.2.51) and (10.2.52)
variable (r) (x) in
private def A (hX : GeneralCase f (α' a α)) : Set X := ⋃ (j : ↑(𝒥₂ r x hX)), czBall3 hX j

-- (10.2.52)
private lemma A_subset (hx : x ∈ (Ω f (α' a α))ᶜ) (hX : GeneralCase f (α' a α)) :
    A r x hX ⊆ Annulus.co x (r / 3) (3 * r) := by
  sorry

private lemma sum_volume_restrict_le (hX : GeneralCase f (α' a α)) :
    Measure.sum (fun (j : 𝒥₂ r x hX) ↦ volume.restrict (czBall3 hX j)) ≤
    2 ^ (6 * a) • volume.restrict (A r x hX) := by
  sorry

-- Long calculation toward the end of Lemma 10.2.7
private lemma tsum_integral_K_le (hx : x ∈ (Ω f (α' a α))ᶜ) (hX : GeneralCase f (α' a α)) :
    ∑' (j : 𝒥₂ r x hX), ∫⁻ y in czBall3 hX j, ‖K x y‖ₑ ≤ 2 ^ (a ^ 3 + 10 * a) := by
  sorry

private lemma tsum_𝒥₂ (hf : BoundedFiniteSupport f) (hα : 0 < α) (hx : x ∈ (Ω f (α' a α))ᶜ)
    (hX : GeneralCase f (α' a α)) :
    ∑' (j : 𝒥₂ r x hX), ‖czOperator K r (czRemainder' hX j) x‖ₑ ≤
    2 * czOperatorBound hX x + α / 8 := by
  sorry

omit [IsTwoSidedKernel a K] in
private lemma tsum_𝒥₃ (hX : GeneralCase f (α' a α)) :
    ∑' (j : 𝒥₃ r x hX), ‖czOperator K r (czRemainder' hX j) x‖ₑ = 0 := by
  sorry

omit [IsTwoSidedKernel a K] in
private lemma czOperator_czRemainder' (hX : GeneralCase f α) (i : ℕ) :
    czOperator K r (czRemainder' hX i) x =
    ∫ y in (ball x r)ᶜ ∩ czPartition hX i, K x y * czRemainder f α y := by
  sorry

private lemma czOperator_czRemainder (hf : BoundedFiniteSupport f) (hr : 0 < r) (hα : 0 < α)
    (hX : GeneralCase f α) :
    czOperator K r (czRemainder f α) x = ∑' i, czOperator K r (czRemainder' hX i) x := by
  sorry

/-- Lemma 10.2.7.
Note that `hx` implies `hX`, but we keep the superfluous hypothesis to shorten the statement. -/
lemma estimate_bad_partial (hf : BoundedFiniteSupport f) (hr : 0 < r)
    (hα : ⨍⁻ x, ‖f x‖ₑ / c10_0_3 a < α)
    (hx : x ∈ (Ω f (α' a α))ᶜ) (hX : GeneralCase f (α' a α)) :
    ‖czOperator K r (czRemainder f (α' a α)) x‖ₑ ≤ 3 * czOperatorBound hX x + α / 8 := by
  sorry

lemma czOperatorBound_inner_le (ha : 4 ≤ a) (hX : GeneralCase f (α' a α)) {i : ℕ} :
    ∫⁻ x in (Ω f (α' a α))ᶜ, ((3 * czRadius hX i).toNNReal / edist x (czCenter hX i)) ^ (a : ℝ)⁻¹ /
      volume (ball x (dist x (czCenter hX i))) ≤ 2 ^ (3 * a) := by
  sorry

/-- The constant used in `distribution_czOperatorBound`. -/
irreducible_def C10_2_8 (a : ℕ) : ℝ≥0 := 2 ^ (a ^ 3 + 11 * a + 4)

/-- Lemma 10.2.8 -/
lemma distribution_czOperatorBound (ha : 4 ≤ a) (hf : BoundedFiniteSupport f)
    (hα : ⨍⁻ x, ‖f x‖ₑ / c10_0_3 a < α) (hX : GeneralCase f (α' a α)) :
    volume ((Ω f (α' a α))ᶜ ∩ czOperatorBound hX ⁻¹' Ioi (α / 8)) ≤
    C10_2_8 a / α * eLpNorm f 1 volume := by
  sorry

/-- The constant used in `estimate_bad`. -/
irreducible_def C10_2_9 (a : ℕ) : ℝ≥0 := 2 ^ (7 * a) / c10_0_3 a + C10_2_8 a

/-- Lemma 10.2.9 -/
lemma estimate_bad (ha : 4 ≤ a) (hr : 0 < r)
    (hf : BoundedFiniteSupport f) (hα : ⨍⁻ x, ‖f x‖ₑ / c10_0_3 a < α) :
    distribution (czOperator K r (czRemainder f (α' a α))) (α / 2) volume ≤
    C10_2_9 a / α * eLpNorm f 1 volume := by
  sorry

/- ### Lemma 10.0.3 -/

/-- The constant used in `czOperator_weak_1_1`. -/
irreducible_def C10_0_3 (a : ℕ) : ℝ≥0 := 2 ^ (a ^ 3 + 21 * a)

/-- Lemma 10.0.3, blueprint form. -/
lemma estimate_czOperator (ha : 4 ≤ a) (hr : 0 < r) (hf : BoundedFiniteSupport f)
    (hT : HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a)) :
    distribution (czOperator K r f) α volume ≤ C10_0_3 a / α * eLpNorm f 1 volume := by
  sorry

/-- Lemma 10.0.3, formulated differently. The blueprint version is basically this after
unfolding `HasBoundedWeakType`, `wnorm` and `wnorm'`. -/
theorem czOperator_weak_1_1 (ha : 4 ≤ a) (hr : 0 < r)
    (hT : HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a)) :
    HasBoundedWeakType (czOperator K r) 1 1 volume volume (C10_0_3 a) := by
  sorry

end
