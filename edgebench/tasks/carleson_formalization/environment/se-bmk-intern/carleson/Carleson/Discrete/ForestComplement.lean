module

public import Carleson.Antichain.AntichainOperator
public import Carleson.Discrete.Defs
public import Carleson.Discrete.SumEstimates
public import Mathlib.Analysis.Complex.ExponentialBounds
public import Mathlib.Combinatorics.Enumerative.DoubleCounting

@[expose] public section

open MeasureTheory Measure NNReal Metric Complex Set
open scoped ENNReal
noncomputable section

open scoped ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]

variable {k n j l : ℕ} {p p' u u' : 𝔓 X} {x : X}

/-! ## Section 5.5 and Lemma 5.1.3 -/

/-- The set 𝔓_{G\G'} in the blueprint -/
def 𝔓pos : Set (𝔓 X) := { p : 𝔓 X | 0 < volume (𝓘 p ∩ G ∩ G'ᶜ) }

lemma exists_mem_aux𝓒 {i : Grid X} (hi : 0 < volume (G ∩ i)) : ∃ k, i ∈ aux𝓒 (k + 1) := by
  sorry

lemma exists_k_of_mem_𝔓pos (h : p ∈ 𝔓pos (X := X)) : ∃ k, p ∈ TilesAt k := by
  sorry

lemma dens'_le_of_mem_𝔓pos (h : p ∈ 𝔓pos (X := X)) : dens' k {p} ≤ 2 ^ (-k : ℤ) := by
  sorry

lemma exists_E₂_volume_pos_of_mem_𝔓pos (h : p ∈ 𝔓pos (X := X)) : ∃ r : ℕ, 0 < volume (E₂ r p) := by
  sorry

lemma dens'_pos_of_mem_𝔓pos (h : p ∈ 𝔓pos (X := X)) (hp : p ∈ TilesAt k) : 0 < dens' k {p} := by
  sorry

lemma exists_k_n_of_mem_𝔓pos (h : p ∈ 𝔓pos (X := X)) : ∃ k n, p ∈ ℭ k n ∧ k ≤ n := by
  sorry

private lemma two_mul_n_add_six_lt : 2 * n + 6 < 2 ^ (n + 3) := by
  sorry

lemma exists_j_of_mem_𝔓pos_ℭ (h : p ∈ 𝔓pos (X := X)) (mp : p ∈ ℭ k n) (hkn : k ≤ n) :
    p ∈ 𝔏₀ k n ∨ ∃ j ≤ 2 * n + 3, p ∈ ℭ₁ k n j := by
  sorry

lemma exists_k_n_j_of_mem_𝔓pos (h : p ∈ 𝔓pos (X := X)) :
    ∃ k n, k ≤ n ∧ (p ∈ 𝔏₀ k n ∨ ∃ j ≤ 2 * n + 3, p ∈ ℭ₁ k n j) := by
  sorry

/-- The union occurring in the statement of Lemma 5.5.1 containing 𝔏₀ -/
def ℜ₀ : Set (𝔓 X) := 𝔓pos ∩ ⋃ (n : ℕ) (k ≤ n), 𝔏₀ k n

/-- The union occurring in the statement of Lemma 5.5.1 containing 𝔏₁ -/
def ℜ₁ : Set (𝔓 X) := 𝔓pos ∩ ⋃ (n : ℕ) (k ≤ n) (j ≤ 2 * n + 3) (l ≤ Z * (n + 1)), 𝔏₁ k n j l

/-- The union occurring in the statement of Lemma 5.5.1 containing 𝔏₂ -/
def ℜ₂ : Set (𝔓 X) := 𝔓pos ∩ ⋃ (n : ℕ) (k ≤ n) (j ≤ 2 * n + 3), 𝔏₂ k n j

/-- The union occurring in the statement of Lemma 5.5.1 containing 𝔏₃ -/
def ℜ₃ : Set (𝔓 X) := 𝔓pos ∩ ⋃ (n : ℕ) (k ≤ n) (j ≤ 2 * n + 3) (l ≤ Z * (n + 1)), 𝔏₃ k n j l

/-- Lemma allowing to peel `⋃ (n : ℕ) (k ≤ n)` from unions in the proof of Lemma 5.5.1. -/
lemma mem_iUnion_iff_mem_of_mem_ℭ {f : ℕ → ℕ → Set (𝔓 X)} (hp : p ∈ ℭ k n ∧ k ≤ n)
    (hf : ∀ k n, f k n ⊆ ℭ k n) : p ∈ ⋃ (n : ℕ) (k ≤ n), f k n ↔ p ∈ f k n := by
  sorry

/-- Lemma allowing to peel `⋃ (j ≤ 2 * n + 3)` from unions in the proof of Lemma 5.5.1. -/
lemma mem_iUnion_iff_mem_of_mem_ℭ₁ {f : ℕ → Set (𝔓 X)} (hp : p ∈ ℭ₁ k n j ∧ j ≤ 2 * n + 3)
    (hf : ∀ j, f j ⊆ ℭ₁ k n j) : p ∈ ⋃ (j ≤ 2 * n + 3), f j ↔ p ∈ f j := by
  sorry

lemma notMem_ℭ₅_iff_mem_𝔏₃ (hkn : k ≤ n) (hj : j ≤ 2 * n + 3)
    (h : p ∈ 𝔓pos) (mc2 : p ∈ ℭ₂ k n j) (ml2 : p ∉ 𝔏₂ k n j) :
    p ∉ ℭ₅ k n j ↔ p ∈ ⋃ l, ⋃ (_ : l ≤ Z * (n + 1)), 𝔏₃ k n j l := by
  sorry

/-- Lemma 5.5.1.

We will not use the lemma in this form, as to decompose the Carleson sum it is also crucial that
the union is disjoint. This is easier to formalize by decomposing into successive terms, taking
advantage of disjointess at each step, instead of doing everything in one go. Still, we keep this
lemma as it corresponds to the blueprint, and the key steps of its proof will also be the key steps
when doing the successive decompositions.
-/
lemma antichain_decomposition : 𝔓pos (X := X) ∩ 𝔓₁ᶜ = ℜ₀ ∪ ℜ₁ ∪ ℜ₂ ∪ ℜ₃ := by
  sorry

/-- The subset `𝔏₀(k, n, l)` of `𝔏₀(k, n)`, given in Lemma 5.5.3.
  We use the name `𝔏₀'` in Lean. -/
def 𝔏₀' (k n l : ℕ) : Set (𝔓 X) := (𝔏₀ k n).minLayer l

/-- Logarithmic inequality used in the proof of Lemma 5.5.2. -/
lemma ceil_log2_le_floor_four_add_log2 {l : ℝ} (hl : 2 ≤ l) :
    ⌈Real.logb 2 ((l + 6 / 5) / 5⁻¹)⌉₊ ≤ ⌊4 + Real.logb 2 l⌋₊ := by
  sorry

open scoped Classical in
/-- The set `𝔒` in the proof of Lemma 5.5.2. -/
def 𝔒 (p' : 𝔓 X) (l : ℝ≥0) : Finset (𝔓 X) :=
  {p'' | 𝓘 p'' = 𝓘 p' ∧ ¬Disjoint (ball_(p') (𝒬 p') l) (Ω p'')}

lemma card_𝔒 (p' : 𝔓 X) {l : ℝ≥0} (hl : 2 ≤ l) : (𝔒 p' l).card ≤ ⌊2 ^ (4 * a) * l ^ a⌋₊ := by
  sorry

section

variable {p' : 𝔓 X} {l : ℝ≥0} (hl : 2 ≤ l)
  (qp' : 2 ^ (4 * a - n : ℤ) < l ^ (-a : ℤ) * volume (E₂ l p') / volume (𝓘 p' : Set X))
include hl qp'

omit hl in
lemma lt_quotient_rearrange :
    (2 ^ (4 * a) * l ^ a : ℝ≥0) * 2 ^ (-n : ℤ) < volume (E₂ l p') / volume (𝓘 p' : Set X) := by
  sorry

lemma l_upper_bound : l < 2 ^ n := by
  sorry

lemma exists_𝔒_with_le_quotient :
    ∃ b ∈ 𝔒 p' l, 2 ^ (-n : ℤ) < volume (E₁ b) / volume (𝓘 b : Set X) := by
  sorry

end

/-- Main part of Lemma 5.5.2. -/
lemma iUnion_L0' : ⋃ (l < n), 𝔏₀' (X := X) k n l = 𝔏₀ k n := by
  sorry

/-- Part of Lemma 5.5.2 -/
lemma pairwiseDisjoint_L0' : univ.PairwiseDisjoint (𝔏₀' (X := X) k n) := by
  sorry

/-- Part of Lemma 5.5.2 -/
lemma antichain_L0' : IsAntichain (· ≤ ·) (𝔏₀' (X := X) k n l) := by
  sorry

section L2Antichain

/-- Type synonym of `ℭ₁` to apply the `Preorder` of the proof of Lemma 5.5.3 on. -/
private def ℭ₁' (k n j : ℕ) : Type _ := ℭ₁ (X := X) k n j

open scoped Classical in
private instance : Fintype (ℭ₁' (X := X) k n j) := inferInstanceAs (Fintype (ℭ₁ k n j))

private instance : Preorder (ℭ₁' (X := X) k n j) where
  le x y := smul 200 x.1 ≤ smul 200 y.1
  le_refl := by simp
  le_trans _ _ _ xy yz := by
    change smul _ _ ≤ smul _ _ at xy yz ⊢
    exact xy.trans yz

/-- Lemma 5.5.3 -/
lemma antichain_L2 : IsAntichain (· ≤ ·) (𝔏₂ (X := X) k n j) := by
  sorry

end L2Antichain

/-- Part of Lemma 5.5.4 -/
lemma antichain_L1 : IsAntichain (· ≤ ·) (𝔏₁ (X := X) k n j l) := by
  sorry

/-- Part of Lemma 5.5.4 -/
lemma antichain_L3 : IsAntichain (· ≤ ·) (𝔏₃ (X := X) k n j l) := by
  sorry

/- Our goal is now to estimate `∫⁻ x in G \ G', ‖carlesonSum 𝔓₁ᶜ f x‖ₑ` by decomposing `𝔓₁ᶜ` as a
union of disjoint antichains. For this, we proceed step by step, isolating some antichains and
some sets that remain to be decomposed. After 4 steps, we will get a sum of integrals corresponding
to the (disjoint) decomposition in Lemma 5.5.1.
-/

/-- The Carleson sum over `𝔓₁ᶜ` and `𝔓pos ∩ 𝔓₁ᶜ` coincide at ae every point of `G \ G'`. -/
lemma carlesonSum_𝔓₁_compl_eq_𝔓pos_inter (f : X → ℂ) :
    ∀ᵐ x, x ∈ G \ G' → carlesonSum 𝔓₁ᶜ f x = carlesonSum (𝔓pos (X := X) ∩ 𝔓₁ᶜ) f x := by
  sorry

/-- The Carleson sum over `𝔓pos ∩ 𝔓₁ᶜ` can be decomposed as a sum over the intersections of this
set with various `ℭ k n`. -/
lemma carlesonSum_𝔓pos_eq_sum {f : X → ℂ} {x : X} :
    carlesonSum (𝔓pos (X := X) ∩ 𝔓₁ᶜ) f x =
      ∑ n ≤ maxℭ X, ∑ k ≤ n, carlesonSum (𝔓pos (X := X) ∩ 𝔓₁ᶜ ∩ ℭ k n) f x := by
  sorry

/-- In each set `ℭ k n`, the Carleson sum can be decomposed as a sum over `𝔏₀ k n` and over
various `ℭ₁ k n j`. -/
lemma carlesonSum_𝔓pos_inter_ℭ_eq_add_sum {f : X → ℂ} {x : X} (hkn : k ≤ n) :
    carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ ℭ k n) f x =
      carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔏₀ k n) f x
      + ∑ j ≤ 2 * n + 3, carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ ℭ₁ k n j) f x := by
  sorry

lemma carlesonSum_𝔓pos_inter_𝔏₀_eq_sum {f : X → ℂ} {x : X} :
    carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔏₀ k n) f x =
      ∑ l < n, carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔏₀' k n l) f x := by
  sorry

/-- In each set `ℭ₁ k n j`, the Carleson sum can be decomposed as a sum over `ℭ₂ k n j` and over
various `𝔏₁ k n j l`. -/
lemma carlesonSum_𝔓pos_inter_ℭ₁_eq_add_sum {f : X → ℂ} {x : X} :
    carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ ℭ₁ k n j) f x =
      carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ ℭ₂ k n j) f x
      + ∑ l ≤ Z * (n + 1), carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔏₁ k n j l) f x := by
  sorry

