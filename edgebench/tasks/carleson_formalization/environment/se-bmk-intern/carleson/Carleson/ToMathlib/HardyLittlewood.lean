module

public import Carleson.Defs
public import Carleson.ToMathlib.Order.ConditionallyCompleteLattice.Indexed
public import Carleson.ToMathlib.RealInterpolation.Main
public import Mathlib.MeasureTheory.Covering.Vitali
public import Mathlib.MeasureTheory.Integral.Average
public import Carleson.ToMathlib.MeasureTheory.Function.LpSeminorm.Basic
public import Mathlib.Tactic.Field

@[expose] public section

open MeasureTheory Metric Bornology Set TopologicalSpace Vitali Filter Pointwise
open ENNReal hiding one_lt_two
open scoped NNReal
noncomputable section

/-! This should roughly contain the contents of chapter 9. -/

-- Upstreaming status: aside from getting the real interpolation theorem merged,
-- this file needs a bunch of clean-up before it can be upstreamed:
-- moving preliminary lemmas to their appropriate homes (some of these lemmas do not belong in
-- mathlib) and improving the code quality. Follow mathlib style (line length!), can use dot
-- notation more, and the code can sometimes also be golfed.

section Prelude

variable {X : Type*} [PseudoMetricSpace X] [SeparableSpace X]

variable (X) in
/-- Lemma 9.0.2 -/
-- maybe not suited for Mathlib in this form
lemma covering_separable_space :
    ∃ C : Set X, C.Countable ∧ ∀ r > 0, ⋃ c ∈ C, ball c r = univ := by
  sorry

-- maybe not suited for Mathlib in this form
lemma countable_globalMaximalFunction :
    (covering_separable_space X).choose ×ˢ (univ : Set ℤ) |>.Countable := by
  sorry

-- probably not suited for Mathlib in this form
lemma exists_ball_subset_ball_two (c : X) {r : ℝ} (hr : 0 < r) :
    ∃ c' ∈ (covering_separable_space X).choose,
      ∃ m : ℤ, ball c r ⊆ ball c' (2 ^ m) ∧ 2 ^ m ≤ 2 * r ∧ ball c' (2 ^ m) ⊆ ball c (4 * r) := by
  sorry

end Prelude

variable {X E : Type*} {A : ℝ≥0} [MetricSpace X] [MeasurableSpace X]
  {μ : Measure X} [μ.IsDoubling A] [NormedAddCommGroup E]
  {f : X → E} {x : X} {ι : Type*} {𝓑 : Set ι} {c : ι → X} {r : ι → ℝ}
  -- feel free to assume `A ≥ 16` or similar

/-- The Hardy-Littlewood maximal function w.r.t. a collection of balls 𝓑.
M_{𝓑, p} in the blueprint. -/
def maximalFunction (μ : Measure X) (𝓑 : Set ι) (c : ι → X) (r : ι → ℝ)
    (p : ℝ) (u : X → E) (x : X) : ℝ≥0∞ :=
  ⨆ i ∈ 𝓑, (ball (c i) (r i)).indicator (x := x)
    fun _ ↦ (⨍⁻ y in ball (c i) (r i), ‖u y‖ₑ ^ p ∂μ) ^ p⁻¹

/-- The Hardy-Littlewood maximal function w.r.t. a collection of balls 𝓑 with exponent 1.
M_𝓑 in the blueprint. -/
abbrev MB (μ : Measure X) (𝓑 : Set ι) (c : ι → X) (r : ι → ℝ) (u : X → E) (x : X) : ℝ≥0∞ :=
  maximalFunction μ 𝓑 c r 1 u x

lemma MB_def : MB μ 𝓑 c r f x = (⨆ i ∈ 𝓑, (ball (c i) (r i)).indicator (x := x)
    fun _ ↦ ⨍⁻ y in ball (c i) (r i), ‖f y‖ₑ ∂μ) := by
  sorry

