module

public import Carleson.Discrete.Defs
public import Carleson.ToMathlib.HardyLittlewood

@[expose] public section

open MeasureTheory Measure NNReal Metric Set
open scoped ENNReal

noncomputable section

open scoped ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G]

variable (X) in
/-- The constant in Lemma 5.2.9, with value `D ^ (1 - κ * Z * (n + 1))` -/
@[nolint unusedArguments]
def C5_2_9 [ProofData a q K σ₁ σ₂ F G] (n : ℕ) : ℝ≥0 := D ^ (1 - κ * Z * (n + 1))

/-- A rearrangement for Lemma 5.2.9 that does not require the tile structure. -/
lemma third_exception_rearrangement :
    (∑' n, ∑' k, if k ≤ n then ∑' (j : ℕ),
      C5_2_9 X n * 2 ^ (9 * a - j : ℤ) * 2 ^ (n + k + 3) * volume G else 0) =
    ∑' k, 2 ^ (9 * a + 4 + 2 * k) * D ^ (1 - κ * Z * (k + 1)) * volume G *
      ∑' n, if k ≤ n then (2 * D ^ (-κ * Z) : ℝ≥0∞) ^ (n - k : ℝ) else 0 := by
  sorry

variable [TileStructure Q D κ S o] {k n j l : ℕ} {p p' u u' : 𝔓 X} {x : X}

/-! ## Section 5.2 and Lemma 5.1.1 -/

section first_exception

open ENNReal

set_option backward.isDefEq.respectTransparency false in
/-- Lemma 5.2.1 -/
lemma first_exception' : volume (G₁ : Set X) ≤ 2 ^ (- 5 : ℤ) * volume G := by
  sorry

lemma first_exception : volume (G₁ : Set X) ≤ 2 ^ (- 4 : ℤ) * volume G := by
  sorry

end first_exception

/-- Lemma 5.2.2 -/
lemma dense_cover (k : ℕ) : volume (⋃ i ∈ 𝓒 (X := X) k, (i : Set X)) ≤ 2 ^ (k + 1) * volume G := by
  sorry

/-- Lemma 5.2.3 -/
lemma pairwiseDisjoint_E1 : (𝔐 (X := X) k n).PairwiseDisjoint E₁ := by
  sorry

open scoped Classical in
/-- Lemma 5.2.4 -/
lemma dyadic_union (hx : x ∈ setA l k n) : ∃ i : Grid X, x ∈ i ∧ (i : Set X) ⊆ setA l k n := by
  sorry

lemma iUnion_MsetA_eq_setA : ⋃ i ∈ MsetA (X := X) l k n, ↑i = setA (X := X) l k n := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Equation (5.2.7) in the proof of Lemma 5.2.5. -/
lemma john_nirenberg_aux1 {L : Grid X} (mL : L ∈ Grid.maxCubes (MsetA l k n))
    (mx : x ∈ setA (l + 1) k n) (mx₂ : x ∈ L) : 2 ^ (n + 1) ≤
    stackSize { q ∈ 𝔐 (X := X) k n | 𝓘 q ≤ L} x := by
  sorry

/-- Equation (5.2.11) in the proof of Lemma 5.2.5. -/
lemma john_nirenberg_aux2 {L : Grid X} (mL : L ∈ Grid.maxCubes (MsetA l k n)) :
    2 * volume (setA (X := X) (l + 1) k n ∩ L) ≤ volume (L : Set X) := by
  sorry

/-- Lemma 5.2.5 -/
lemma john_nirenberg : volume (setA (X := X) l k n) ≤ 2 ^ (k + 1 - l : ℤ) * volume G := by
  sorry

/-- Lemma 5.2.6 -/
lemma second_exception : volume (G₂ (X := X)) ≤ 2 ^ (-2 : ℤ) * volume G := by
  sorry

section TopTiles

open scoped Classical in
/-- The volume of a "layer" in the key function of Lemma 5.2.7. -/
def layervol (k n : ℕ) (t : ℝ) : ℝ≥0∞ :=
  volume {x | t ≤ ∑ m with m ∈ 𝔐 (X := X) k n,
    (𝓘 m : Set X).indicator (1 : X → ℝ) x}

lemma indicator_sum_eq_natCast {s : Finset (𝔓 X)} :
    ∑ m ∈ s, (𝓘 m : Set X).indicator (1 : X → ℝ) x =
    Nat.cast (∑ m ∈ s, (𝓘 m : Set X).indicator (1 : X → ℕ) x) := by
  sorry

open scoped Classical in
lemma layervol_eq_zero_of_lt {t : ℝ} (ht : (𝔐 (X := X) k n).toFinset.card < t) :
    layervol (X := X) k n t = 0 := by
  sorry

lemma lintegral_Ioc_layervol_one {l : ℕ} :
    ∫⁻ t in Ioc (l : ℝ) (l + 1), layervol (X := X) k n t = layervol (X := X) k n (l + 1) := by
  sorry

lemma antitone_layervol : Antitone fun t ↦ layervol (X := X) k n t := by
  sorry

lemma lintegral_Ioc_layervol_le {a b : ℕ} : ∫⁻ t in Ioc (a : ℝ) b, layervol (X := X) k n t ≤
    (b - a : ℕ) * layervol (X := X) k n (a + 1) := by
  sorry

open scoped Classical in
lemma top_tiles_aux : ∑ m with m ∈ 𝔐 (X := X) k n, volume (𝓘 m : Set X) =
    ∫⁻ t in Ioc 0 ((𝔐 (X := X) k n).toFinset.card * 2 ^ (n + 1) : ℝ), layervol (X := X) k n t := by
  sorry