/-- In each set `ℭ₂ k n j`, the Carleson sum can be decomposed as a sum over `𝔏₂ k n j` and over
various `𝔏₃ k n j l`. -/
lemma carlesonSum_𝔓pos_inter_ℭ₂_eq_add_sum {f : X → ℂ} {x : X} (hkn : k ≤ n) (hj : j ≤ 2 * n + 3) :
    carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ ℭ₂ k n j) f x =
      carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔏₂ k n j) f x
      + ∑ l ≤ Z * (n + 1), carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔏₃ k n j l) f x := by
  sorry

/-- Putting together all the previous decomposition lemmas, one gets an estimate of the integral
of `‖carlesonSum 𝔓₁ᶜ f x‖ₑ` by a sum of integrals of the same form over various subsets of `𝔓`,
which are all antichains by design. -/
lemma lintegral_carlesonSum_𝔓₁_compl_le_sum_lintegral {f : X → ℂ} (h'f : Measurable f) :
    ∫⁻ x in G \ G', ‖carlesonSum 𝔓₁ᶜ f x‖ₑ ≤
        (∑ n ≤ maxℭ X, ∑ k ≤ n, ∑ l < n,
          ∫⁻ x in G \ G', ‖carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔏₀' k n l) f x‖ₑ)
      + (∑ n ≤ maxℭ X, ∑ k ≤ n, ∑ j ≤ 2 * n + 3, ∑ l ≤ Z * (n + 1),
          ∫⁻ x in G \ G', ‖carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔏₁ k n j l) f x‖ₑ)
      + (∑ n ≤ maxℭ X, ∑ k ≤ n, ∑ j ≤ 2 * n + 3,
          ∫⁻ x in G \ G', ‖carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔏₂ k n j) f x‖ₑ)
      + (∑ n ≤ maxℭ X, ∑ k ≤ n, ∑ j ≤ 2 * n + 3, ∑ l ≤ Z * (n + 1),
          ∫⁻ x in G \ G', ‖carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔏₃ k n j l) f x‖ₑ) := by
  sorry

/-- Custom version of the antichain operator theorem, in the specific form we need to handle
the various terms in the previous statement. -/
lemma lintegral_enorm_carlesonSum_le_of_isAntichain_subset_ℭ
    {f : X → ℂ} {𝔄 : Set (𝔓 X)} (hf : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (h'f : Measurable f)
    (hA : IsAntichain (· ≤ ·) 𝔄) (h'A : 𝔄 ⊆ ℭ k n) :
    ∫⁻ x in G \ G', ‖carlesonSum (𝔓pos ∩ 𝔓₁ᶜ ∩ 𝔄) f x‖ₑ
    ≤ C2_0_3 a nnq * 2 ^ (a + 3) * volume G ^ (1 - q⁻¹) * volume F ^ (q⁻¹)
      * 2 ^ (- ((q - 1) / (8 * a ^ 4) * n)) := by
  sorry

open scoped Nat

omit [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o] in
lemma lintegral_carlesonSum_𝔓₁_compl_le_sum_aux1 [ProofData a q K σ₁ σ₂ F G] {N : ℕ} :
    ∑ x ≤ N,
      (((12 + 8 * Z) * x ^ 0 + (19 + 20 * Z) * x ^ 1 + (7 + 16 * Z) * x ^ 2 + (4 * Z) * x ^ 3) *
        (2 : ℝ) ^ (-((q - 1) / (8 * ↑a ^ 4) * x : ℝ))) ≤ 2 ^ (28 * a + 20) / (q - 1) ^ 4 := by
  sorry

omit [TileStructure Q D κ S o] in
lemma lintegral_carlesonSum_𝔓₁_compl_le_sum_aux2 {N : ℕ} :
    ∑ x ≤ N, (((12 + 8 * Z) + (19 + 20 * Z) * x + (7 + 16 * Z) * x ^ 2 + (4 * Z) * x ^ 3) *
        (2 : ℝ≥0∞) ^ (-((q - 1) / (8 * ↑a ^ 4) * x : ℝ)))
    ≤ (2 : ℝ≥0∞) ^ (28 * a + 20) / (nnq - 1) ^ 4 := by
  sorry

/-- An optimized constant for Lemma 5.1.3. -/
def C5_1_3_optimized (a : ℕ) (q : ℝ≥0) := C2_0_3 a q * 2 ^ (29 * a + 23) / (q - 1) ^ 4

/-- The constant used in Lemma 5.1.3.
Has value `2 ^ (120 * a ^ 3) / (q - 1) ^ 5` in the blueprint. -/
def C5_1_3 (a : ℕ) (q : ℝ≥0) : ℝ≥0 := 2 ^ ((𝕔 + 8 + 𝕔 / 8) * a ^ 3) / (q - 1) ^ 5

omit [TileStructure Q D κ S o] in
lemma C5_1_3_pos : 0 < C5_1_3 a nnq := by
  sorry

omit [TileStructure Q D κ S o] in
lemma C5_1_3_optimized_le_C5_1_3 : C5_1_3_optimized a nnq ≤ C5_1_3 a nnq := by
  sorry

lemma forest_complement_optimized
    {f : X → ℂ} (hf : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (h'f : Measurable f) :
    ∫⁻ x in G \ G', ‖carlesonSum 𝔓₁ᶜ f x‖ₑ ≤
      C5_1_3_optimized a nnq * volume G ^ (1 - q⁻¹) * volume F ^ q⁻¹ := by
  sorry

/-- Lemma 5.1.3, proving the bound on the integral of the Carleson sum over all leftover tiles
which do not fit in a forest. It follows from a careful grouping of these tiles into finitely
many antichains. -/
lemma forest_complement {f : X → ℂ} (hf : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (h'f : Measurable f) :
    ∫⁻ x in G \ G', ‖carlesonSum 𝔓₁ᶜ f x‖ₑ ≤
    C5_1_3 a nnq * volume G ^ (1 - q⁻¹) * volume F ^ q⁻¹ := by
  sorry