lemma indicator_rpow {α : Type*} {p : ℝ} (hp : 0 < p) {s : Set α} {f : α → ℝ≥0∞} :
    s.indicator (fun y ↦ f y ^ p) = (s.indicator f) ^ p := by
  sorry

lemma maximalFunction_eq_MB
    {μ : Measure X} {𝓑 : Set ι} {c : ι → X} {r : ι → ℝ} {p : ℝ} {u : X → E} {x : X} (hp : 0 < p) :
    maximalFunction μ 𝓑 c r p u x = (MB μ 𝓑 c r (‖u ·‖ ^ p) x) ^ p⁻¹ := by
  sorry

-- We will replace the criterion `P` used in `MeasureTheory.AESublinearOn.maximalFunction` with the
-- weaker criterion `LocallyIntegrable` that is closed under addition and scalar multiplication.

-- The average that appears in the definition of `MB`
variable (μ c r) in
private def T (i : ι) (u : X → E) := ⨍⁻ (y : X) in ball (c i) (r i), ‖u y‖ₑ ∂μ

-- move
lemma MeasureTheory.LocallyIntegrable.integrableOn_of_isBounded [ProperSpace X]
    {f : X → E} (hf : LocallyIntegrable f μ) {s : Set X}
    (hs : IsBounded s) : IntegrableOn f s μ := by
  sorry

-- move
lemma MeasureTheory.LocallyIntegrable.integrableOn_ball [ProperSpace X]
    {f : X → E} (hf : LocallyIntegrable f μ) {x : X} {r : ℝ} : IntegrableOn f (ball x r) μ := by
  sorry

-- probably unsuitable for Mathlib
lemma MeasureTheory.LocallyIntegrable.laverage_ball_lt_top [ProperSpace X] {f : X → E}
    (hf : LocallyIntegrable f μ) {x₀ : X} {r : ℝ} :
    ⨍⁻ x in ball x₀ r, ‖f x‖ₑ ∂μ < ⊤ := by
  sorry

private lemma T.add_le [MeasurableSpace E] [BorelSpace E] [BorelSpace X] [ProperSpace X]
    (i : ι) {f g : X → E} (hf : LocallyIntegrable f μ) :
    ‖T μ c r i (f + g)‖ₑ ≤ ‖T μ c r i f‖ₑ + ‖T μ c r i g‖ₑ := by
  sorry

-- move to `ENNReal.Basic` or similar
lemma NNReal.smul_ennreal_eq_mul (x : ℝ≥0) (y : ℝ≥0∞) : x • y = x * y := by
  sorry

private lemma T.smul [NormedSpace ℝ E] (i : ι) {f : X → E} {d : ℝ≥0} :
    T μ c r i (d • f) = d • T μ c r i f := by
  sorry

-- move near `exists_disjoint_subfamily_covering_enlargement_closedBall`
-- slightly more general than the Mathlib version
-- the extra conclusion says that if there is a nonnegative radius, then we can choose `r b` to be
-- larger than `r a` (up to a constant)
theorem exists_disjoint_subfamily_covering_enlargement_closedBall' {α} [MetricSpace α] (t : Set ι)
    (x : ι → α) (r : ι → ℝ) (R : ℝ) (hr : ∀ a ∈ t, r a ≤ R) (τ : ℝ) (hτ : 3 < τ) :
    ∃ u ⊆ t,
      (u.PairwiseDisjoint fun a => closedBall (x a) (r a)) ∧
        ∀ a ∈ t, ∃ b ∈ u, closedBall (x a) (r a) ⊆ closedBall (x b) (τ * r b) ∧
        (∀ u ∈ t, 0 ≤ r u → r a ≤ (τ - 1) / 2 * r b) := by
  sorry

