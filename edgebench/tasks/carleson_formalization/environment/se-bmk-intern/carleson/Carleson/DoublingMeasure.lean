module

public import Carleson.Defs
public import Carleson.LipschitzNorm
public import Carleson.ToMathlib.Data.ENNReal

@[expose] public section

open MeasureTheory Measure Metric Complex Set Bornology Function
open ENNReal hiding one_lt_two
open scoped NNReal

noncomputable section

/-! # Basic definitions and lemmas

This file contains definitions from Section 2 of the blueprint and used throughout the proof
of metric Carleson, as well as results about structures defined in sections 1 and 2
(`DoublingMeasure` `KernelProofData`, `IsCancellative`, `FunctionDistances`, ...).
The constants `D`, `κ`, `Z` from the blueprint are introduce here, and useful inequalities are
provided for them (as well as for the constants `a` and `tau`).

-/

lemma seven_le_c : 7 ≤ 𝕔 := by
  sorry

lemma c_le_100 : 𝕔 ≤ 100 := by
  sorry

/- To check that the value of `c` is irrelevant, you can take `𝕔 = 7` above, or you can comment
the previous lines and uncomment the next ones.

lemma exists_c : ∃ (c : ℕ), 7 ≤ c ∧ c ≤ 100 := ⟨7, le_rfl, by norm_num⟩
def 𝕔 : ℕ := exists_c.choose
lemma seven_le_c : 7 ≤ 𝕔 := exists_c.choose_spec.1
lemma c_le_100 : 𝕔 ≤ 100 := exists_c.choose_spec.2
-/

/-- The constant `D` from (2.0.1). -/
@[simp] def defaultD (a : ℕ) : ℕ := 2 ^ (𝕔 * a ^ 2)

/-- `D` as an element of `ℝ≥0`. -/
def nnD (a : ℕ) : ℝ≥0 := ⟨defaultD a, by simp⟩

/-- The constant `κ` from (2.0.2). -/
@[simp] def defaultκ (a : ℕ) : ℝ := 2 ^ (-10 * (a : ℝ))

/-- The constant `Z` from (2.0.3). -/
@[simp] def defaultZ (a : ℕ) : ℕ := 2 ^ (12 * a)

section ConstantBounds

variable (a : ℕ)

lemma defaultD_pos : 0 < defaultD a := by
  sorry

lemma realD_pos : 0 < (defaultD a : ℝ) := by
  sorry

lemma realD_nonneg : 0 ≤ (defaultD a : ℝ) := by
  sorry

lemma one_le_realD : 1 ≤ (defaultD a : ℝ) := by
  sorry

lemma defaultD_pow_pos (z : ℤ) : 0 < (defaultD a : ℝ) ^ z := by
  sorry

lemma mul_defaultD_pow_pos {r : ℝ} (hr : 0 < r) (z : ℤ) : 0 < r * (defaultD a : ℝ) ^ z := by
  sorry

section KernelProofData

variable (X) [PseudoMetricSpace X] {a} {K : X → X → ℂ} [hK : KernelProofData a K]

include hK

-- used in 7.5.6 (`limited_scale_impact`)
lemma hundred_lt_D : 100 < defaultD a := by
  sorry

-- used in 7.5.6 (`limited_scale_impact`)
lemma hundred_lt_realD : (100 : ℝ) < defaultD a := by
  sorry

-- used in 4.1.7 (`small_boundary`)
lemma twentyfive_le_realD : (25 : ℝ) ≤ defaultD a := by
  sorry

-- used in 4.1.3 (`I3_prop_3_1`)
lemma eight_le_realD : (8 : ℝ) ≤ defaultD a := by
  sorry

-- used in 4.1.6 (`transitive_boundary`)
lemma five_le_realD : (5 : ℝ) ≤ defaultD a := by
  sorry

-- used in various places in `Carleson.TileExistence`
lemma four_le_realD : (4 : ℝ) ≤ defaultD a := by
  sorry

lemma one_lt_realD : 1 < (defaultD a : ℝ) := by
  sorry

lemma a_pos : 0 < a := by
  sorry

lemma cast_a_pos : 0 < (a : ℝ) := by
  sorry

lemma τ_pos : 0 < defaultτ a := by
  sorry

