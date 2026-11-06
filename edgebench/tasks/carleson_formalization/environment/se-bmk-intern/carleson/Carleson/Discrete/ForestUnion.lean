module

public import Carleson.Discrete.Defs
public import Carleson.Discrete.SumEstimates
public import Carleson.ForestOperator.Forests
public import Carleson.MinLayerTiles
public import Mathlib.Analysis.Complex.ExponentialBounds

@[expose] public section

open MeasureTheory Measure NNReal Metric Complex Set
open scoped ENNReal
noncomputable section

open scoped ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]

variable {k n j l : ℕ} {p p' u u' : 𝔓 X} {x : X}

/-! ## Section 5.3 -/

/-! Note: the lemmas 5.3.1-5.3.3 are in `TileStructure`. -/

/-- Lemma 5.3.4 -/
lemma ordConnected_tilesAt : OrdConnected (TilesAt k : Set (𝔓 X)) := by
  sorry

/-- Lemma 5.3.5 -/
lemma ordConnected_C : OrdConnected (ℭ k n : Set (𝔓 X)) := by
  sorry

/-- Lemma 5.3.6 -/
lemma ordConnected_C1 : OrdConnected (ℭ₁ k n j : Set (𝔓 X)) := by
  sorry

/-- Lemma 5.3.7 -/
lemma ordConnected_C2 : OrdConnected (ℭ₂ k n j : Set (𝔓 X)) := by
  sorry

/-- Lemma 5.3.8 -/
lemma ordConnected_C3 : OrdConnected (ℭ₃ k n j : Set (𝔓 X)) := by
  sorry

/-- Lemma 5.3.9 -/
lemma ordConnected_C4 : OrdConnected (ℭ₄ k n j : Set (𝔓 X)) := by
  sorry

/-- Lemma 5.3.10 -/
lemma ordConnected_C5 : OrdConnected (ℭ₅ k n j : Set (𝔓 X)) := by
  sorry

/-! ## Section 5.4 and Lemma 5.1.2 -/