-- move to Vitali
theorem Vitali.exists_disjoint_subfamily_covering_enlargement_ball {α} [MetricSpace α] (t : Set ι)
    (x : ι → α) (r : ι → ℝ) (R : ℝ) (hr : ∀ a ∈ t, r a ≤ R) (τ : ℝ) (hτ : 3 < τ) :
    ∃ u ⊆ t,
      (u.PairwiseDisjoint fun a => ball (x a) (r a)) ∧
        ∀ a ∈ t, ∃ b ∈ u, ball (x a) (r a) ⊆ ball (x b) (τ * r b) := by
  sorry

-- move next to Finset.exists_le
lemma Finset.exists_image_le {α β} [Nonempty β] [Preorder β] [IsDirected β (· ≤ ·)]
    (s : Finset α) (f : α → β) : ∃ b : β, ∀ a ∈ s, f a ≤ b := by
  sorry

-- move
lemma Set.Finite.exists_image_le {α β} [Nonempty β] [Preorder β] [IsDirected β (· ≤ ·)]
    {s : Set α} (hs : s.Finite) (f : α → β) : ∃ b : β, ∀ a ∈ s, f a ≤ b := by
  sorry

theorem Set.Countable.measure_biUnion_le_lintegral [OpensMeasurableSpace X] (h𝓑 : 𝓑.Countable)
    (l : ℝ≥0∞) (u : X → ℝ≥0∞) (R : ℝ) (hR : ∀ a ∈ 𝓑, r a ≤ R)
    (h2u : ∀ i ∈ 𝓑, l * μ (ball (c i) (r i)) ≤ ∫⁻ x in ball (c i) (r i), u x ∂μ) :
    l * μ (⋃ i ∈ 𝓑, ball (c i) (r i)) ≤ A ^ 2 * ∫⁻ x, u x ∂μ  := by
  sorry

protected theorem Finset.measure_biUnion_le_lintegral [OpensMeasurableSpace X] (𝓑 : Finset ι)
    (l : ℝ≥0∞) (u : X → ℝ≥0∞)
    (h2u : ∀ i ∈ 𝓑, l * μ (ball (c i) (r i)) ≤ ∫⁻ x in ball (c i) (r i), u x ∂μ) :
    l * μ (⋃ i ∈ 𝓑, ball (c i) (r i)) ≤ A ^ 2 * ∫⁻ x, u x ∂μ  := by
  sorry

lemma lowerSemiContinuous_maximalFunction {p : ℝ} :
    LowerSemicontinuous (maximalFunction μ 𝓑 c r p f) := by
  sorry

protected theorem MeasureTheory.Measurable.maximalFunction [BorelSpace X] {p : ℝ}
    {u : X → E} : Measurable (maximalFunction μ 𝓑 c r p u) := by
  sorry

theorem MeasureTheory.Measurable.maximalFunction_toReal [BorelSpace X] {p : ℝ} {u : X → E} :
    Measurable (fun x ↦ maximalFunction μ 𝓑 c r p u x |>.toReal) := by
  sorry

theorem MB_le_eLpNormEssSup {u : X → E} {x : X} : MB μ 𝓑 c r u x ≤ eLpNormEssSup u μ := by
  sorry

protected theorem HasStrongType.MB_top [BorelSpace X] :
    HasStrongType (fun (u : X → E) (x : X) ↦ MB μ 𝓑 c r u x) ⊤ ⊤ μ μ 1 := by
  sorry

/- The proof is roughly between (9.0.12)-(9.0.22). -/
protected theorem HasWeakType.MB_one [BorelSpace X] (h𝓑 : 𝓑.Countable)
    {R : ℝ} (hR : ∀ i ∈ 𝓑, r i ≤ R) :
    HasWeakType (MB (E := E) μ 𝓑 c r) 1 1 μ μ (A ^ 2) := by
  sorry