lemma τ_nonneg : 0 ≤ defaultτ a := by
  sorry

lemma τ_le_one : defaultτ a ≤ 1 := by
  sorry

/-- `τ` as an element of `ℝ≥0`. -/
def nnτ : ℝ≥0 := ⟨defaultτ a, τ_nonneg X⟩
lemma nnτ_pos : 0 < nnτ X := by
  sorry
@[simp]
lemma nnτ_def : nnτ X = (defaultτ a).toNNReal := by
  sorry

end KernelProofData

namespace ShortVariables
-- open this section to get shorter 1-letter names for a bunch of variables

set_option hygiene false
scoped notation "D" => defaultD a
scoped notation "κ" => defaultκ a
scoped notation "Z" => defaultZ a
scoped notation "τ" => defaultτ a
scoped notation "o" => cancelPt X
scoped notation "S" => defaultS X
scoped notation "nnτ" => nnτ X
scoped notation "nnD" => nnD a

end ShortVariables

open scoped ShortVariables

variable {a : ℕ}

lemma κ_nonneg : 0 ≤ κ := by
  sorry

lemma κ_le_one : κ ≤ 1 := by
  sorry

end ConstantBounds

section DoublingMeasure

universe u

namespace MeasureTheory

/- # Doubling metric measure spaces -/

variable {X : Type*} {A : ℝ≥0} [PseudoMetricSpace X] [DoublingMeasure X A]

