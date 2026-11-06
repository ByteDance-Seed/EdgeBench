module

public import Carleson.Psi
public import Carleson.TileStructure
public import Carleson.ToMathlib.BoundedCompactSupport

@[expose] public section

open Set MeasureTheory Metric Function Complex Bornology
open scoped ComplexConjugate
noncomputable section

open scoped ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}

/-! ## Carleson operators -/

section Carleson

variable [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G]

lemma bcs_of_measurable_of_le_indicator_f {f : X → ℂ}
    (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x) : BoundedCompactSupport f := by
  sorry

lemma bcs_of_measurable_of_le_indicator_g {g : X → ℂ}
    (hg : Measurable g) (h2g : ∀ x, ‖g x‖ ≤ G.indicator 1 x) : BoundedCompactSupport g := by
  sorry

variable [TileStructure Q D κ S o] {p p' : 𝔓 X}

/-- The operator `T_𝔭` defined in Proposition 2.0.2. -/
def carlesonOn (p : 𝔓 X) (f : X → ℂ) : X → ℂ :=
  indicator (E p)
    fun x ↦ ∫ y, exp (I * (Q x y - Q x x)) * Ks (𝔰 p) x y * f y

/- Deprecated for `AEStronglyMeasurable.carlesonOn`
Used through `measurable_carlesonSum` in `Antichain.AntichainOperator` and `ForestOperator.Forests`
with nontrivial rework in order to move from `Measurable` to `AEStronglyMeasurable`. -/
lemma measurable_carlesonOn {p : 𝔓 X} {f : X → ℂ} (measf : Measurable f) :
    Measurable (carlesonOn p f) := by
  sorry

open Classical in
/-- The operator `T_ℭ f` defined at the bottom of Section 7.4.
We will use this in other places of the formalization as well. -/
def carlesonSum (ℭ : Set (𝔓 X)) (f : X → ℂ) (x : X) : ℂ :=
  ∑ p with p ∈ ℭ, carlesonOn p f x

@[fun_prop]
lemma measurable_carlesonSum {ℭ : Set (𝔓 X)} {f : X → ℂ} (measf : Measurable f) :
    Measurable (carlesonSum ℭ f) := by
  sorry

lemma _root_.MeasureTheory.AEStronglyMeasurable.carlesonOn {p : 𝔓 X} {f : X → ℂ}
    (hf : AEStronglyMeasurable f) : AEStronglyMeasurable (carlesonOn p f) := by
  sorry

lemma _root_.MeasureTheory.AEStronglyMeasurable.carlesonSum {ℭ : Set (𝔓 X)}
    {f : X → ℂ} (hf : AEStronglyMeasurable f) : AEStronglyMeasurable (carlesonSum ℭ f) := by
  sorry

lemma carlesonOn_def' (p : 𝔓 X) (f : X → ℂ) : carlesonOn p f =
    indicator (E p) fun x ↦ ∫ y, Ks (𝔰 p) x y * f y * exp (I * (Q x y - Q x x)) := by
  sorry

lemma support_carlesonOn_subset_E {f : X → ℂ} : support (carlesonOn p f) ⊆ E p := by
  sorry

lemma support_carlesonSum_subset {ℭ : Set (𝔓 X)} {f : X → ℂ} :
    support (carlesonSum ℭ f) ⊆ (⋃ p ∈ ℭ, 𝓘 p) := by
  sorry

namespace MeasureTheory

variable (p) in
theorem BoundedCompactSupport.bddAbove_norm_carlesonOn
    {f : X → ℂ} (hf : BoundedCompactSupport f) : BddAbove (range (‖carlesonOn p f ·‖)) := by
  sorry

@[fun_prop]
theorem BoundedCompactSupport.carlesonOn {f : X → ℂ}
    (hf : BoundedCompactSupport f) : BoundedCompactSupport (carlesonOn p f) := by
  sorry

theorem BoundedCompactSupport.bddAbove_norm_carlesonSum
    {ℭ : Set (𝔓 X)} {f : X → ℂ} (hf : BoundedCompactSupport f) :
    BddAbove (range (‖carlesonSum ℭ f ·‖)) := by
  sorry

@[fun_prop]
theorem BoundedCompactSupport.carlesonSum {ℭ : Set (𝔓 X)} {f : X → ℂ}
    (hf : BoundedCompactSupport f) : BoundedCompactSupport (carlesonSum ℭ f) := by
  sorry

end MeasureTheory

lemma carlesonSum_inter_add_inter_compl {f : X → ℂ} {x : X} (A B : Set (𝔓 X)) :
    carlesonSum (A ∩ B) f x + carlesonSum (A ∩ Bᶜ) f x = carlesonSum A f x := by
  sorry

lemma sum_carlesonSum_of_pairwiseDisjoint {ι : Type*} {f : X → ℂ} {x : X} {A : ι → Set (𝔓 X)}
    {s : Finset ι} (hs : (s : Set ι).PairwiseDisjoint A) :
    ∑ i ∈ s, carlesonSum (A i) f x = carlesonSum (⋃ i ∈ s, A i) f x := by
  sorry

end Carleson

/-! ## Adjoint operators -/

section Adjoint

variable [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o] {p p' : 𝔓 X}

/-- The definition of `Tₚ*g(x)`, defined above Lemma 7.4.1 -/
def adjointCarleson (p : 𝔓 X) (f : X → ℂ) (x : X) : ℂ :=
  ∫ y in E p, conj (Ks (𝔰 p) y x) * exp (.I * (Q y y - Q y x)) * f y

open scoped Classical in
/-- The definition of `T_ℭ*g(x)`, defined at the bottom of Section 7.4 -/
def adjointCarlesonSum (ℭ : Set (𝔓 X)) (f : X → ℂ) (x : X) : ℂ :=
  ∑ p with p ∈ ℭ, adjointCarleson p f x

/-- A helper lemma used in Lemma 7.5.10. -/
lemma adjointCarlesonSum_inter {A B : Set (𝔓 X)} {f : X → ℂ} {x : X} :
    adjointCarlesonSum (A ∩ B) f x = adjointCarlesonSum A f x - adjointCarlesonSum (A \ B) f x := by
  sorry

variable {f g : X → ℂ}

lemma adjoint_eq_adjoint_indicator (h : E p ⊆ 𝓘 p') :
    adjointCarleson p f = adjointCarleson p ((𝓘 p' : Set X).indicator f) := by
  sorry

namespace MeasureTheory

attribute [fun_prop] continuous_exp -- not needed here, but clearly missing in mathlib

@[fun_prop]
lemma StronglyMeasurable.adjointCarleson (hf : StronglyMeasurable f) :
    StronglyMeasurable (adjointCarleson p f) := by
  sorry

@[fun_prop]
lemma AEStronglyMeasurable.adjointCarleson (hf : AEStronglyMeasurable f) :
    AEStronglyMeasurable (adjointCarleson p f) := by
  sorry

lemma StronglyMeasurable.adjointCarlesonSum {ℭ : Set (𝔓 X)} (hf : StronglyMeasurable f) :
    StronglyMeasurable (adjointCarlesonSum ℭ f) := by
  sorry

lemma AEStronglyMeasurable.adjointCarlesonSum {ℭ : Set (𝔓 X)} (hf : AEStronglyMeasurable f) :
    AEStronglyMeasurable (adjointCarlesonSum ℭ f) := by
  sorry

variable (p) in
theorem BoundedCompactSupport.bddAbove_norm_adjointCarleson (hf : BoundedCompactSupport f) :
    BddAbove (range (‖adjointCarleson p f ·‖)) := by
  sorry

@[fun_prop]
theorem BoundedCompactSupport.adjointCarleson (hf : BoundedCompactSupport f) :
    BoundedCompactSupport (adjointCarleson p f) := by
  sorry

variable (p) in
theorem BoundedCompactSupport.bddAbove_norm_adjointCarlesonSum
    {ℭ : Set (𝔓 X)} (hf : BoundedCompactSupport f) :
    BddAbove (range (‖adjointCarlesonSum ℭ f ·‖)) := by
  sorry

@[fun_prop]
theorem BoundedCompactSupport.adjointCarlesonSum {ℭ : Set (𝔓 X)}
    (hf : BoundedCompactSupport f) : BoundedCompactSupport (adjointCarlesonSum ℭ f) := by
  sorry

end MeasureTheory

/-- `MKD` is short for "modulated kernel times dilated bump". -/
private abbrev MKD (s : ℤ) x y := exp (I * (Q x y - Q x x)) * Ks s x y (K := K)

omit [TileStructure Q D κ S o] in
private lemma norm_MKD_le_norm_Ks {s : ℤ} {x y : X} : ‖MKD s x y‖ ≤ ‖Ks s x y‖ := by
  sorry

/-- `adjointCarleson` is the adjoint of `carlesonOn`. -/
lemma adjointCarleson_adjoint
    (hf : BoundedCompactSupport f) (hg : BoundedCompactSupport g) (p : 𝔓 X) :
    ∫ x, conj (g x) * carlesonOn p f x = ∫ y, conj (adjointCarleson p g y) * f y := by
  sorry

-- Bug: why is `integrable_fun_mul` needed, despite `integrable_mul` existing?
-- the fun_prop documentation implies it's superfluous. TODO ask on zulip!

/-- `adjointCarlesonSum` is the adjoint of `carlesonSum`. -/
lemma adjointCarlesonSum_adjoint
    (hf : BoundedCompactSupport f) (hg : BoundedCompactSupport g) (ℭ : Set (𝔓 X)) :
    ∫ x, conj (g x) * carlesonSum ℭ f x = ∫ x, conj (adjointCarlesonSum ℭ g x) * f x := by
  sorry

lemma integrable_adjointCarlesonSum (s : Set (𝔓 X)) {f : X → ℂ} (hf : BoundedCompactSupport f) :
    Integrable (adjointCarlesonSum s f ·) := by
  sorry

end Adjoint