include A in
theorem MB_ae_ne_top [BorelSpace X] (h𝓑 : 𝓑.Countable)
    {R : ℝ} (hR : ∀ i ∈ 𝓑, r i ≤ R)
    {u : X → E} (hu : MemLp u 1 μ) : ∀ᵐ x : X ∂μ, MB μ 𝓑 c r u x ≠ ∞ := by
  sorry

-- move
lemma MeasureTheory.MemLp.eLpNormEssSup_lt_top {α} [MeasurableSpace α] {μ : Measure α}
    {u : α → E} (hu : MemLp u ⊤ μ) : eLpNormEssSup u μ < ⊤ := by
  sorry

include A in
theorem MB_ae_ne_top' [BorelSpace X] (h𝓑 : 𝓑.Countable)
    {R : ℝ} (hR : ∀ i ∈ 𝓑, r i ≤ R)
    ⦃u : X → E⦄ (hu : MemLp u ∞ μ ∨ MemLp u 1 μ) : ∀ᵐ x : X ∂μ, MB μ 𝓑 c r u x ≠ ∞ := by
  sorry

include A in
protected theorem MeasureTheory.AESublinearOn.maximalFunction
    [BorelSpace X] [NormedSpace ℝ E] [MeasurableSpace E] [BorelSpace E]
    [IsFiniteMeasureOnCompacts μ] [ProperSpace X] (h𝓑 : 𝓑.Countable)
    {R : ℝ} (hR : ∀ i ∈ 𝓑, r i ≤ R) :
    AESublinearOn (fun (u : X → E) (x : X) ↦ MB μ 𝓑 c r u x)
    (fun f ↦ MemLp f ∞ μ ∨ MemLp f 1 μ) 1 μ := by
  sorry

/-- The constant factor in the statement that `M_𝓑` has strong type. -/
irreducible_def CMB (A p : ℝ≥0) : ℝ≥0 := C_realInterpolation ⊤ 1 ⊤ 1 p 1 (A ^ 2) 1 p⁻¹

lemma CMB_eq_of_one_lt_q {b q : ℝ≥0} (hq : 1 < q) :
    CMB b q = 2 * (q / (q - 1) * b ^ 2) ^ (q : ℝ)⁻¹ := by
  sorry

lemma CMB_defaultA_two_eq {a : ℕ} : CMB (defaultA a) 2 = 2 ^ (a + (3 / 2 : ℝ)) := by
  sorry

/-- Special case of equation (2.0.44). The proof is given between (9.0.12) and (9.0.34).
Use the real interpolation theorem instead of following the blueprint. -/
lemma hasStrongType_MB [BorelSpace X] [NormedSpace ℝ E] [MeasurableSpace E] [BorelSpace E]
    [IsFiniteMeasureOnCompacts μ] [ProperSpace X] [Nonempty X] [μ.IsOpenPosMeasure]
    (h𝓑 : 𝓑.Countable) {R : ℝ} (hR : ∀ i ∈ 𝓑, r i ≤ R) {p : ℝ≥0} (hp : 1 < p) :
    HasStrongType (fun (u : X → E) (x : X) ↦ MB μ 𝓑 c r u x) p p μ μ (CMB A p) := by
  sorry

lemma hasStrongType_MB_finite [BorelSpace X] [NormedSpace ℝ E] [MeasurableSpace E] [BorelSpace E]
    [IsFiniteMeasureOnCompacts μ] [ProperSpace X] [Nonempty X] [μ.IsOpenPosMeasure]
    (h𝓑 : 𝓑.Finite) {p : ℝ≥0} (hp : 1 < p) :
    HasStrongType (fun (u : X → E) (x : X) ↦ MB μ 𝓑 c r u x) p p μ μ (CMB A p) := by
  sorry

/-- The constant factor in the statement that `M_{𝓑, p}` has strong type. -/
irreducible_def C2_0_6 (A p₁ p₂ : ℝ≥0) : ℝ≥0 := CMB A (p₂ / p₁) ^ (p₁⁻¹ : ℝ)