open scoped Classical in
/-- Lemma 5.2.7 -/
lemma top_tiles : ∑ m with m ∈ 𝔐 (X := X) k n, volume (𝓘 m : Set X) ≤
    2 ^ (n + k + 3) * volume G := by
  sorry

end TopTiles

/-! Definition of function `𝔘(m)` used in the proof of Lemma 5.2.8, and some properties of `𝔘(m)` -/
section 𝔘

open Finset

variable (k) (n) (j) (x)
open scoped Classical in
/-- The function `𝔘(m)` used in the proof of Lemma 5.2.8 -/
def 𝔘 (m : 𝔓 X) := (𝔘₁ k n j).toFinset.filter (fun u ↦ x ∈ 𝓘 u ∧ smul 100 u ≤ smul 1 m)

-- Ball that covers the image of `𝒬`. Radius chosen for convenience with `BallsCoverBalls.pow_mul`
private def big_ball (m : 𝔓 X) (u : 𝔓 X) := ball_(u) (𝒬 m) (2 ^ 9 * 0.2)

variable {k} {n} {j} {x}
variable {x : X} {m u u' u'' : 𝔓 X}
variable (hu : u ∈ 𝔘 k n j x m) (hu' : u' ∈ 𝔘 k n j x m) (hu'' : u'' ∈ 𝔘 k n j x m)

include hu in
private lemma x_mem_𝓘u : x ∈ (𝓘 u) := by
  sorry

set_option backward.isDefEq.respectTransparency false in
include hu in
private lemma 𝒬m_mem_ball : 𝒬 m ∈ ball_(u) (𝒬 u) 100 := by
  sorry

include hu hu' in
private lemma 𝓘_not_lt_𝓘 : ¬𝓘 u < 𝓘 u' := by
  sorry

include hu hu' in
private lemma 𝓘_eq_𝓘 : 𝓘 u = 𝓘 u' := by
  sorry

include hu hu' in
private lemma ball_eq_ball : ball_(u) = ball_(u') := by
  sorry

include hu hu' hu'' in
private lemma disjoint_balls (h : u' ≠ u'') :
    Disjoint (ball_(u) (𝒬 u') 0.2) (ball_(u) (𝒬 u'') 0.2) := by
  sorry

set_option backward.isDefEq.respectTransparency false in
include hu hu' in
private lemma mem_big_ball : 𝒬 u' ∈ big_ball m u := by
  sorry

open scoped Classical in
include hu in
private lemma subset_big_ball (f : Θ X) (hf : f ∈ (𝔘 k n j x m).image 𝒬) : f ∈ big_ball m u := by
  sorry

variable (m) (u : 𝔓 X) in
private lemma balls_cover_big_ball : CoveredByBalls (big_ball m u) (defaultA a ^ 9) 0.2 := by
  sorry

private lemma 𝒬_injOn_𝔘m : InjOn 𝒬 (SetLike.coe (𝔘 k n j x m)) := by
  sorry

set_option backward.isDefEq.respectTransparency false in
private lemma card_𝔘m_le : (𝔘 k n j x m).card ≤ (defaultA a) ^ 9 := by
  sorry

variable (k n j) (x) in
open scoped Classical in
private def 𝔐' (u : 𝔓 X) := (𝔐 k n).toFinset.filter (fun m ↦ smul 100 u ≤ smul 1 m)

-- Interchange the summations in the proof of Lemma 5.2.8
open scoped Classical in
private lemma interchange :
    ((𝔘₁ k n j).toFinset.filter (x ∈ 𝓘 ·)).sum (fun u ↦ (𝔐' k n u).sum
    (fun m ↦ (𝓘 m : Set X).indicator (1 : X → ℝ) x)) =
    (𝔐 k n).toFinset.sum (fun m ↦ (𝔘 k n j x m).sum
    (fun _ ↦ (𝓘 m : Set X).indicator (1 : X → ℝ) x)) := by
  sorry

end 𝔘

-- Inequality (5.2.20) in the proof of Lemma 5.2.8
open scoped Classical in
private lemma indicator_le : ∀ u ∈ (𝔘₁ k n j).toFinset.filter (x ∈ 𝓘 ·),
    (𝓘 u : Set X).indicator 1 x ≤ (2 : ℝ) ^ (-j : ℤ) * stackSize (𝔐' k n u) x := by
  sorry

open Finset in
/-- Lemma 5.2.8 -/
lemma tree_count :
    stackSize (𝔘₁ k n j) x ≤ (2 : ℝ) ^ (9 * a - j : ℤ) * stackSize (𝔐 k n) x := by
  sorry

/-- Lemma 5.2.9 -/
lemma boundary_exception {u : 𝔓 X} :
    volume (⋃ i ∈ 𝓛 (X := X) n u, (i : Set X)) ≤ C5_2_9 X n * volume (𝓘 u : Set X) := by
  sorry

lemma third_exception_aux :
    volume (⋃ p ∈ 𝔏₄ (X := X) k n j, (𝓘 p : Set X)) ≤
    C5_2_9 X n * 2 ^ (9 * a - j : ℤ) * 2 ^ (n + k + 3) * volume G := by
  sorry

/-- Lemma 5.2.10 -/
lemma third_exception : volume (G₃ (X := X)) ≤ 2 ^ (-4 : ℤ) * volume G := by
  sorry

/-- Lemma 5.1.1 -/
lemma exceptional_set : volume (G' : Set X) ≤ 2 ^ (-1 : ℤ) * volume G := by
  sorry