instance : ProperSpace X := by
  constructor
  intro x r
  refine TotallyBounded.isCompact_of_isClosed ?_ isClosed_closedBall
  obtain ⟨r', hr'⟩ := exists_gt r
  apply TotallyBounded.subset (closedBall_subset_ball hr')
  refine Metric.totallyBounded_iff.mpr fun ε hε ↦ ?_
  obtain ⟨s, _, h2s⟩ := IsDoubling.allBallsCoverBalls volume |>.ballsCoverBalls (by norm_num) hε x
  use s, s.finite_toSet, by simpa using h2s

instance : IsOpenPosMeasure (volume : Measure X) := isOpenPosMeasure_of_isDoubling _

/-- Monotonicity of doubling measure metric spaces in `A`. -/
@[reducible]
def DoublingMeasure.mono {A'} (h : A ≤ A') : DoublingMeasure X A' where
  toIsDoubling := IsDoubling.mono h

open Module

instance InnerProductSpace.DoublingMeasure
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [MeasurableSpace E] [BorelSpace E] [FiniteDimensional ℝ E] :
    DoublingMeasure E (2 ^ finrank ℝ E) where

end MeasureTheory

variable {𝕜 X : Type*} {A : ℕ} [_root_.RCLike 𝕜] [PseudoMetricSpace X]

lemma fact_isCompact_ball (x : X) (r : ℝ) : Fact (IsBounded (ball x r)) := by
  sorry
attribute [local instance] fact_isCompact_ball

section FunctionDistances

variable [FunctionDistances 𝕜 X]

instance : ContinuousMapClass (Θ X) X 𝕜 := ⟨fun f ↦ (f : C(X, 𝕜)).2⟩

def toWithFunctionDistance {x : X} {r : ℝ} [FunctionDistances 𝕜 X] :
    Θ X ≃ WithFunctionDistance x r := .refl _

end FunctionDistances

/-- The `ℝ≥0`-valued distance function on `WithFunctionDistance x r`. Preferably use `edist` -/
notation3 "nndist_{" x ", " r "}" => @nndist (WithFunctionDistance x r) _
/-- The ball with center `x` and radius `r` in `WithFunctionDistance x r`. -/
notation3 "ball_{" x ", " r "}" => @ball (WithFunctionDistance x r) _ in
instance nonempty_Space [CompatibleFunctions 𝕜 X A] : Nonempty X := by
  obtain ⟨x,_⟩ := ‹CompatibleFunctions 𝕜 X A›.eq_zero
  use x

instance inhabited_Space [CompatibleFunctions 𝕜 X A] : Inhabited X :=
  ⟨nonempty_Space.some⟩

lemma le_localOscillation [CompatibleFunctions 𝕜 X A] (x : X) (r : ℝ) (f g : Θ X) {y z : X}
    (hy : y ∈ ball x r) (hz : z ∈ ball x r) : ‖coeΘ f y - coeΘ g y - coeΘ f z + coeΘ g z‖ ≤
    ENNReal.toReal (localOscillation (ball x r) (coeΘ f) (coeΘ g)) := by
  sorry

lemma oscillation_le_cdist [CompatibleFunctions 𝕜 X A] (x : X) (r : ℝ) (f g : Θ X) {y z : X}
    (hy : y ∈ ball x r) (hz : z ∈ ball x r) :
    ‖coeΘ f y - coeΘ g y - coeΘ f z + coeΘ g z‖ ≤ dist_{x, r} f g := by
  sorry

export CompatibleFunctions (localOscillation_le_cdist cdist_mono cdist_le le_cdist)

lemma dist_congr [FunctionDistances 𝕜 X] {x₁ x₂ : X} {r₁ r₂ : ℝ} {f g : Θ X}
    (e₁ : x₁ = x₂) (e₂ : r₁ = r₂) : dist_{x₁, r₁} f g = dist_{x₂, r₂} f g := by
  sorry

variable (X) in
/-- The point `o` in the blueprint -/
def cancelPt [CompatibleFunctions 𝕜 X A] : X :=
  CompatibleFunctions.eq_zero (𝕜 := 𝕜) |>.choose

lemma cancelPt_eq_zero [CompatibleFunctions 𝕜 X A] {f : Θ X} : f (cancelPt X) = 0 := by
  sorry

variable [hXA : DoublingMeasure X A]

lemma enorm_integral_exp_le [CompatibleFunctions ℝ X A] {τ : ℝ} [IsCancellative X τ]
    {x : X} {r : ℝ} {φ : X → ℂ} (h2 : support φ ⊆ ball x r) {f g : Θ X} :
    ‖∫ x, exp (I * (f x - g x)) * φ x‖ₑ ≤
    (A : ℝ≥0∞) * volume (ball x r) * iLipENorm φ x r * (1 + edist_{x, r} f g) ^ (- τ) := by
  sorry

/-- Constructor of `IsCancellative` in terms of real norms instead of extended reals. -/
lemma isCancellative_of_norm_integral_exp_le (τ : ℝ) [CompatibleFunctions ℝ X A]
    (h : ∀ {x : X} {r : ℝ} {φ : X → ℂ} (_hr : 0 < r) (_h1 : iLipENorm φ x r ≠ ∞)
    (_h2 : support φ ⊆ ball x r) {f g : Θ X},
      ‖∫ x in ball x r, exp (I * (f x - g x)) * φ x‖ ≤
      A * volume.real (ball x r) * iLipNNNorm φ x r * (1 + dist_{x, r} f g) ^ (-τ)) :
    IsCancellative X τ := by
  sorry

/-- The "volume function" `V`. We will need to assume
`IsFiniteMeasureOnCompacts` and `ProperSpace` to actually know that this volume is finite. -/
def vol {X : Type*} [PseudoMetricSpace X] [MeasureSpace X] (x y : X) : ℝ≥0∞ :=
  volume (ball x (dist x y))

@[fun_prop]
lemma measurable_vol {X : Type*} [PseudoMetricSpace X] [SecondCountableTopology X]
    [MeasureSpace X] [OpensMeasurableSpace X] [SFinite (volume : Measure X)] :
    Measurable (uncurry vol : X × X → ℝ≥0∞) := by
  sorry

@[fun_prop]
lemma measurable_vol₁ {X : Type*} [PseudoMetricSpace X] [SecondCountableTopology X]
    [MeasureSpace X] [OpensMeasurableSpace X] [SFinite (volume : Measure X)] {y : X} :
    Measurable (vol · y) := by
  sorry

lemma Real.vol_def {X : Type*} [PseudoMetricSpace X] [MeasureSpace X] {x y : X} :
  Real.vol x y = (vol x y).toReal := by
  sorry

lemma ofReal_vol {X : Type*} [PseudoMetricSpace X] [MeasureSpace X] [ProperSpace X]
  [IsFiniteMeasureOnCompacts (volume : Measure X)] {x y : X} :
    ENNReal.ofReal (Real.vol x y) = vol x y := by
  sorry

lemma le_upperRadius [FunctionDistances ℝ X] {Q : X → Θ X} {θ : Θ X} {x : X} {r : ℝ}
    (hr : dist_{x, r} θ (Q x) < 1) : ENNReal.ofReal r ≤ upperRadius Q θ x := by
  sorry

set_option backward.isDefEq.respectTransparency false in
private lemma carlesonOperatorIntegrand_const_smul [FunctionDistances ℝ X] (K : X → X → ℂ)
    (θ : Θ X) (R₁ R₂ : ℝ) (f : X → ℂ) (z : ℂ) :
    carlesonOperatorIntegrand (z • K) θ R₁ R₂ f = z • carlesonOperatorIntegrand K θ R₁ R₂ f := by
  sorry

private lemma linearizedCarlesonOperator_const_smul [FunctionDistances ℝ X] (Q : X → Θ X)
    (K : X → X → ℂ) (f : X → ℂ) (z : ℂ) :
    linearizedCarlesonOperator Q (z • K) f = ‖z‖ₑ • linearizedCarlesonOperator Q K f := by
  sorry

lemma carlesonOperator_const_smul [FunctionDistances ℝ X] (K : X → X → ℂ) (f : X → ℂ) (z : ℂ) :
    carlesonOperator (z • K) f = ‖z‖ₑ • carlesonOperator K f := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma nontangentialOperator_const_smul (z : ℂ) {K : X → X → ℂ} :
    nontangentialOperator (z • K) = ‖z‖ₑ • nontangentialOperator K := by
  sorry

set_option backward.isDefEq.respectTransparency false in
private lemma carlesonOperatorIntegrand_const_smul' [FunctionDistances ℝ X] (K : X → X → ℂ)
    (θ : Θ X) (R₁ R₂ : ℝ) (f : X → ℂ) (z : ℂ) :
    carlesonOperatorIntegrand K θ R₁ R₂ (z • f) = z • carlesonOperatorIntegrand K θ R₁ R₂ f := by
  sorry

private lemma linearizedCarlesonOperator_const_smul' [FunctionDistances ℝ X] (Q : X → Θ X)
    (K : X → X → ℂ) (f : X → ℂ) (z : ℂ) :
    linearizedCarlesonOperator Q K (z • f) = ‖z‖ₑ • linearizedCarlesonOperator Q K f := by
  sorry

lemma carlesonOperator_const_smul' [FunctionDistances ℝ X] (K : X → X → ℂ) (f : X → ℂ) (z : ℂ) :
    carlesonOperator K (z • f) = ‖z‖ₑ • carlesonOperator K f := by
  sorry

end DoublingMeasure

section Kernel

variable {X : Type*} {a : ℕ} {K : X → X → ℂ} [PseudoMetricSpace X] [MeasureSpace X]

open Function

lemma C_K_pos {a : ℝ} : 0 < C_K a := by
  sorry
lemma C_K_pos_real {a : ℝ} : 0 < (C_K a : ℝ) := by
  sorry

export IsOneSidedKernel (measurable_K norm_K_le_vol_inv norm_K_sub_le)

lemma isOneSidedKernel_const_smul {a : ℕ} {K : X → X → ℂ} [IsOneSidedKernel a K] {r : ℝ}
    (hr : |r| ≤ 1) :
    IsOneSidedKernel a (r • K) := by
  sorry

lemma MeasureTheory.stronglyMeasurable_K [IsOneSidedKernel a K] :
    StronglyMeasurable (uncurry K) := by
  sorry

lemma MeasureTheory.aestronglyMeasurable_K [IsOneSidedKernel a K] :
    AEStronglyMeasurable (uncurry K) := by
  sorry

lemma measurable_K_left [IsOneSidedKernel a K] (y : X) : Measurable (K · y) := by
  sorry

lemma measurable_K_right [IsOneSidedKernel a K] (x : X) : Measurable (K x) := by
  sorry

lemma enorm_K_le_vol_inv [ProperSpace X] [IsFiniteMeasureOnCompacts (volume : Measure X)]
    [IsOneSidedKernel a K] (x y : X) : ‖K x y‖ₑ ≤ (C_K a : ℝ≥0∞) / vol x y := by
  sorry

lemma enorm_K_le_ball_complement [ProperSpace X] [IsFiniteMeasureOnCompacts (volume : Measure X)]
    [IsOneSidedKernel a K] {r : ℝ} {x : X} {y : X} (hy : y ∈ (ball x r)ᶜ) :
    ‖K x y‖ₑ ≤ C_K a / volume (ball x r) := by
  sorry

lemma enorm_K_le_ball_complement' [ProperSpace X] [IsFiniteMeasureOnCompacts (volume : Measure X)]
    [IsOpenPosMeasure (volume : Measure X)] [IsOneSidedKernel a K] {r : ℝ} (hr : 0 < r)
    {x : X} {y : X} (hy : y ∈ (ball x r)ᶜ) :
    ‖K x y‖ₑ ≤ (C_K a / volume (ball x r)).toNNReal := by
  sorry

lemma enorm_K_sub_le [ProperSpace X] [IsFiniteMeasureOnCompacts (volume : Measure X)]
    [IsOneSidedKernel a K] {x y y' : X} (h : 2 * dist y y' ≤ dist x y) :
    ‖K x y - K x y'‖ₑ ≤ (edist y y' / edist x y) ^ (a : ℝ)⁻¹ * (C_K a / vol x y) := by
  sorry