/-- Equation (2.0.44). The proof is given between (9.0.34) and (9.0.36).
This is a special case of `hasStrongType_maximalFunction` below, which doesn't have the assumption
`hR` (but uses this result in its proof). -/
theorem hasStrongType_maximalFunction_aux
    [BorelSpace X] [IsFiniteMeasureOnCompacts μ] [ProperSpace X] [μ.IsOpenPosMeasure]
    {p₁ p₂ : ℝ≥0} (h𝓑 : 𝓑.Countable) {R : ℝ} (hR : ∀ i ∈ 𝓑, r i ≤ R) (hp₁ : 0 < p₁) (hp₁₂ : p₁ < p₂) :
    HasStrongType (fun (u : X → E) x ↦ maximalFunction μ 𝓑 c r p₁ u x) p₂ p₂ μ μ
      (C2_0_6 A p₁ p₂) := by
  sorry

variable (𝓑 r) in
def tr (k : ℕ) : Set ι := {i | i ∈ 𝓑 ∧ r i ≤ k}

lemma tr_subset (k : ℕ) : tr 𝓑 r k ⊆ 𝓑 := by
  sorry

lemma tr_radius_le (k : ℕ) : ∀ i ∈ tr 𝓑 r k, r i ≤ k := by
  sorry

lemma tr_mono {k₁ k₂ : ℕ} (h : k₁ ≤ k₂) : tr 𝓑 r k₁ ⊆ tr 𝓑 r k₂ := by
  sorry

def maximalFunction_seq (μ : Measure X) (𝓑 : Set ι) (c : ι → X) (r : ι → ℝ) (q : ℝ) (k : ℕ)
    (u : X → E) (z : X) : ℝ≥0∞ :=
  maximalFunction μ (tr 𝓑 r k) c r q u z

lemma maximalFunction_seq_mono {p : ℝ} {𝓑 : Set ι} :
    Monotone (maximalFunction_seq (E := E) μ 𝓑 c r p) := by
  sorry

lemma maximalFunction_seq_eq (𝓑 : Set ι) (p : ℝ) :
    maximalFunction (E := E) μ 𝓑 c r p = fun u x => ⨆ k : ℕ, maximalFunction_seq μ 𝓑 c r p k u x := by
  sorry

/-- Version of `hasWeakType_maximalFunction_equal_exponents` with the additional assumption `hR`.
-/
theorem hasWeakType_maximalFunction_equal_exponents_aux [BorelSpace X]
    {p : ℝ≥0} (h𝓑 : 𝓑.Countable) {R : ℝ} (hR : ∀ i ∈ 𝓑, r i ≤ R) (hp : 0 < p) :
    HasWeakType (maximalFunction (E := E) μ 𝓑 c r p) p p μ μ (A ^ ((2 / p : ℝ))) := by
  sorry

/-- `hasStrongType_maximalFunction` minus the assumption `hR`.
A proof for basically this result is given in Chapter 9, everything following after equation
(9.0.36). -/
theorem hasStrongType_maximalFunction
    [BorelSpace X] [IsFiniteMeasureOnCompacts μ] [ProperSpace X] [μ.IsOpenPosMeasure]
    {p₁ p₂ : ℝ≥0} (h𝓑 : 𝓑.Countable) (hp₁ : 0 < p₁) (hp₁₂ : p₁ < p₂) :
    HasStrongType (maximalFunction (E := E) μ 𝓑 c r p₁) p₂ p₂ μ μ
      (C2_0_6 A p₁ p₂) := by
  sorry

theorem hasWeakType_maximalFunction_equal_exponents
    [BorelSpace X] {p : ℝ≥0} (h𝓑 : 𝓑.Countable) (hp : 0 < p) :
    HasWeakType (maximalFunction (E := E) μ 𝓑 c r p) p p μ μ (A ^ (2 / p : ℝ)) := by
  sorry

