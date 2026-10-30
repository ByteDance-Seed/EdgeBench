module

public import Carleson.Antichain.Basic

/-!
# 6.3. Proof of the Antichain Tile Count Lemma

This file contains the proofs of lemmas 6.3.1, 6.3.2, 6.3.3, 6.3.4 and 6.1.6 from the blueprint.

## Main results
- `Antichain.tile_reach`: Lemma 6.3.1.
- `Antichain.stack_density`: Lemma 6.3.2.
- `Antichain.local_antichain_density` : Lemma 6.3.3.
- `Antichain.global_antichain_density` : Lemma 6.3.4.
- `Antichain.tile_count`: Lemma 6.1.6.
-/

@[expose] public section

macro_rules | `(tactic |gcongr_discharger) => `(tactic | with_reducible assumption)

noncomputable section

open scoped ENNReal NNReal ShortVariables

open MeasureTheory Metric Set

namespace Antichain

variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]

/-- Lemma 6.3.1. -/
-- hp is eq. 6.3.1, hp' is eq. 6.3.2.
lemma tile_reach {ϑ : Θ X} {N : ℕ} {p p' : 𝔓 X} (hp : dist_(p) (𝒬 p) ϑ ≤ 2 ^ N)
    (hp' : dist_(p') (𝒬 p') ϑ ≤ 2 ^ N) (hI : 𝓘 p ≤ 𝓘 p') (hs : 𝔰 p < 𝔰 p') :
    smul (2^(N + 2)) p ≤ smul (2^(N + 2)) p' := by
  sorry -- uses h34

/-- Def 6.3.15. -/
def 𝔄_aux (𝔄 : Set (𝔓 X)) (ϑ : Θ X) (N : ℕ) : Set (𝔓 X) :=
  {p ∈ 𝔄 | 1 + dist_(p) (𝒬 p) ϑ ∈ Ico (2 ^ N) (2 ^ (N + 1))}

open Classical in
lemma pairwiseDisjoint_𝔄_aux {𝔄 : Set (𝔓 X)} {ϑ : Θ X} :
    univ.PairwiseDisjoint (fun N ↦ (𝔄_aux 𝔄 ϑ N).toFinset) := by
  sorry

open Classical in
lemma biUnion_𝔄_aux {𝔄 : Set (𝔓 X)} {ϑ : Θ X} :
    ∃ N, (Finset.range N).biUnion (fun N ↦ (𝔄_aux 𝔄 ϑ N).toFinset) = 𝔄.toFinset := by
  sorry

open Metric

open scoped Classical in
/-- Lemma 6.3.2. -/
lemma stack_density (𝔄 : Set (𝔓 X)) (ϑ : Θ X) (N : ℕ) (L : Grid X) :
    ∑ p ∈ 𝔄_aux 𝔄 ϑ N with 𝓘 p = L, volume (E p ∩ G) ≤
      2^(a * (N + 5)) * dens₁ (𝔄 : Set (𝔓 X)) * volume (L : Set X) := by
  sorry

open Classical in
/-- We prove inclusion 6.3.24 for every `p ∈ (𝔄_aux 𝔄 ϑ N)` with `𝔰 p' < 𝔰 p` such that
 `(𝓘 p : Set X) ∩ (𝓘 p') ≠ ∅`. The variable `p'` corresponds to `𝔭_ϑ` in the blueprint. -/
lemma Ep_inter_G_inter_Ip'_subset_E2 {𝔄 : Set (𝔓 X)} (ϑ : Θ X) (N : ℕ) {p p' : 𝔓 X}
    (hpin : p ∈ (𝔄_aux 𝔄 ϑ N).toFinset) (hp' : ϑ ∈ ball_(p') (𝒬 p') (2 ^ (N + 1)))
    (hs : 𝔰 p' < 𝔰 p) (h𝓘 : ((𝓘 p' : Set X) ∩ (𝓘 p)).Nonempty) :
    E p ∩ G ∩ ↑(𝓘 p') ⊆ E₂ (2^(N + 3)) p' := by
  sorry

-- p' is 𝔭_ϑ in the blueprint
open Classical in
/-- Lemma 6.3.3. -/
lemma local_antichain_density {𝔄 : Set (𝔓 X)} (h𝔄 : IsAntichain (· ≤ ·) 𝔄) (ϑ : Θ X) (N : ℕ)
    {p' : 𝔓 X} (hp' : ϑ ∈ ball_(p') (𝒬 p') (2 ^ (N + 1))) :
    ∑ p ∈ 𝔄_aux 𝔄 ϑ N with 𝔰 p' < 𝔰 p, volume (E p ∩ G ∩ 𝓘 p') ≤
      volume (E₂ (2 ^ (N + 3)) p') := by
  sorry

/-- The constant appearing in Lemma 6.3.4. -/
def C6_3_4 (a N : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 1) * a ^ 3 + N * a)