lemma integrableOn_K_mul [IsOpenPosMeasure (volume : Measure X)]
    [IsFiniteMeasureOnCompacts (volume : Measure X)] [ProperSpace X] [IsOneSidedKernel a K]
    {f : X → ℂ} {s : Set X} (hf : IntegrableOn f s) (x : X) {r : ℝ} (hr : 0 < r)
    (hs : s ⊆ (ball x r)ᶜ) : IntegrableOn (K x * f) s := by
  sorry

lemma integrableOn_K_Icc [IsOpenPosMeasure (volume : Measure X)]
    [IsFiniteMeasureOnCompacts (volume : Measure X)] [ProperSpace X]
    [IsOneSidedKernel a K] {x : X} {r R : ℝ} (hr : r > 0) :
    IntegrableOn (K x) {y | dist x y ∈ Icc r R} volume := by
  sorry

end Kernel

section PseudoMetricSpace

variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [PseudoMetricSpace X]

section Iterate

variable [CompatibleFunctions ℝ X (defaultA a)]

lemma le_cdist_iterate {x : X} {r : ℝ} (hr : 0 ≤ r) (f g : Θ X) (k : ℕ) :
    2 ^ k * dist_{x, r} f g ≤ dist_{x, (defaultA a) ^ k * r} f g := by
  sorry