def C_weakType_maximalFunction (A p₁ p₂ : ℝ≥0) :=
  if p₁ = p₂ then (ofNNReal A) ^ (2 / p₁ : ℝ) else C2_0_6 A p₁ p₂

@[aesop (rule_sets := [finiteness]) safe apply]
lemma C_weakType_maximalFunction_lt_top {A p₁ p₂ : ℝ≥0} :
    C_weakType_maximalFunction A p₁ p₂ < ∞ := by
  sorry

/-- `hasStrongType_maximalFunction` minus the assumption `hR`, but where `p₁ = p₂` is possible and
we only conclude a weak-type estimate. -/
theorem hasWeakType_maximalFunction
    [BorelSpace X] [IsFiniteMeasureOnCompacts μ] [ProperSpace X] [μ.IsOpenPosMeasure]
    {p₁ p₂ : ℝ≥0} (h𝓑 : 𝓑.Countable) (hp₁ : 0 < p₁) (hp₁₂ : p₁ ≤ p₂) :
    HasWeakType (fun (u : X → E) (x : X) ↦ maximalFunction μ 𝓑 c r p₁ u x)
      p₂ p₂ μ μ (C_weakType_maximalFunction A p₁ p₂) := by
  sorry

section GMF

variable [ProperSpace X]

variable (μ) in
/-- The transformation `M` characterized in Proposition 2.0.6.
`p` is `1` in the blueprint, and `globalMaximalFunction μ p u = (M (u ^ p)) ^ p⁻¹ ` -/
@[nolint unusedArguments]
def globalMaximalFunction [μ.IsDoubling A] (p : ℝ) (u : X → E) (x : X) : ℝ≥0∞ :=
  A ^ 2 * maximalFunction μ ((covering_separable_space X).choose ×ˢ (univ : Set ℤ))
    (·.1) (fun x ↦ 2 ^ (x.2)) p u x

protected theorem MeasureTheory.AEStronglyMeasurable.globalMaximalFunction
    [BorelSpace X] {p : ℝ} {u : X → E} : AEStronglyMeasurable (globalMaximalFunction μ p u) μ := by
  sorry

/-- Equation (2.0.45) -/
theorem laverage_le_globalMaximalFunction [IsFiniteMeasureOnCompacts μ] [μ.IsOpenPosMeasure]
    {u : X → E} {z x : X} {r : ℝ} (h : dist x z < r) :
    ⨍⁻ y in ball z r, ‖u y‖ₑ ∂μ ≤ globalMaximalFunction μ 1 u x := by
  sorry

theorem lintegral_ball_le_volume_globalMaximalFunction [IsFiniteMeasureOnCompacts μ] [μ.IsOpenPosMeasure]
    {u : X → E} {z x : X} {r : ℝ} (h : dist x z < r) :
    ∫⁻ y in (ball z r), ‖u y‖ₑ ∂μ  ≤ μ (ball z r) * globalMaximalFunction μ 1 u x := by
  sorry

/-- The constant factor in the statement that `M` has strong type. -/
def C2_0_6' (A p₁ p₂ : ℝ≥0) : ℝ≥0 := A ^ 2 * C2_0_6 A p₁ p₂

lemma C2_0_6'_defaultA_one_two_eq {a : ℕ} : C2_0_6' (defaultA a) 1 2 = 2 ^ (3 * a + 3 / (2 : ℝ)) := by
  sorry

lemma C2_0_6'_defaultA_one_le {a : ℕ} {q : ℝ≥0} (hq : 1 < q) :
    C2_0_6' (defaultA a) 1 q ≤ 2 ^ (4 * a + 1) * (q / (q - 1)) := by
  sorry

