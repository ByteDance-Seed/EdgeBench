module

public import Carleson.ForestOperator.LargeSeparation
public import Carleson.ForestOperator.RemainingTiles
public import Carleson.ToMathlib.MeasureTheory.Function.L1Integrable
public import Carleson.ToMathlib.MeasureTheory.Integral.Bochner.ContinuousLinearMap
public import Mathlib.Data.Set.Pairwise.Chain

@[expose] public section

open ShortVariables TileStructure
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]
  {n j j' : ℕ} {t : Forest X n} {u u₁ u₂ p : 𝔓 X} {x x' : X} {𝔖 : Set (𝔓 X)}
  {f f₁ f₂ g g₁ g₂ : X → ℂ} {I J J' L : Grid X}
variable {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E']

noncomputable section

open Set MeasureTheory Metric Function Complex Bornology TileStructure Filter
open scoped NNReal ENNReal ComplexConjugate

namespace TileStructure.Forest

/-! ## Lemma 7.4.4 -/

lemma estimate_C7_4_5 {a : ℕ} (n : ℕ) (ha : 4 ≤ a) :
    C7_4_5 a n ≤ 2 ^ ((4 * 𝕔 + 11 + 4 * (𝕔 / 4)) * a ^ 3) * 2 ^ (-(4 * n : ℝ)) := by
  sorry

lemma estimate_C7_4_6 {a : ℕ} (n : ℕ) (ha : 4 ≤ a) :
    C7_4_6 a n ≤ 2 ^ ((2 * 𝕔 + 9 + 𝕔 / 4) * a ^ 3) * 2 ^ (-(4 * n : ℝ)) := by
  sorry

/-- The constant used in `correlation_separated_trees`.
Has value `2 ^ (512 * a ^ 3 - 4 * n)` in the blueprint. -/
irreducible_def C7_4_4 (a n : ℕ) : ℝ≥0 :=
    2 ^ ((4 * 𝕔 + 12 + 4 * (𝕔 / 4)) * a ^ 3) * 2 ^ (-(4 * n : ℝ))

lemma le_C7_4_4 (ha : 4 ≤ a) : C7_4_5 a n + C7_4_6 a n ≤ C7_4_4 a n := by
  sorry

lemma correlation_separated_trees_of_subset (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hg₁ : BoundedCompactSupport g₁) (hg₂ : BoundedCompactSupport g₂) :
    ‖∫ x, adjointCarlesonSum (t u₁) g₁ x * conj (adjointCarlesonSum (t u₂) g₂ x)‖ₑ ≤
    C7_4_4 a n *
    eLpNorm ((𝓘 u₁ ∩ 𝓘 u₂ : Set X).indicator (adjointBoundaryOperator t u₁ g₁) ·) 2 volume *
    eLpNorm ((𝓘 u₁ ∩ 𝓘 u₂ : Set X).indicator (adjointBoundaryOperator t u₂ g₂) ·) 2 volume := by
  sorry

lemma cst_disjoint (hd : Disjoint (𝓘 u₁ : Set X) (𝓘 u₂)) (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (x : X) :
    adjointCarlesonSum (t u₁) g₁ x * conj (adjointCarlesonSum (t u₂) g₂ x) = 0 := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Lemma 7.4.4 -/
lemma correlation_separated_trees (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (hg₁ : BoundedCompactSupport g₁) (hg₂ : BoundedCompactSupport g₂) :
    ‖∫ x, adjointCarlesonSum (t u₁) g₁ x * conj (adjointCarlesonSum (t u₂) g₂ x)‖ₑ ≤
    C7_4_4 a n *
    eLpNorm ((𝓘 u₁ ∩ 𝓘 u₂ : Set X).indicator (adjointBoundaryOperator t u₁ g₁) ·) 2 volume *
    eLpNorm ((𝓘 u₁ ∩ 𝓘 u₂ : Set X).indicator (adjointBoundaryOperator t u₂ g₂) ·) 2 volume := by
  sorry

/-! ## Section 7.7 -/

def rowDecomp_zornset (s : Set (𝔓 X)) :=
  { x : Set (𝔓 X) | x ⊆ s} ∩ {x : Set (𝔓 X) | x.PairwiseDisjoint (𝓘 ·: _ → Set X)} ∩
    {x : Set (𝔓 X) | x ⊆ {u | Maximal (· ∈ 𝓘 '' s) (𝓘 u)}}

lemma mem_rowDecomp_zornset_iff (s s' : Set (𝔓 X)) :
    s' ∈ rowDecomp_zornset s ↔ (s' ⊆ s ∧ s'.PairwiseDisjoint (𝓘 ·: _ → Set X) ∧
      ∀ u ∈ s', Maximal (· ∈ 𝓘 '' s) (𝓘 u)) := by
  sorry

lemma rowDecomp_zornset_chain_Union_bound (s' : Set (𝔓 X)) {c : Set (Set (𝔓 X))} (hc : c ⊆ rowDecomp_zornset s')
    (hc_chain : IsChain (· ⊆ ·) c) :
    (⋃ s ∈ c,s) ∈ rowDecomp_zornset s' ∧ ∀ s ∈ c, s ⊆ ⋃ s'' ∈ c, s'' := by
  sorry

def rowDecomp_𝔘 (t : Forest X n) (j : ℕ) : Set (𝔓 X) :=
  (zorn_subset (rowDecomp_zornset (t \ ⋃ i < j, rowDecomp_𝔘 t i))
  (fun _ hc ↦ Exists.intro _ ∘ rowDecomp_zornset_chain_Union_bound _ hc)).choose

lemma rowDecomp_𝔘_def (t : Forest X n) (j : ℕ) :
    Maximal (fun x ↦ x ∈ rowDecomp_zornset (t \ ⋃ i < j, rowDecomp_𝔘 t i)) (rowDecomp_𝔘 t j) := by
  sorry

lemma rowDecomp_𝔘_mem_zornset (t : Forest X n) (j : ℕ) :
    t.rowDecomp_𝔘 j ∈ rowDecomp_zornset (t \ ⋃ i < j, rowDecomp_𝔘 t i) := by
  sorry

lemma rowDecomp_𝔘_subset (t : Forest X n) (j : ℕ) :
    t.rowDecomp_𝔘 j ⊆ t \ ⋃ i < j, rowDecomp_𝔘 t i := by
  sorry

lemma rowDecomp_𝔘_pairwiseDisjoint (t : Forest X n) (j : ℕ) :
    (t.rowDecomp_𝔘 j).PairwiseDisjoint (𝓘 ·: _ → Set X) := by
  sorry

lemma mem_rowDecomp_𝔘_maximal (t : Forest X n) (j : ℕ) :
    ∀ x ∈ (t.rowDecomp_𝔘 j), Maximal (· ∈ 𝓘 '' (t \ ⋃ i < j, rowDecomp_𝔘 t i)) (𝓘 x) := by
  sorry

lemma rowDecomp_𝔘_subset_forest (t : Forest X n) (j : ℕ) :
  rowDecomp_𝔘 t j ⊆ t := by
  sorry

/-- The row-decomposition of a tree, defined in the proof of Lemma 7.7.1.
The indexing is off-by-one compared to the blueprint. -/
def rowDecomp (t : Forest X n) (j : ℕ) : Row X n where
  𝔘 := rowDecomp_𝔘 t j
  𝔗 := t
  nonempty' hu := t.nonempty (rowDecomp_𝔘_subset_forest t j hu)
  ordConnected' hu:= t.ordConnected' (rowDecomp_𝔘_subset_forest t j hu)
  𝓘_ne_𝓘' hu := t.𝓘_ne_𝓘' (rowDecomp_𝔘_subset_forest t j hu)
  smul_four_le' hu := t.smul_four_le' (rowDecomp_𝔘_subset_forest t j hu)
  stackSize_le' := le_trans (stackSize_mono (rowDecomp_𝔘_subset_forest t j)) t.stackSize_le'
  dens₁_𝔗_le' hu := t.dens₁_𝔗_le' (rowDecomp_𝔘_subset_forest t j hu)
  lt_dist' hu hu' := t.lt_dist' (rowDecomp_𝔘_subset_forest t j hu) (rowDecomp_𝔘_subset_forest t j hu')
  ball_subset' hu := t.ball_subset' (rowDecomp_𝔘_subset_forest t j hu)
  pairwiseDisjoint' := rowDecomp_𝔘_pairwiseDisjoint t j

lemma mem_forest_of_mem {t : Forest X n} {j : ℕ} {x : 𝔓 X} (hx : x ∈ t.rowDecomp j) : x ∈ t := by
  sorry

lemma rowDecomp_𝔘_eq (t : Forest X n) (j : ℕ) :
  (t.rowDecomp j).𝔘 = rowDecomp_𝔘 t j := by
  sorry

lemma mem_rowDecomp_iff_mem_rowDecomp_𝔘 (t : Forest X n) (j : ℕ) : ∀ x,
  x ∈ t.rowDecomp j ↔ x ∈ t.rowDecomp_𝔘 j := by
  sorry

lemma stackSize_remainder_ge_one_of_exists (t : Forest X n) (j : ℕ) (x : X)
    (hx : ∃ 𝔲' ∈ (t.rowDecomp j).𝔘, x ∈ 𝓘 𝔲') :
    1 ≤ stackSize ((t \ ⋃ i < j, t.rowDecomp i) ∩ t.rowDecomp j: Set _) x := by
  sorry

lemma remainder_stackSize_le (t : Forest X n) (j : ℕ) (x : X) :
    stackSize (t \ ⋃ i < j, t.rowDecomp i : Set _) x ≤ 2 ^ n - j := by
  sorry

/-- Part of Lemma 7.7.1 -/
@[simp]
lemma biUnion_rowDecomp : ⋃ j < 2 ^ n, t.rowDecomp j = (t : Set (𝔓 X)) := by
  sorry

/-- Part of Lemma 7.7.1 -/
lemma pairwiseDisjoint_rowDecomp :
    (Iio (2 ^ n)).PairwiseDisjoint (rowDecomp t · : ℕ → Set (𝔓 X)) := by
  sorry

@[simp] lemma rowDecomp_apply : t.rowDecomp j u = t u := by
  sorry

open scoped Classical in
/-- The definition of `T_{ℜ_j}f(x)`, defined above Lemma 7.7.2. -/
def carlesonRowSum (t : Forest X n) (j : ℕ) (f : X → ℂ) (x : X) : ℂ :=
  ∑ u with u ∈ rowDecomp t j, carlesonSum (t u) f x

open scoped Classical in
/-- The definition of `T_{ℜ_j}*f(x)`, defined above Lemma 7.7.2. -/
def adjointCarlesonRowSum (t : Forest X n) (j : ℕ) (f : X → ℂ) (x : X) : ℂ :=
  ∑ u with u ∈ rowDecomp t j, adjointCarlesonSum (t u) f x

/-- `adjointCarlesonRowSum` is the adjoint of `carlesonRowSum`. -/
lemma adjointCarlesonRowSum_adjoint
    (hf : BoundedCompactSupport f) (hg : BoundedCompactSupport g) (j : ℕ) :
    ∫ x, conj (g x) * carlesonRowSum t j f x = ∫ x, conj (adjointCarlesonRowSum t j g x) * f x := by
  sorry

/-- Common proof structure for the two parts of Lemma 7.7.2. -/
lemma row_bound_common (hg : BoundedCompactSupport g) {A : Set X} (mA : MeasurableSet A) {C : ℝ≥0∞}
    (hC : ∀ u ∈ t.rowDecomp j,
      eLpNorm (A.indicator (adjointCarlesonSum (t u) ((𝓘 u : Set X).indicator g))) 2 ≤
      C * eLpNorm ((𝓘 u : Set X).indicator g) 2) :
    eLpNorm (A.indicator (adjointCarlesonRowSum t j g)) 2 ≤ C * eLpNorm g 2 := by
  sorry

/-- The constant used in `row_bound`.
Has value `2 ^ (182 * a ^ 3 - n / 2)` in the blueprint. -/
irreducible_def C7_7_2_1 (a n : ℕ) : ℝ≥0 :=
  2 ^ ((𝕔 + 7 + 𝕔 / 2 + 𝕔 / 4) * a ^ 3) * 2 ^ (- (n / 2 : ℝ))

lemma le_C7_7_2_1 (a4 : 4 ≤ a) :
    C7_3_1_1 a * (2 ^ (4 * (a : ℝ) - n + 1)) ^ (2 : ℝ)⁻¹ ≤ C7_7_2_1 a n := by
  sorry

/-- The constant used in `indicator_row_bound`.
Has value `2 ^ (283 * a ^ 3 - n / 2)` in the blueprint. -/
irreducible_def C7_7_2_2 (a n : ℕ) : ℝ≥0 :=
  2 ^ ((2 * 𝕔 + 8 + 𝕔 / 2 + 𝕔 / 4) * a ^ 3) * 2 ^ (- (n / 2 : ℝ))

lemma le_C7_7_2_2 (a4 : 4 ≤ a) :
    C7_3_1_2 a * (2 ^ (4 * (a : ℝ) - n + 1)) ^ (2 : ℝ)⁻¹ ≤ C7_7_2_2 a n := by
  sorry

lemma row_bound (hg : BoundedCompactSupport g) (h2g : support g ⊆ G) :
    eLpNorm (adjointCarlesonRowSum t j g) 2 volume ≤ C7_7_2_1 a n * eLpNorm g 2 volume := by
  sorry

lemma indicator_row_bound (hg : BoundedCompactSupport g) (h2g : support g ⊆ G) :
    eLpNorm (F.indicator (adjointCarlesonRowSum t j g)) 2 volume ≤
    C7_7_2_2 a n * dens₂ (⋃ u ∈ t, t u) ^ (2 : ℝ)⁻¹ * eLpNorm g 2 volume := by
  sorry

open Classical in
lemma row_correlation_aux (hf : BoundedCompactSupport f) (nf : f.support ⊆ G) :
    (∑ u with u ∈ t.rowDecomp j, ∑ u' with u' ∈ t.rowDecomp j',
    eLpNorm ((𝓘 u ∩ 𝓘 u' : Set X).indicator
      (adjointBoundaryOperator t u ((𝓘 u : Set X).indicator f)) ·) 2 volume ^ (2 : ℝ)) ^ (2 : ℝ)⁻¹ ≤
    C7_4_3 a * eLpNorm f 2 volume := by
  sorry

/-- The constant used in `row_correlation`.
Has value `2 ^ (876 * a ^ 3 - 4 * n)` in the blueprint. -/
irreducible_def C7_7_3 (a n : ℕ) : ℝ≥0 := C7_4_3 a ^ 2 * C7_4_4 a n

/-- Lemma 7.7.3. -/
lemma row_correlation (lj : j < 2 ^ n) (lj' : j' < 2 ^ n) (hn : j ≠ j')
    (hf₁ : BoundedCompactSupport f₁) (nf₁ : f₁.support ⊆ G)
    (hf₂ : BoundedCompactSupport f₂) (nf₂ : f₂.support ⊆ G) :
    ‖∫ x, adjointCarlesonRowSum t j f₁ x * conj (adjointCarlesonRowSum t j' f₂ x)‖ₑ ≤
    C7_7_3 a n * eLpNorm f₁ 2 volume * eLpNorm f₂ 2 volume := by
  sorry

variable (t) in
/-- The definition of `Eⱼ` defined above Lemma 7.7.4. -/
def rowSupport (j : ℕ) : Set X := ⋃ (u ∈ rowDecomp t j) (p ∈ t u), E p

lemma disjoint_impl {p p' : 𝔓 X} : Disjoint (Ω p) (Ω p') → Disjoint (E p) (E p') := by
  sorry

lemma disjoint_of_ne_of_mem {i j : ℕ} {u u' : 𝔓 X} (hne : u ≠ u') (hu : u ∈ t.rowDecomp i) (hu' : u' ∈ t.rowDecomp j)
  {p p' : 𝔓 X} (hp : p ∈ t u) (hp' : p' ∈ t u') : Disjoint (E p) (E p') := by
  sorry

lemma measurableSet_rowSupport : MeasurableSet (rowSupport t j) := by
  sorry

/-- Lemma 7.7.4 -/
lemma pairwiseDisjoint_rowSupport : (Iio (2 ^ n)).PairwiseDisjoint (rowSupport t) := by
  sorry

section FinalProp

open scoped Classical in
lemma forest_operator_g_prelude
    (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x)
    (hg : Measurable g) (h2g : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    ‖∫ x, conj (g x) * ∑ u with u ∈ t, carlesonSum (t u) f x‖ₑ ≤
    eLpNorm f 2 * eLpNorm (∑ u with u ∈ t, adjointCarlesonSum (t u) g ·) 2 := by
  sorry

lemma adjointCarlesonRowSum_rowSupport :
    adjointCarlesonRowSum t j f = adjointCarlesonRowSum t j ((rowSupport t j).indicator f) := by
  sorry

/-- The constant on the `g` side of Proposition 2.0.4.
Has value `2 ^ (440 * a ^ 3)` in the blueprint. -/
def G2_0_4 (a n : ℕ) : ℝ≥0 := 2 ^ ((3 * 𝕔 + 15 + 5 * (𝕔 / 4)) * a ^ 3) * 2 ^ (-(n / 2 : ℝ))

lemma le_sq_G2_0_4 (a4 : 4 ≤ a) : C7_7_2_1 a n ^ 2 + C7_7_3 a n * 2 ^ n ≤ G2_0_4 a n ^ 2 := by
  sorry

omit [MetricSpace X] in
lemma support_subset_of_norm_le_indicator {g : X → ℝ} {A : Set X}
    (h2f : ∀ x, ‖f x‖ ≤ A.indicator g x) : f.support ⊆ A := by
  sorry

open Classical in
lemma forest_operator_g_main (hg : Measurable g) (h2g : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    eLpNorm (∑ u with u ∈ t, adjointCarlesonSum (t u) g ·) 2 ^ 2 ≤
    (G2_0_4 a n * eLpNorm g 2) ^ 2 := by
  sorry

open Classical in
/-- The `g` side of Proposition 2.0.4. -/
lemma forest_operator_g (t : Forest X n)
    (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x)
    (hg : Measurable g) (h2g : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    ‖∫ x, conj (g x) * ∑ u with u ∈ t, carlesonSum (t u) f x‖ₑ ≤
    G2_0_4 a n * eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

lemma carlesonRowSum_rowSupport :
    carlesonRowSum t j f = (rowSupport t j).indicator (carlesonRowSum t j f) := by
  sorry

open Classical in
lemma forest_operator_f_prelude
    (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x)
    (hg : Measurable g) (h2g : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    ‖∫ x, conj (g x) * ∑ u with u ∈ t, carlesonSum (t u) f x‖ₑ ≤
    eLpNorm g 2 * eLpNorm (fun x ↦ G.indicator (∑ u with u ∈ t, carlesonSum (t u) f ·) x) 2 := by
  sorry

/-- https://leanprover.zulipchat.com/#narrow/channel/442935-Carleson/topic/Problems.20in.20the.20forest.20operator.20proposition/near/522771057 -/
lemma forest_operator_f_inner (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x) :
    eLpNorm (G.indicator (carlesonRowSum t j f)) 2 ≤
    C7_7_2_2 a n * dens₂ (⋃ u ∈ t, t u) ^ (2 : ℝ)⁻¹ * eLpNorm f 2 := by
  sorry

/-- The constant in the `f` side of Proposition 2.0.4.
Has value `2 ^ (283 * a ^ 3)` in the blueprint. -/
def C2_0_4_aux (a : ℕ) : ℝ≥0 := 2 ^ ((2 * 𝕔 + 8 + 𝕔 / 2 + 𝕔 / 4) * a ^ 3)

open Classical in
lemma forest_operator_f_main (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x) :
    eLpNorm (fun x ↦ G.indicator (∑ u with u ∈ t, carlesonSum (t u) f ·) x) 2 volume ^ 2 ≤
    (C2_0_4_aux a
      * dens₂ (⋃ u ∈ t, t u) ^ (2 : ℝ)⁻¹ * eLpNorm f 2 volume) ^ 2 := by
  sorry

open Classical in
/-- The `f` side of Proposition 2.0.4. -/
lemma forest_operator_f (t : Forest X n)
    (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x)
    (hg : Measurable g) (h2g : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    ‖∫ x, conj (g x) * ∑ u with u ∈ t, carlesonSum (t u) f x‖ₑ ≤
    C2_0_4_aux a * dens₂ (⋃ u ∈ t, t u) ^ (2 : ℝ)⁻¹ *
    eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

end FinalProp

end TileStructure.Forest

/-! ## Proposition 2.0.4 -/

irreducible_def C2_0_4_base (a : ℕ) : ℝ≥0 := 2 ^ ((3 * 𝕔 + 15 + 5 * (𝕔 / 4)) * a ^ 3)

/-- The constant used in `forest_operator`.
Has value `2 ^ (440 * a ^ 3 - (q - 1) / q * n)` in the blueprint. -/
irreducible_def C2_0_4 (a : ℕ) (q : ℝ) (n : ℕ) : ℝ≥0 := C2_0_4_base a * 2 ^ (-(q - 1) / q * n)

open scoped Classical in
theorem forest_operator {n : ℕ} (𝔉 : Forest X n) {f g : X → ℂ}
    (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x)
    (hg : Measurable g) (h2g : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    ‖∫ x, conj (g x) * ∑ u with u ∈ 𝔉, carlesonSum (𝔉 u) f x‖ₑ ≤
    C2_0_4 a q n * (dens₂ (⋃ u ∈ 𝔉, 𝔉 u)) ^ (q⁻¹ - 2⁻¹) *
    eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

open scoped Classical in
/-- Version of the forest operator theorem, but controlling the integral of the norm instead of
the integral of the function multiplied by another function. -/
theorem forest_operator' {n : ℕ} (𝔉 : Forest X n) {f : X → ℂ} {A : Set X}
    (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (hA : MeasurableSet A) (sA : A ⊆ G) :
    ∫⁻ x in A, ‖∑ u with u ∈ 𝔉, carlesonSum (𝔉 u) f x‖ₑ ≤
    C2_0_4 a q n * (dens₂ (⋃ u ∈ 𝔉, 𝔉 u)) ^ (q⁻¹ - 2⁻¹) *
    eLpNorm f 2 volume * (volume A) ^ (1/2 : ℝ) := by
  sorry

open scoped Classical in
/-- Version of the forest operator theorem, but controlling the integral of the norm instead of
the integral of the function multiplied by another function, and with the upper bound in terms
of `volume F` and `volume G`. -/
theorem forest_operator_le_volume {n : ℕ} (𝔉 : Forest X n) {f : X → ℂ} {A : Set X}
    (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (hA : MeasurableSet A) (sA : A ⊆ G) :
    ∫⁻ x in A, ‖∑ u with u ∈ 𝔉, carlesonSum (𝔉 u) f x‖ₑ ≤
    C2_0_4 a q n * (dens₂ (⋃ u ∈ 𝔉, 𝔉 u)) ^ (q⁻¹ - 2⁻¹) *
    (volume F) ^ (1/2 : ℝ) * (volume A) ^ (1/2 : ℝ) := by
  sorry
