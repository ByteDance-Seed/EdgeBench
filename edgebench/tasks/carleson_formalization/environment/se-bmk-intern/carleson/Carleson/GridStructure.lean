module

public import Carleson.ProofData

@[expose] public section

open Set MeasureTheory Metric Function Complex Bornology
open scoped NNReal ENNReal ComplexConjugate
noncomputable section

section Generic
universe u
variable {𝕜 : Type*} [_root_.RCLike 𝕜]

variable (X) in
/-- A grid structure on `X`.
We prefer `coeGrid : Grid → Set X` over `Grid : Set (Set X)`
Note: the `s` in this paper is `-s` of Christ's paper.
-/
class GridStructure {A : outParam ℝ≥0} [PseudoMetricSpace X] [DoublingMeasure X A]
    (D : outParam ℕ) (κ : outParam ℝ) (S : outParam ℕ) (o : outParam X) where
  /-- indexing set for a grid structure -/
  protected Grid : Type u
  fintype_Grid : Fintype Grid
  /-- The collection of dyadic cubes -/
  coeGrid : Grid → Set X
  /-- scale functions -/
  s : Grid → ℤ
  /-- Center functions -/
  c : Grid → X
  inj : Injective (fun i ↦ (coeGrid i, s i))
  range_s_subset : range s ⊆ Icc (-S) S
  topCube : Grid
  s_topCube : s topCube = S
  c_topCube : c topCube = o
  subset_topCube {i} : coeGrid i ⊆ coeGrid topCube
  Grid_subset_biUnion {i} : ∀ k ∈ Ico (-S : ℤ) (s i), coeGrid i ⊆ ⋃ j ∈ s ⁻¹' {k}, coeGrid j
  fundamental_dyadic' {i j} : s i ≤ s j → coeGrid i ⊆ coeGrid j ∨ Disjoint (coeGrid i) (coeGrid j)
  ball_subset_Grid {i} : ball (c i) (D ^ s i / 4) ⊆ coeGrid i --2.0.10
  Grid_subset_ball {i} : coeGrid i ⊆ ball (c i) (4 * D ^ s i) --2.0.10
  small_boundary {i} {t : ℝ≥0} (ht : D ^ (- S - s i) ≤ t) :
    volume.real { x ∈ coeGrid i | Metric.infEDist x (coeGrid i)ᶜ ≤ t * (D ^ (s i):ℝ≥0∞)} ≤
    2 * t ^ κ * volume.real (coeGrid i)
  coeGrid_measurable {i} : MeasurableSet (coeGrid i)

export GridStructure (range_s_subset Grid_subset_biUnion ball_subset_Grid Grid_subset_ball small_boundary
  topCube s_topCube c_topCube subset_topCube coeGrid_measurable) -- should `X` be explicit in topCube?

attribute [coe] GridStructure.coeGrid

variable {X : Type u} {A : ℝ≥0} [PseudoMetricSpace X] [DoublingMeasure X A]
variable {D : ℕ} {κ : ℝ} {S : ℕ} {o : X}
variable [GridStructure X D κ S o]

variable (X) in
/-- The indexing type of the grid structure. Elements are called (dyadic) cubes.
Note that this type has instances for both `≤` and `⊆`, but they do *not* coincide. -/
abbrev Grid : Type u := GridStructure.Grid X

def s : Grid X → ℤ := GridStructure.s
def c : Grid X → X := GridStructure.c

variable {i j : Grid X}

instance : Inhabited (Grid X) := ⟨topCube⟩
instance : Fintype (Grid X) := GridStructure.fintype_Grid
instance : Coe (Grid X) (Set X) := ⟨GridStructure.coeGrid⟩
instance : Membership X (Grid X) := ⟨fun i x ↦ x ∈ (i : Set X)⟩
instance : PartialOrder (Grid X) := PartialOrder.lift _ GridStructure.inj

/- not sure whether these should be simp lemmas, but that might be required if we want to
  conveniently rewrite/simp with Set-lemmas -/
@[simp] lemma Grid.mem_def {x : X} : x ∈ i ↔ x ∈ (i : Set X) := by
  sorry
@[simp] lemma Grid.le_def : i ≤ j ↔ (i : Set X) ⊆ (j : Set X) ∧ s i ≤ s j := by
  sorry

lemma Grid.eq_iff : i = j ↔ (i : Set X) = (j : Set X) ∧ s i = s j := by
  sorry

lemma Grid.mem_mono {x : X} : Monotone (x ∈ · : Grid X → Prop) := by
  sorry

lemma fundamental_dyadic :
    s i ≤ s j → (i : Set X) ⊆ (j : Set X) ∨ Disjoint (i : Set X) (j : Set X) := by
  sorry

lemma le_or_disjoint (h : s i ≤ s j) : i ≤ j ∨ Disjoint (i : Set X) (j : Set X) := by
  sorry