/-- Auxiliary constant for Lemma 6.3.4. -/
def C6_3_4' (a N : ℕ) : ℝ≥0 := ((2 ^ (a * (N + 5)) + 2 ^ (a * N + a * 3)) * 2 ^ (𝕔 * a^3 + 5 * a))

variable (𝔄 : Set (𝔓 X)) (ϑ : range (Q (X := X))) (N : ℕ)

/-- The set `𝔄'` defined in Lemma 6.3.4. -/
def 𝔄' : Set (𝔓 X) := {p ∈ 𝔄_aux 𝔄 ϑ N | ((𝓘 p : Set X) ∩ G) ≠ ∅ ∧ 𝔰 p > -S}

/-- The set `𝔄_-S` defined in Lemma 6.3.4. -/
def 𝔄_min : Set (𝔓 X) := {p ∈ 𝔄_aux 𝔄 ϑ N | ((𝓘 p : Set X) ∩ G) ≠ ∅ ∧ 𝔰 p = -S}

open Classical in
private lemma 𝔄_aux_sum_splits :
    ∑ p ∈ (𝔄_aux 𝔄 ϑ N).toFinset, volume (E p ∩ G) =
      ∑ p ∈ (𝔄' 𝔄 ϑ N).toFinset, volume (E p ∩ G) +
        ∑ p ∈ (𝔄_min 𝔄 ϑ N).toFinset, volume (E p ∩ G) := by
  sorry

/-- The set `𝓛_{-S}` defined in Lemma 6.3.4. -/
def 𝓛_min : Set (Grid X) := {I : Grid X | ∃ (p : 𝔄_min 𝔄 ϑ N), I = 𝓘 (p : 𝔓 X)}

-- Ineq. 6.3.26
open Classical in
private lemma 𝔄_min_sum_le :
    ∑ p ∈ (𝔄_min 𝔄 ϑ N).toFinset, volume (E p ∩ G) ≤
      2 ^ (a * (N + 5)) * dens₁ (𝔄 : Set (𝔓 X)) * volume (⋃ p ∈ 𝔄, (𝓘 p : Set X)) := by
  sorry

/-- The set `𝓛` defined in Lemma 6.3.4. -/
def 𝓛 : Set (Grid X) := {I : Grid X | (∃ (p : 𝔄' 𝔄 ϑ N), I ≤ 𝓘 (p : 𝔓 X)) ∧
    (∀ (p : 𝔄' 𝔄 ϑ N), 𝓘 (p : 𝔓 X) ≤ I → 𝔰 (p : 𝔓 X) = - S)}

-- Ineq. 6.3.27
lemma I_p_subset_union_L (p : 𝔄' 𝔄 ϑ N) : (𝓘 (p : 𝔓 X) : Set X) ⊆ ⋃ (L ∈ 𝓛 𝔄 ϑ N), L := by
  sorry

-- Ineq. 6.3.28
lemma union_L_eq_union_I_p : ⋃ (L ∈ 𝓛 𝔄 ϑ N), L = ⋃ (p ∈ 𝔄' 𝔄 ϑ N), (𝓘 (p : 𝔓 X) : Set X) := by
  sorry

/-- The set `𝓛*` defined in Lemma 6.3.4. -/
def 𝓛' : Set (Grid X) := {I : Grid X | Maximal (· ∈ 𝓛 𝔄 ϑ N) I}

open Classical in
lemma pairwiseDisjoint_𝓛' :
    ((𝓛' 𝔄 ϑ N).toFinset : Set (Grid X)).PairwiseDisjoint (fun I ↦ (I : Set X)) := by
  sorry

-- Eq. 6.3.29
lemma union_L'_eq_union_I_p : ⋃ (L ∈ 𝓛' 𝔄 ϑ N), L = ⋃ (p ∈ 𝔄' 𝔄 ϑ N), (𝓘 (p : 𝔓 X) : Set X) := by
  sorry

variable {𝔄 ϑ N}

variable (𝔄 ϑ N) in private def SL (L : Grid X) : Set (𝔓 X) :=
  {p : 𝔓 X | p ∈ 𝔄' 𝔄 ϑ N ∧ L ≤ 𝓘 (p : 𝔓 X)}

section hL

variable {L : Grid X} (hL : L ∈ 𝓛' 𝔄 ϑ N)

include L hL

private lemma exists_p'_ge_L : ∃ (p : 𝔄' 𝔄 ϑ N), L ≤ 𝓘 (p : 𝔓 X) := by
  sorry

open Classical in
private lemma SL_nonempty : (SL 𝔄 ϑ N L).toFinset.Nonempty := by
  sorry

open Classical in
/-- `p'` in the blueprint. -/
private def p' : 𝔓 X :=(Finset.exists_minimalFor 𝔰 (SL 𝔄 ϑ N L).toFinset (SL_nonempty hL)).choose

open Classical in
private lemma p'_mem : p' hL ∈ (SL 𝔄 ϑ N L).toFinset := by
  sorry

private lemma L_le_I_p' : L ≤ 𝓘 (p' hL : 𝔓 X) := by
  sorry

private lemma not_I_p'_le_L : ¬ 𝓘 (p' hL) ≤ L := by
  sorry

private lemma s_L_le_s_p' : s L < 𝔰 (p' hL) := by
  sorry

lemma exists_larger_grid : ∃ (L' : Grid X), L ≤ L' ∧ s L' = s L + 1 := by
  sorry

/-- The `L'` introduced in the proof of Lemma 6.3.4. -/
def L' : Grid X := (exists_larger_grid hL).choose

lemma L_le_L' : L ≤ L' hL := by
  sorry

lemma s_L'_eq : s (L' hL) = s L + 1 := by
  sorry

lemma c_L_mem : c L ∈ L' hL := by
  sorry

private lemma L'_not_mem : ¬ L' hL ∈ 𝓛 𝔄 ϑ N := by
  sorry

private lemma L'_le_I_p' : L' hL ≤ 𝓘 (p' hL : 𝔓 X) := by
  sorry

private lemma exists_p''_le_L' : ∃ (p : 𝔓 X), p ∈ 𝔄' 𝔄 ϑ N ∧ 𝓘 p ≤ L' hL := by
  sorry

/-- p'' in the blueprint -/
@[no_expose] def p'' : 𝔓 X := (exists_p''_le_L' hL).choose

lemma p''_mem : p'' hL ∈ 𝔄' 𝔄 ϑ N := by
  sorry

lemma I_p''_le_L' : 𝓘 (p'' hL) ≤ L' hL := by
  sorry

private lemma exists_pΘ_eq_L' : ∃! (p : 𝔓 X), 𝓘 p = L' hL ∧ ϑ.val ∈ Ω p := by
  sorry

/-- p_Θ in the blueprint -/
@[no_expose] def pΘ : 𝔓 X := by
  classical exact if 𝓘 (p'' hL) = L' hL then p'' hL else (exists_pΘ_eq_L' hL).choose

lemma I_pΘ_eq_L' : 𝓘 (pΘ hL) = L' hL := by
  sorry

lemma theta_mem_Omega_pΘ (h : ¬ 𝓘 (p'' hL) = L' hL) : ϑ.val ∈ Ω (pΘ hL)  := by
  sorry

lemma pΘ_unique (h : ¬ 𝓘 (p'' hL) = L' hL) :
    ∀ (y : 𝔓 X), (fun p ↦ 𝓘 p = L' hL ∧ ↑ϑ ∈ Ω p) y → y = (pΘ hL) := by
  sorry

-- Eq. 6.3.35
private lemma eq_6_3_35 : ϑ.val ∈ ball_(p'' hL) (𝒬 (p'' hL)) (2 ^ (N + 1)) := by
  sorry

-- Eq. 6.3.37
private lemma eq_6_3_37 : ϑ.val ∈ ball_(pΘ hL) (𝒬 (pΘ hL)) (2 ^ (N + 1)) := by
  sorry

-- Ineq. 6.3.36
private lemma ineq_6_3_36 : smul (2^(N + 3)) (p'' hL) ≤ smul (2^(N + 3)) (pΘ hL) := by
  sorry

-- Ineq. 6.3.38
private lemma ineq_6_3_38 : volume (E₂ (2 ^ (N + 3)) (pΘ hL)) ≤
      2 ^ (a * N + a * 3) * (dens₁ (𝔄 : Set (𝔓 X)) * volume (L' hL : Set X)) := by
  sorry

-- Ineq. 6.3.39
open Classical in
private lemma ineq_6_3_39 (h𝔄 : IsAntichain (· ≤ ·) 𝔄) :
    ∑ p ∈ 𝔄' 𝔄 ϑ N with ¬𝓘 p = L' hL, volume (E p ∩ G ∩ L) ≤
      volume (E₂ (2 ^ (N + 3)) (pΘ hL)) := by
  sorry

-- Ineq. 6.3.41
private lemma volume_L'_le :
    volume (L' hL : Set X) ≤ 2 ^ (𝕔 * a^3 + 5*a) * volume (L : Set X) := by
  sorry

-- Ineq. 6.3.30
open Classical in
lemma global_antichain_density_aux (h𝔄 : IsAntichain (· ≤ ·) 𝔄) :
    ∑ (p ∈ 𝔄' 𝔄 ϑ N), volume (E p ∩ G ∩ L) ≤
      (C6_3_4' a N) * dens₁ (𝔄 : Set (𝔓 X)) * volume (L : Set X) := by
  sorry

end hL

variable (𝔄 ϑ N)

open Classical in
private lemma volume_union_I_p_eq_sum :
    volume (⋃ (p ∈ 𝔄' 𝔄 ϑ N), (𝓘 p : Set X)) = ∑ (L ∈ 𝓛' 𝔄 ϑ N), volume (L : Set X) := by
  sorry

open Classical in
private lemma lhs' : ∑ (p ∈ (𝔄' 𝔄 ϑ N).toFinset), volume (E p ∩ G) =
    (∑ (L ∈ (𝓛' 𝔄 ϑ N).toFinset), ∑ (p ∈ (𝔄' 𝔄 ϑ N).toFinset), volume (E p ∩ G ∩ L)) := by
  sorry

open Classical in
private lemma lhs : ∑ (p ∈ (𝔄_aux 𝔄 ϑ N).toFinset), volume (E p ∩ G) =
    (∑ (L ∈ (𝓛' 𝔄 ϑ N).toFinset), ∑ (p ∈ (𝔄' 𝔄 ϑ N).toFinset), volume (E p ∩ G ∩ L)) +
    ∑ p ∈ (𝔄_min 𝔄 ϑ N).toFinset, volume (E p ∩ G) := by
  sorry

private lemma le_C6_3_4 (ha : 4 ≤ a) :
    (((2 : ℝ≥0∞) ^ (a * (N + 5)) + 2 ^ (a * N + a * 3)) * 2 ^ (𝕔 * a ^ 3 + 5 * a)) +
      2 ^ (a * (N + 5)) ≤ C6_3_4 a N := by
  sorry

open Classical in
/-- Lemma 6.3.4. -/
lemma global_antichain_density {𝔄 : Set (𝔓 X)} (h𝔄 : IsAntichain (· ≤ ·) 𝔄) (ϑ : range Q) (N : ℕ) :
    ∑ p ∈ (𝔄_aux 𝔄 ϑ.val N).toFinset, volume (E p ∩ G) ≤
      C6_3_4 a N * dens₁ (𝔄 : Set (𝔓 X)) * volume (⋃ p ∈ 𝔄, (𝓘 p : Set X)) := by
  sorry

/-- `p` in Lemma 6.1.6. We append a subscript `₆` to keep `p` available for tiles. -/
def p₆ (a : ℕ) : ℝ := 4 * a ^ 4

/-- `p'` in the proof of Lemma 6.1.4, the Hölder conjugate exponent of `p₆`. -/
def q₆ (a : ℕ) : ℝ := (1 - (p₆ a)⁻¹)⁻¹

lemma p₆_ge_1024 (a4 : 4 ≤ a) : 1024 ≤ p₆ a := by
  sorry

lemma one_lt_p₆ (a4 : 4 ≤ a) : 1 < p₆ a := by
  sorry

lemma p₆_pos (a4 : 4 ≤ a) : 0 < p₆ a := by
  sorry

lemma holderConjugate_p₆ (a4 : 4 ≤ a) : (p₆ a).HolderConjugate (q₆ a) := by
  sorry

lemma q₆_le_superparticular (a4 : 4 ≤ a) : q₆ a ≤ 1024 / 1023 := by
  sorry

lemma one_lt_q₆ (a4 : 4 ≤ a) : 1 < q₆ a := by
  sorry

lemma q₆_pos (a4 : 4 ≤ a) : 0 < q₆ a := by
  sorry

/-- A very involved bound needed for Lemma 6.1.4. -/
lemma C2_0_6_q₆_le (a4 : 4 ≤ a) : C2_0_6 (defaultA a) (q₆ a).toNNReal 2 ≤ 2 ^ (a + 2) := by
  sorry

open Classical in
lemma tile_count_aux {𝔄 : Set (𝔓 X)} (h𝔄 : IsAntichain (· ≤ ·) 𝔄) (ϑ : range (Q (X := X)))
    {n : ℕ} : eLpNorm (fun x ↦ ∑ p ∈ 𝔄_aux 𝔄 ϑ n, (2 : ℝ) ^ (-n * (2 * a ^ 2 + a ^ 3 : ℝ)⁻¹) *
      (E p).indicator 1 x * G.indicator 1 x) (ENNReal.ofReal (p₆ a)) volume ≤
    (2 ^ ((𝕔 + 1) * a ^ 3 - n : ℝ)) ^ (p₆ a)⁻¹ * dens₁ 𝔄 ^ (p₆ a)⁻¹ *
    volume (⋃ p ∈ 𝔄, (𝓘 p : Set X)) ^ (p₆ a)⁻¹ := by
  sorry

/-- The constant appearing in Lemma 6.1.6. -/
def C6_1_6 (a : ℕ) : ℝ≥0 := 2 ^ (5 * a)

lemma le_C6_1_6 (a4 : 4 ≤ a) :
    (2 : ℝ≥0∞) ^ ((𝕔 + 1) * a ^ 3 / p₆ a) * ∑ n ∈ Finset.range N, (2 ^ (-(p₆ a)⁻¹)) ^ n ≤
      C6_1_6 a := by
  sorry

open Classical in
/-- Lemma 6.1.6. -/
lemma tile_count {𝔄 : Set (𝔓 X)} (h𝔄 : IsAntichain (· ≤ ·) 𝔄) (ϑ : range (Q (X := X))) :
    eLpNorm (fun x ↦ ∑ p with p ∈ 𝔄, (1 + edist_(p) (𝒬 p) ϑ.val) ^ (-(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹) *
      (E p).indicator 1 x * G.indicator 1 x) (ENNReal.ofReal (p₆ a)) volume ≤
    C6_1_6 a * dens₁ 𝔄 ^ (p₆ a)⁻¹ * volume (⋃ p ∈ 𝔄, (𝓘 p : Set X)) ^ (p₆ a)⁻¹ := by
  sorry

end Antichain