/-- The subset `ℭ₆(k, n, j)` of `ℭ₅(k, n, j)`, given above (5.4.1). -/
def ℭ₆ (k n j : ℕ) : Set (𝔓 X) :=
  { p ∈ ℭ₅ k n j | ¬ (𝓘 p : Set X) ⊆ G' }

lemma ℭ₆_subset_ℭ₅ : ℭ₆ (X := X) k n j ⊆ ℭ₅ k n j := by
  sorry
lemma ℭ₆_subset_ℭ : ℭ₆ (X := X) k n j ⊆ ℭ k n := by
  sorry

/-- The subset `𝔗₁(u)` of `ℭ₁(k, n, j)`, given in (5.4.1).
In lemmas, we will assume `u ∈ 𝔘₁ k n l` -/
def 𝔗₁ (k n j : ℕ) (u : 𝔓 X) : Set (𝔓 X) :=
  { p ∈ ℭ₁ k n j | 𝓘 p ≠ 𝓘 u ∧ smul 2 p ≤ smul 1 u }

lemma 𝓘_lt_of_mem_𝔗₁ (h : p ∈ 𝔗₁ k n j p') : 𝓘 p < 𝓘 p' := by
  sorry

/-- The subset `𝔘₂(k, n, j)` of `𝔘₁(k, n, j)`, given in (5.4.2). -/
def 𝔘₂ (k n j : ℕ) : Set (𝔓 X) :=
  { u ∈ 𝔘₁ k n j | ¬ Disjoint (𝔗₁ k n j u) (ℭ₆ k n j) }

lemma 𝔘₂_subset_𝔘₁ : 𝔘₂ k n j ⊆ 𝔘₁ (X := X) k n j := by
  sorry

/-- The relation `∼` defined below (5.4.2). It is an equivalence relation on `𝔘₂ k n j`. -/
def URel (k n j : ℕ) (u u' : 𝔓 X) : Prop :=
  u = u' ∨ ∃ p ∈ 𝔗₁ k n j u, smul 10 p ≤ smul 1 u'

nonrec lemma URel.rfl : URel k n j u u := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Lemma 5.4.1, part 2. -/
lemma URel.not_disjoint (hu : u ∈ 𝔘₂ k n j) (hu' : u' ∈ 𝔘₂ k n j) (huu' : URel k n j u u') :
    ¬Disjoint (ball_(u) (𝒬 u) 100) (ball_(u') (𝒬 u') 100) := by
  sorry

/-- Lemma 5.4.1, part 1. -/
lemma URel.eq (hu : u ∈ 𝔘₂ k n j) (hu' : u' ∈ 𝔘₂ k n j) (huu' : URel k n j u u') : 𝓘 u = 𝓘 u' := by
  sorry

/-- Helper for 5.4.2 that is also used in 5.4.9. -/
lemma urel_of_not_disjoint {x y : 𝔓 X} (my : y ∈ 𝔘₂ k n j) (xye : 𝓘 x = 𝓘 y)
    (nd : ¬Disjoint (ball_(x) (𝒬 x) 100) (ball_(y) (𝒬 y) 100)) : URel k n j y x := by
  sorry

/-- Lemma 5.4.2. -/
lemma equivalenceOn_urel : EquivalenceOn (URel (X := X) k n j) (𝔘₂ k n j) := by
  sorry

/-- `𝔘₃(k, n, j) ⊆ 𝔘₂ k n j` is an arbitary set of representatives of `URel` on `𝔘₂ k n j`,
given above (5.4.5). -/
def 𝔘₃ (k n j : ℕ) : Set (𝔓 X) :=
  (equivalenceOn_urel (k := k) (n := n) (j := j)).reprs

lemma 𝔘₃_subset_𝔘₂ : 𝔘₃ k n j ⊆ 𝔘₂ (X := X) k n j := by
  sorry

/-- The subset `𝔗₂(u)` of `ℭ₆(k, n, j)`, given in (5.4.5).
In lemmas, we will assume `u ∈ 𝔘₃ k n l` -/
def 𝔗₂ (k n j : ℕ) (u : 𝔓 X) : Set (𝔓 X) :=
  ℭ₆ k n j ∩ ⋃ (u' ∈ 𝔘₂ k n j) (_ : URel k n j u u'), 𝔗₁ k n j u'

lemma 𝔗₂_subset_ℭ₆ : 𝔗₂ k n j u ⊆ ℭ₆ k n j := by
  sorry

/-- Lemma 5.4.3 -/
lemma C6_forest : ℭ₆ (X := X) k n j = ⋃ u ∈ 𝔘₃ k n j, 𝔗₂ k n j u := by
  sorry

/-- This one could deserve a lemma in the blueprint, as it is needed to decompose the sum
of Carleson operators over disjoint subfamilies. -/
lemma forest_disjoint : (𝔘₃ k n j).PairwiseDisjoint (fun u ↦ 𝔗₂ (X := X) k n j u) := by
  sorry

/-- Lemma 5.4.4, verifying (2.0.32) -/
lemma forest_geometry (hu : u ∈ 𝔘₃ k n j) (hp : p ∈ 𝔗₂ k n j u) : smul 4 p ≤ smul 1 u := by
  sorry

/-- Lemma 5.4.5, verifying (2.0.33) -/
lemma forest_convex : OrdConnected (𝔗₂ k n j u) := by
  sorry

/-- Lemma 5.4.6, verifying (2.0.36)
Note: swapped `u` and `u'` to match (2.0.36) -/
lemma forest_separation (hu : u ∈ 𝔘₃ k n j) (hu' : u' ∈ 𝔘₃ k n j) (huu' : u ≠ u')
    (hp : p ∈ 𝔗₂ k n j u') (h : 𝓘 p ≤ 𝓘 u) : 2 ^ (Z * (n + 1)) < dist_(p) (𝒬 p) (𝒬 u) := by
  sorry

/-- Lemma 5.4.7, verifying (2.0.37) -/
lemma forest_inner (hu : u ∈ 𝔘₃ k n j) (hp : p ∈ 𝔗₂ k n j u) :
    ball (𝔠 p) (8 * D ^ 𝔰 p) ⊆ 𝓘 u := by
  sorry

/-- The multiplicity appearing in Lemma 5.4.8. -/
def C5_4_8 (n : ℕ) : ℕ := (4 * n + 12) * 2 ^ n

lemma exists_smul_le_of_𝔘₃ (u : 𝔘₃ k n j) : ∃ m : 𝔐 (X := X) k n, smul 100 u.1 ≤ smul 1 m.1 := by
  sorry

variable (k n j) in
/-- The good choice of an element to get a contradiction in the proof of Lemma 5.4.8. -/
def mf (u : 𝔘₃ (X := X) k n j) : 𝔐 (X := X) k n := (exists_smul_le_of_𝔘₃ u).choose

lemma mf_injOn : InjOn (mf k n j) {u | x ∈ 𝓘 u.1} := by
  sorry

lemma stackSize_𝔘₃_le_𝔐 (x : X) : stackSize (𝔘₃ k n j) x ≤ stackSize (𝔐 k n) x := by
  sorry

/-- Lemma 5.4.8, used to verify that 𝔘₄ satisfies 2.0.34. -/
lemma forest_stacking (x : X) (hkn : k ≤ n) : stackSize (𝔘₃ (X := X) k n j) x ≤ C5_4_8 n := by
  sorry

/-- Define `𝔘₄ k n j l` as the union of `2 ^ n` disjoint subfamilies in `𝔘₃ k n j`, to make sure
the multiplicity is at most `2 ^ n` to get a forest. -/
def 𝔘₄ (k n j l : ℕ) : Set (𝔓 X) :=
  ⋃ i ∈ Ico (l * 2 ^ n) ((l + 1) * 2 ^ n), iteratedMaximalSubfamily (𝔘₃ k n j) i

lemma 𝔘₄_subset_𝔘₃ {k n j l} : 𝔘₄ (X := X) k n j l ⊆ 𝔘₃ k n j := by
  sorry

/-- The sets `(𝔘₄(k, n, j, l))_l` form a partition of `𝔘₃ k n j`. -/
lemma iUnion_𝔘₄ (hkn : k ≤ n) : ⋃ l ∈ Iio (4 * n + 12), 𝔘₄ (X := X) k n j l = 𝔘₃ k n j := by
  sorry

lemma C6_forest' (hkn : k ≤ n) :
    ℭ₆ (X := X) k n j = ⋃ l ∈ Iio (4 * n + 12), ⋃ u ∈ 𝔘₄ k n j l, 𝔗₂ k n j u := by
  sorry -- perf: squeeze

lemma pairwiseDisjoint_𝔘₄ : univ.PairwiseDisjoint (𝔘₄ (X := X) k n j) := by
  sorry

lemma stackSize_𝔘₄_le (x : X) : stackSize (𝔘₄ (X := X) k n j l) x ≤ 2 ^ n := by
  sorry

open TileStructure
variable (k n j l) in
/-- The forest based on `𝔘₄ k n j l`. -/
def forest : Forest X n where
  𝔘 := 𝔘₄ k n j l
  𝔗 := 𝔗₂ k n j
  nonempty' {u} hu := by
    have m : u ∈ 𝔘₂ k n j := (𝔘₃_subset_𝔘₂ (𝔘₄_subset_𝔘₃ hu))
    have : ℭ₆ k n j ∩ 𝔗₁ k n j u ⊆ 𝔗₂ k n j u := by
      apply inter_subset_inter_right
      have : 𝔗₁ k n j u ⊆ ⋃ (_ : URel k n j u u), 𝔗₁ k n j u := by
        intro p hp
        exact Set.mem_iUnion.mpr ⟨(equivalenceOn_urel (X := X)).refl _ m, hp⟩
      apply this.trans
      apply subset_biUnion_of_mem (u := fun u' ↦ ⋃ (_ : URel k n j u u'), 𝔗₁ k n j u') m
    apply Nonempty.mono this
    rw [inter_comm]
    simp only [𝔘₂, not_disjoint_iff_nonempty_inter, mem_setOf_eq] at m
    exact m.2
  ordConnected' {u} hu := forest_convex
  𝓘_ne_𝓘' {u} hu p hp := by
    have := hp.2
    simp only [mem_iUnion, exists_prop] at this
    rcases this with ⟨u', hu', u'rel, hu'I⟩
    rw [URel.eq (𝔘₃_subset_𝔘₂ (𝔘₄_subset_𝔘₃ hu)) hu' u'rel]
    exact (𝓘_lt_of_mem_𝔗₁ hu'I).ne
  smul_four_le' {u} hu := forest_geometry <| 𝔘₄_subset_𝔘₃ hu
  stackSize_le' {x} := stackSize_𝔘₄_le x
  dens₁_𝔗_le' {u} hu := dens1_le <| 𝔗₂_subset_ℭ₆.trans ℭ₆_subset_ℭ
  lt_dist' hu hu' huu' p hp := forest_separation (𝔘₄_subset_𝔘₃ hu) (𝔘₄_subset_𝔘₃ hu') huu' hp
  ball_subset' hu p hp := forest_inner (𝔘₄_subset_𝔘₃ hu) hp

/-- From the fact that the `ℭ₅ k n j` are disjoint, one can rewrite the whole Carleson sum over
`𝔓₁` (the union of the `ℭ₅ k n j`) as a sum of Carleson sums over the `ℭ₅ k n j`. -/
lemma carlesonSum_𝔓₁_eq_sum {f : X → ℂ} {x : X} :
    carlesonSum 𝔓₁ f x = ∑ n ≤ maxℭ X, ∑ k ≤ n, ∑ j ≤ 2 * n + 3, carlesonSum (ℭ₅ k n j) f x := by
  sorry

/-- The Carleson sum over `ℭ₅` and `ℭ₆` coincide, for points in `G \ G'`. -/
lemma carlesonSum_ℭ₅_eq_ℭ₆ {f : X → ℂ} {x : X} (hx : x ∈ G \ G') {k n j : ℕ} :
    carlesonSum (ℭ₅ k n j) f x = carlesonSum (ℭ₆ k n j) f x := by
  sorry

/-- The Carleson sum over `ℭ₆` can be decomposed as a sum over `4 n + 12` forests
based on `𝔘₄ k n j l`. -/
lemma carlesonSum_ℭ₆_eq_sum {f : X → ℂ} {x : X} {k n j : ℕ} (hkn : k ≤ n) :
    carlesonSum (ℭ₆ k n j) f x =
      ∑ l < 4 * n + 12, carlesonSum (⋃ u ∈ 𝔘₄ k n j l, 𝔗₂ k n j u) f x := by
  sorry -- perf: squeezed

/-- For each forest, the integral of the norm of the Carleson sum can be controlled thanks to
the forest theorem and to the density control coming from the fact we are away from `G₁`. -/
lemma lintegral_carlesonSum_forest
    {f : X → ℂ} (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x) :
    ∫⁻ x in G \ G', ‖carlesonSum (⋃ u ∈ 𝔘₄ k n j l, 𝔗₂ k n j u) f x‖ₑ ≤
    C2_0_4 a q n * (2 ^ (2 * a + 5) * volume F / volume G) ^ (q⁻¹ - 2⁻¹) *
    (volume F) ^ (1/2 : ℝ) * (volume G) ^ (1/2 : ℝ) := by
  sorry

/-- For each forest, the integral of the norm of the Carleson sum can be controlled thanks to
the forest theorem and to the density control coming from the fact we are away from `G₁`. Second
version, with the volume of `F`. -/
lemma lintegral_carlesonSum_forest'
    {f : X → ℂ} (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x) :
    ∫⁻ x in G \ G', ‖carlesonSum (⋃ u ∈ 𝔘₄ k n j l, 𝔗₂ k n j u) f x‖ₑ ≤
    C2_0_4 a q n * 2 ^ (a + 5/2 : ℝ) * (volume G) ^ (1 - q⁻¹) * (volume F) ^ (q⁻¹) := by
  sorry

/-- Putting all the above decompositions together, one obtains a control of the integral of the
full Carleson sum over `𝔓₁`, as a sum over all the forests. -/
lemma forest_union_aux {f : X → ℂ} (hf : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (h'f : Measurable f) :
    ∫⁻ x in G \ G', ‖carlesonSum 𝔓₁ f x‖ₑ ≤ C2_0_4_base a * 2 ^ (a + 5/2 : ℝ) *
         (volume G) ^ (1 - q⁻¹) * (volume F) ^ (q⁻¹) *
        ∑ n ≤ maxℭ X, ∑ _k ≤ n, ∑ _j ≤ 2 * n + 3, ∑ _l < 4 * n + 12,
          (2 : ℝ≥0∞) ^ (- (q - 1) / q * n : ℝ) := by
  sorry

/- It remains to bound the sum above, by a sum/integral comparison over `ℝ` and then a cast from
`ℝ` to `ℝ≥0∞`. We do that in the next two lemmas. -/

open scoped Nat
open Real

lemma forest_union_sum_aux1 (M : ℕ) (q : ℝ) (hq : 1 < q) (h'q : q ≤ 2) :
    ∑ n ≤ M, ∑ _k ≤ n, ∑ _j ≤ 2 * n + 3, ∑ _l < 4 * n + 12,
      (2 : ℝ) ^ (- ((q - 1) / q * n)) ≤ 13009 / (q - 1) ^ 4 := by
  sorry

lemma forest_union_sum_aux2 (M : ℕ) (q : ℝ) (hq : 1 < q) (h'q : q ≤ 2) :
    (∑ n ≤ M, ∑ _k ≤ n, ∑ _j ≤ 2 * n + 3, ∑ _l < 4 * n + 12,
      (2 : ℝ≥0∞) ^ (- ((q - 1) / q * n))) ≤ 13009 / (ENNReal.ofReal (q - 1)) ^ 4 := by
  sorry

/-- An optimized constant for the forest union theorem. The constant from the blueprint,
defined as `C5_1_2` below, is slightly worse. -/
def C5_1_2_optimized (a : ℕ) (q : ℝ≥0) : ℝ≥0 :=
  C2_0_4_base a * 2 ^ (a + 5/2 : ℝ) * 13009 / (q - 1) ^ 4

/-- Version of the forest union result with a better constant. -/
lemma forest_union_optimized {f : X → ℂ} (hf : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (h'f : Measurable f) :
    ∫⁻ x in G \ G', ‖carlesonSum 𝔓₁ f x‖ₑ ≤
    C5_1_2_optimized a nnq * (volume G) ^ (1 - q⁻¹) * (volume F) ^ (q⁻¹) := by
  sorry

lemma C5_1_2_optimized_le' {a : ℕ} {q : ℝ≥0} (ha : 4 ≤ a) :
    C5_1_2_optimized a q ≤ C2_0_4_base a * 2 ^ (a ^ 3) / (q - 1) ^ 4 := by
  sorry

/-- The constant used in Lemma 5.1.2.
Has value `2 ^ (441 * a ^ 3) / (q - 1) ^ 4` in the blueprint. -/
def C5_1_2 (a : ℕ) (q : ℝ≥0) : ℝ≥0 := 2 ^ ((3 * 𝕔 + 16 + 5 * (𝕔 / 4)) * a ^ 3) / (q - 1) ^ 4

omit [TileStructure Q D κ S o] in
lemma C5_1_2_pos : 0 < C5_1_2 a nnq := by
  sorry

omit [TileStructure Q D κ S o] in
lemma C5_1_2_optimized_le : C5_1_2_optimized a nnq ≤ C5_1_2 a nnq := by
  sorry

/-- Lemma 5.1.2 in the blueprint: the integral of the Carleson sum over the set which can
naturally be decomposed as a union of forests can be controlled, thanks to the estimate for
a single forest. -/
lemma forest_union {f : X → ℂ} (hf : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (h'f : Measurable f) :
    ∫⁻ x in G \ G', ‖carlesonSum 𝔓₁ f x‖ₑ ≤
    C5_1_2 a nnq * (volume G) ^ (1 - q⁻¹) * (volume F) ^ (q⁻¹) := by
  sorry