lemma le_or_ge_or_disjoint : i ≤ j ∨ j ≤ i ∨ Disjoint (i : Set X) (j : Set X) := by
  sorry

lemma le_or_ge_of_mem_of_mem {c : X} (mi : c ∈ i) (mj : c ∈ j) : i ≤ j ∨ j ≤ i := by
  sorry

lemma le_of_mem_of_mem (h : s i ≤ s j) {c : X} (mi : c ∈ i) (mj : c ∈ j) : i ≤ j := by
  sorry

lemma eq_or_disjoint (hs : s i = s j) : i = j ∨ Disjoint (i : Set X) (j : Set X) := by
  sorry

lemma disjoint_of_not_le_not_le {i j : Grid X} (h : ¬i ≤ j) (h' : ¬j ≤ i) :
    Disjoint (i : Set X) j := by
  sorry

lemma subset_of_notMem_Iic_of_not_disjoint (i : Grid X) (j : Grid X)
    (h : i ∉ Iic j)
    (notDisjoint : ¬ Disjoint (i : Set X) j) :
    (j : Set X) ⊆ i := by
  sorry

lemma scale_mem_Icc : s i ∈ Icc (-S : ℤ) S := by
  sorry

lemma volume_coeGrid_pos (hD : 0 < D) : 0 < volume (i : Set X) := by
  sorry

@[aesop (rule_sets := [finiteness]) safe apply]
lemma volume_coeGrid_lt_top : volume (i : Set X) < ⊤ := by
  sorry

namespace Grid

protected lemma inj : Injective (fun i : Grid X ↦ ((i : Set X), s i)) := by
  sorry

lemma le_topCube : i ≤ topCube := by
  sorry

lemma isTop_topCube : IsTop (topCube : Grid X) := by
  sorry

lemma isMax_iff : IsMax i ↔ i = topCube := by
  sorry

/-- The set `I ↦ Iᵒ` in the blueprint. -/
def int (i : Grid X) : Set X := ball (c i) (D ^ s i / 4)

postfix:max "ᵒ" => Grid.int

/-- An auxiliary measure used in the well-foundedness of `Ω` in Lemma `tile_structure`. -/
def opSize (i : Grid X) : ℕ := (S - s i).toNat

lemma int_subset : i.int ⊆ i := by
  sorry

end Grid
end Generic

namespace Grid

open scoped ShortVariables
variable {X : Type*} [PseudoMetricSpace X] {a : ℕ} {q : ℝ} {K : X → X → ℂ}
  {σ₁ σ₂ : X → ℤ} {F G : Set X} [ProofData a q K σ₁ σ₂ F G]

notation "dist_{" I "}" => @dist (WithFunctionDistance (c I) (D ^ s I / 4)) _
notation "nndist_{" I "}" => @nndist (WithFunctionDistance (c I) (D ^ s I / 4)) _
notation "edist_{" I "}" => @edist (WithFunctionDistance (c I) (D ^ s I / 4)) _
notation "ball_{" I "}" => @ball (WithFunctionDistance (c I) (D ^ s I / 4)) _

section GridManipulation

variable [GridStructure X D κ S o]

lemma c_mem_Grid {i : Grid X} : c i ∈ (i : Set X) := by
  sorry

lemma nonempty (i : Grid X) : (i : Set X).Nonempty := by
  sorry

lemma scale_eq_scale_topCube_iff (i : Grid X) : s i = s (topCube : Grid X) ↔ i = topCube := by
  sorry

lemma scale_lt_scale_topCube {i : Grid X} (hi : i ≠ topCube) : s i < s (topCube : Grid X) := by
  sorry

lemma eq_topCube_of_S_eq_zero (i : Grid X) (hS : S = 0) : i = topCube := by
  sorry

lemma le_dyadic {i j k : Grid X} (h : s i ≤ s j) (li : k ≤ i) (lj : k ≤ j) : i ≤ j := by
  sorry

@[simp] lemma lt_def {i j : Grid X} : i < j ↔ (i : Set X) ⊆ (j : Set X) ∧ s i < s j := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma isMin_iff {i : Grid X} : IsMin i ↔ s i = - S := by
  sorry

/-- There exists a unique successor of each non-maximal cube. -/
lemma exists_unique_succ (i : Grid X) (h : ¬IsMax i) :
    ∃! j ∈ Finset.univ, i < j ∧ ∀ j', i < j' → j ≤ j' := by
  sorry

open Classical in
/-- If `i` is not a maximal element, this is the (unique) minimal element greater than i.
This is not a `SuccOrder` since an element can be the successor of multiple other elements. -/
def succ (i : Grid X) : Grid X := if h : IsMax i then i else Finset.choose (hp := exists_unique_succ i h)

variable {i j : Grid X}

lemma succ_spec (h : ¬IsMax i) : i < i.succ ∧ ∀ j, i < j → i.succ ≤ j := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma succ_unique (h : ¬IsMax i) : i < j → (∀ j', i < j' → j ≤ j') → i.succ = j := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma le_succ : i ≤ i.succ := by
  sorry

lemma max_of_le_succ : i.succ ≤ i → IsMax i := by
  sorry

lemma not_isMax_of_scale_lt {j W : Grid X} (h : s j < s W) : ¬IsMax j := by
  sorry

lemma succ_le_of_lt (h : i < j) : i.succ ≤ j := by
  sorry

lemma exists_containing_subcube (l : ℤ) (h : l ∈ Icc (-S : ℤ) (s i)) {x : X} (mx : x ∈ i) :
    ∃ j, s j = l ∧ x ∈ j := by
  sorry

lemma exists_supercube (l : ℤ) (h : l ∈ Icc (s i) S) : ∃ j, s j = l ∧ i ≤ j := by
  sorry

lemma exists_sandwiched (h : i ≤ j) (l : ℤ) (hl : l ∈ Icc (s i) (s j)) :
    ∃ k, s k = l ∧ i ≤ k ∧ k ≤ j := by
  sorry

lemma scale_succ (h : ¬IsMax i) : s i.succ = s i + 1 := by
  sorry

lemma exists_scale_succ {j W : Grid X} (h : s j < s W) : ∃ J, j ≤ J ∧ s J = s j + 1 := by
  sorry

lemma opSize_succ_lt (h : ¬IsMax i) : i.succ.opSize < i.opSize := by
  sorry

@[elab_as_elim]
lemma induction (P : Grid X → Prop) (base : ∀ i, IsMax i → P i)
    (ind : ∀ i, ¬IsMax i → P i.succ → P i) : ∀ i, P i := by
  sorry

lemma succ_def (h : ¬IsMax i) : i.succ = j ↔ i ≤ j ∧ s j = s i + 1 := by
  sorry

/-! ## Maximal elements of finsets of dyadic cubes -/

open Classical in
def maxCubes (s : Finset (Grid X)) : Finset (Grid X) := s.filter fun i ↦ ∀ j ∈ s, i ≤ j → i = j

lemma exists_maximal_supercube {s : Finset (Grid X)} (hi : i ∈ s) : ∃ j ∈ maxCubes s, i ≤ j := by
  sorry

lemma maxCubes_pairwiseDisjoint {s : Finset (Grid X)} :
    PairwiseDisjoint (SetLike.coe (maxCubes s)) fun i ↦ (i : Set X) := by
  sorry

end GridManipulation

/-- The constant appearing in Lemma 2.1.2, `2 ^ {-95a}`. -/
def _root_.C2_1_2 (a : ℕ) : ℝ := 2 ^ ((-𝕔 + 5) * a : ℝ)

include q K σ₁ σ₂ F G in
variable (X) in
lemma _root_.C2_1_2_le_inv_256 : C2_1_2 a ≤ 1 / 256 := by
  sorry

include q K σ₁ σ₂ F G in
variable (X) in
lemma _root_.C2_1_2_le_one : C2_1_2 a ≤ 1 := by
  sorry

include q K σ₁ σ₂ F G in
variable (X) in
lemma _root_.C2_1_2_lt_one : C2_1_2 a < 1 := by
  sorry

variable [GridStructure X D κ S o]

/-- Stronger version of Lemma 2.1.2. -/
lemma dist_strictMono {I J : Grid X} (hpq : I < J) {f g : Θ X} :
    dist_{I} f g ≤ C2_1_2 a * dist_{J} f g := by
  sorry

/-- Weaker version of Lemma 2.1.2. -/
lemma dist_mono {I J : Grid X} (hpq : I ≤ J) {f g : Θ X} : dist_{I} f g ≤ dist_{J} f g := by
  sorry

lemma dist_strictMono_iterate {I J : Grid X} {d : ℕ} (hij : I ≤ J) (hs : s I + d = s J)
    {f g : Θ X} : dist_{I} f g ≤ C2_1_2 a ^ d * dist_{J} f g := by
  sorry

-- Version of `dist_strictMono_iterate` with `d` in `ℤ`
lemma dist_strictMono_iterate' {I J : Grid X} {d : ℤ} (hd : d ≥ 0) (hij : I ≤ J)
    (hs : s I + d = s J) {f g : Θ X} : dist_{I} f g ≤ C2_1_2 a ^ d * dist_{J} f g := by
  sorry

lemma dist_c_le_of_subset {J J' : Grid X} (subset : (J : Set X) ⊆ J') :
    dist (c J) (c J') < 4 * D ^ s J' := by
  sorry

end Grid