/-- Equation (2.0.46). Easy from `hasStrongType_maximalFunction` -/
theorem hasStrongType_globalMaximalFunction [BorelSpace X] [IsFiniteMeasureOnCompacts μ]
    [μ.IsOpenPosMeasure] {p₁ p₂ : ℝ≥0} (hp₁ : 0 < p₁) (hp₁₂ : p₁ < p₂) :
    HasStrongType (globalMaximalFunction μ p₁ (E := E))
      p₂ p₂ μ μ (C2_0_6' A p₁ p₂) := by
  sorry

def C_weakType_globalMaximalFunction (A p₁ p₂ : ℝ≥0) :=
  A ^ 2 * C_weakType_maximalFunction A p₁ p₂

lemma C_weakType_globalMaximalFunction_lt_top {A p₁ p₂ : ℝ≥0} :
    C_weakType_globalMaximalFunction A p₁ p₂ < ∞ := by
  sorry

-- the constant here `A ^ 4` can be improved
theorem hasWeakType_globalMaximalFunction [BorelSpace X] [IsFiniteMeasureOnCompacts μ]
    [μ.IsOpenPosMeasure] {p₁ p₂ : ℝ≥0} (hp₁ : 0 < p₁) (hp₁₂ : p₁ ≤ p₂) :
    HasWeakType (globalMaximalFunction μ p₁ (E := E))
      p₂ p₂ μ μ (C_weakType_globalMaximalFunction A p₁ p₂) := by
  sorry

/-- Use `lowerSemiContinuous_MB` -/
lemma lowerSemiContinuous_globalMaximalFunction :
    LowerSemicontinuous (globalMaximalFunction μ 1 f) := by
  sorry

theorem globalMaximalFunction_ae_lt_top [BorelSpace X] [IsFiniteMeasureOnCompacts μ]
    [μ.IsOpenPosMeasure] {p₁ p₂ : ℝ≥0} (hp₁ : 0 < p₁) (hp₁₂ : p₁ < p₂)
    {u : X → E} (hu : MemLp u p₂ μ) :
    ∀ᵐ x ∂μ, globalMaximalFunction μ p₁ u x < ∞ := by
  sorry

theorem globalMaximalFunction_lt_top {p : ℝ≥0} (hp₁ : 0 < p)
    {u : X → E} (hu : MemLp u ⊤ μ) {x : X} :
    globalMaximalFunction μ p u x < ∞ := by
  sorry

end GMF

section UnusedContinuity

open scoped Topology in
lemma continuous_integral_ball [OpensMeasurableSpace X]
    (g : X → ℝ≥0∞) (hg : ∀ x : X, ∀ r > (0 : ℝ), ∫⁻ (y : X) in ball x r, g y ∂μ < ⊤)
    (hg2 : AEMeasurable g μ) (hμ : ∀ z : X, ∀ r > (0 : ℝ), μ (sphere z r) = 0 ):
    ContinuousOn (fun x : X × ℝ ↦ ∫⁻ y in ball x.1 x.2, g y ∂μ) (univ ×ˢ Ioi 0) := by
  sorry

-- unused in Carleson
-- move to separate file (not sure where)
lemma continuous_average_ball [μ.IsOpenPosMeasure] [IsFiniteMeasureOnCompacts μ] [OpensMeasurableSpace X]
    [ProperSpace X] (hf : LocallyIntegrable f μ)
    (hμ : ∀ z : X, ∀ r > (0 : ℝ), μ (sphere z r) = 0) :
    ContinuousOn (fun x : X × ℝ ↦ ⨍⁻ y in ball x.1 x.2, ‖f y‖ₑ ∂μ) (univ ×ˢ Ioi 0) := by
  sorry

open scoped Topology in
-- unused in Carleson
-- move to separate file (not sure where)
lemma lowerSemiContinuousOn_integral_ball [OpensMeasurableSpace X] (hf2 : AEStronglyMeasurable f μ) :
    LowerSemicontinuousOn (fun x : X × ℝ ↦ ∫⁻ y in ball x.1 x.2, ‖f y‖ₑ ∂μ) (univ ×ˢ Ioi 0) := by
  sorry

end UnusedContinuity