lemma cdist_le_iterate {x : X} {r : ℝ} (hr : 0 < r) (f g : Θ X) (k : ℕ) :
    dist_{x, 2 ^ k * r} f g ≤ (defaultA a) ^ k * dist_{x, r} f g := by
  sorry

lemma cdist_le_mul_cdist {x x' : X} {r r' : ℝ} (hr : 0 < r) (hr' : 0 < r') (f g : Θ X) :
    dist_{x', r'} f g ≤ As (defaultA a) ((r' + dist x' x) / r) * dist_{x, r} f g := by
  sorry

lemma ballsCoverBalls_iterate_nat {x : X} {d r : ℝ} {n : ℕ} :
    BallsCoverBalls (WithFunctionDistance x d) (2 ^ n * r) r (defaultA a ^ n) := by
  sorry

lemma ballsCoverBalls_iterate {x : X} {d R r : ℝ} (hr : 0 < r) :
    BallsCoverBalls (WithFunctionDistance x d) R r (defaultA a ^ ⌈Real.logb 2 (R / r)⌉₊) := by
  sorry

end Iterate

section MeasQ

variable [KernelProofData a K] {Q : SimpleFunc X (Θ X)}

@[fun_prop]
lemma measurable_Q₂ : Measurable fun p : X × X ↦ Q p.1 p.2 := by
  sorry

lemma stronglyMeasurable_Q₂ : StronglyMeasurable fun p : X × X ↦ Q p.1 p.2 := by
  sorry

@[fun_prop]
lemma aestronglyMeasurable_Q₂ : AEStronglyMeasurable fun p : X × X ↦ Q p.1 p.2 := by
  sorry

@[fun_prop]
lemma measurable_Q₁ (x : X) : Measurable (Q x) := by
  sorry

end MeasQ

end PseudoMetricSpace
