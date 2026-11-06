module

public import Carleson.TileStructure

public section

open Set MeasureTheory Metric Function Complex Bornology
open scoped NNReal ENNReal ComplexConjugate
noncomputable section

open scoped ShortVariables
variable {X : Type*} [PseudoMetricSpace X] {a : ℕ} {q : ℝ} {K : X → X → ℂ}
  {σ₁ σ₂ : X → ℤ} {F G : Set X} [ProofData a q K σ₁ σ₂ F G]
variable [TileStructure Q D κ S o] {u u' p p' : 𝔓 X} {f g : Θ X}
  {C C' : Set (𝔓 X)} {x x' : X}

namespace TileStructure

variable (X) in
/-- An `n`-forest -/
structure Forest (n : ℕ) where
  𝔘 : Set (𝔓 X)
  /-- The value of `𝔗 u` only matters when `u ∈ 𝔘`. -/
  𝔗 : 𝔓 X → Set (𝔓 X)
  nonempty' {u : _} (hu : u ∈ 𝔘) : (𝔗 u).Nonempty
  ordConnected' {u : _} (hu : u ∈ 𝔘) : OrdConnected (𝔗 u) -- (2.0.33)
  𝓘_ne_𝓘' {u : _} (hu : u ∈ 𝔘) {p} (hp : p ∈ 𝔗 u) : 𝓘 p ≠ 𝓘 u
  smul_four_le' {u : _} (hu : u ∈ 𝔘) {p} (hp : p ∈ 𝔗 u) : smul 4 p ≤ smul 1 u -- (2.0.32)
  stackSize_le' {x : _} : stackSize 𝔘 x ≤ 2 ^ n -- (2.0.34), we formulate this a bit differently.
  dens₁_𝔗_le' {u : _} (hu : u ∈ 𝔘) : dens₁ (𝔗 u) ≤ 2 ^ (4 * (a : ℝ) - n + 1) -- (2.0.35)
  lt_dist' {u u' : _} (hu : u ∈ 𝔘) (hu' : u' ∈ 𝔘) (huu' : u ≠ u') {p} (hp : p ∈ 𝔗 u')
    (h : 𝓘 p ≤ 𝓘 u) : 2 ^ (Z * (n + 1)) < dist_(p) (𝒬 p) (𝒬 u) -- (2.0.36)
  ball_subset' {u : _} (hu : u ∈ 𝔘) {p} (hp : p ∈ 𝔗 u) : ball (𝔠 p) (8 * D ^ 𝔰 p) ⊆ 𝓘 u -- (2.0.37)

namespace Forest

variable {n : ℕ} (t : Forest X n)

instance : CoeHead (Forest X n) (Set (𝔓 X)) := ⟨Forest.𝔘⟩
instance : Membership (𝔓 X) (Forest X n) := ⟨fun t x ↦ x ∈ (t : Set (𝔓 X))⟩
instance : CoeFun (Forest X n) (fun _ ↦ 𝔓 X → Set (𝔓 X)) := ⟨fun t x ↦ t.𝔗 x⟩

@[simp] lemma mem_mk (n 𝔘 𝔗 a b c d e f g h) (p : 𝔓 X) :
    p ∈ Forest.mk (n := n) 𝔘 𝔗 a b c d e f g h ↔ p ∈ 𝔘 := by
  sorry

@[simp] lemma mem_𝔘 : u ∈ t.𝔘 ↔ u ∈ t := by
  sorry
@[simp] lemma mem_𝔗 : p ∈ t.𝔗 u ↔ p ∈ t u := by
  sorry

lemma nonempty (hu : u ∈ t) : (t u).Nonempty := by
  sorry
lemma ordConnected (hu : u ∈ t) : OrdConnected (t u) := by
  sorry
lemma 𝓘_ne_𝓘 (hu : u ∈ t) (hp : p ∈ t u) : 𝓘 p ≠ 𝓘 u := by
  sorry
lemma smul_four_le (hu : u ∈ t) (hp : p ∈ t u) : smul 4 p ≤ smul 1 u := by
  sorry
lemma stackSize_le : stackSize t x ≤ 2 ^ n := by
  sorry
lemma dens₁_𝔗_le (hu : u ∈ t) : dens₁ (t u) ≤ 2 ^ (4 * (a : ℝ) - n + 1) := by
  sorry
lemma lt_dist (hu : u ∈ t) (hu' : u' ∈ t) (huu' : u ≠ u') {p} (hp : p ∈ t u') (h : 𝓘 p ≤ 𝓘 u) :
    2 ^ (Z * (n + 1)) < dist_(p) (𝒬 p) (𝒬 u) := by
  sorry
lemma ball_subset (hu : u ∈ t) (hp : p ∈ t u) : ball (𝔠 p) (8 * D ^ 𝔰 p) ⊆ 𝓘 u := by
  sorry

-- Used in the proof of Lemma 7.1.4
variable {t} in
lemma ball_subset_of_mem_𝓘 (hu : u ∈ t) {p : 𝔓 X} (hp : p ∈ t u) {x : X} (hx : x ∈ 𝓘 p) :
    ball x (4 * D ^ (𝔰 p)) ⊆ 𝓘 u := by
  sorry

lemma 𝓘_le_𝓘 (hu : u ∈ t) (hp : p ∈ t u) : 𝓘 p ≤ 𝓘 u := by
  sorry

lemma cball_subset_cball (hu : u ∈ t) (hp : p ∈ t u) : ball_(u) (𝒬 u) 1 ⊆ ball_(p) (𝒬 p) 4 := by
  sorry

lemma 𝒬_mem_cball (hu : u ∈ t) (hp : p ∈ t u) : 𝒬 u ∈ ball_(p) (𝒬 p) 4 := by
  sorry

lemma dist_lt_four (hu : u ∈ t) (hp : p ∈ t u) : dist_(p) (𝒬 p) (𝒬 u) < 4 := by
  sorry

lemma dist_lt_four' (hu : u ∈ t) (hp : p ∈ t u) : dist_(p) (𝒬 u) (𝒬 p) < 4 := by
  sorry

end Forest

variable (X) in
/-- An `n`-row -/
structure Row (n : ℕ) extends Forest X n where
  pairwiseDisjoint' : 𝔘.PairwiseDisjoint (fun u ↦ (𝓘 u : Set X))

namespace Row

variable {n : ℕ} (t : Row X n)

instance : CoeHead (Row X n) (Set (𝔓 X)) := ⟨fun t ↦ t.𝔘⟩
instance : Membership (𝔓 X) (Row X n) := ⟨fun t x ↦ x ∈ (t : Set (𝔓 X))⟩
instance : CoeFun (Row X n) (fun _ ↦ 𝔓 X → Set (𝔓 X)) := ⟨fun t x ↦ t.𝔗 x⟩

@[simp] lemma mem_𝔘 : u ∈ t.𝔘 ↔ u ∈ t := by
  sorry
@[simp] lemma mem_𝔗 : p ∈ t.𝔗 u ↔ p ∈ t u := by
  sorry

lemma pairwiseDisjoint : Set.PairwiseDisjoint (t : Set (𝔓 X)) (fun u ↦ (𝓘 u : Set X)) := by
  sorry

end Row
end TileStructure
