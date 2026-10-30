module

public import Carleson.TileStructure
import Mathlib.Algebra.Order.Interval.Set.Group

@[expose] public section

open Set MeasureTheory Metric Function Complex Bornology Notation
open scoped NNReal ENNReal ComplexConjugate

noncomputable section

open scoped ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G]

lemma ball_bound {Y : Set X} (k : ℤ) (hk_lower : -S ≤ k)
    (hY : Y ⊆ ball o (4 * D ^ (S : ℤ) - D ^ k)) (y : X) (hy : y ∈ Y) :
    ball o (4 * D ^ (S : ℤ)) ⊆ ball y (8 * D ^ (2 * S : ℤ) * D ^ k) := by
  sorry

variable (X) in def J' : ℕ := 3 + 2 * S * 𝕔 * a ^ 2

lemma twopow_J : 2 ^ J' X = 8 * D ^ (2 * S) := by
  sorry

lemma twopow_J' : 2 ^ J' X = 8 * nnD ^ (2 * S) := by
  sorry

variable (X) in
def C4_1_1 := As (2 ^ a) (2 ^ J' X)

lemma counting_balls {k : ℤ} (hk_lower : -S ≤ k) {Y : Set X}
    (hY : Y ⊆ ball o (4 * D ^ S - D ^ k))
    (hYdisjoint : Y.PairwiseDisjoint (ball · (D ^ k))) :
    (Set.encard Y).toENNReal ≤ C4_1_1 X := by
  sorry

variable (X) in
def property_set (k : ℤ) : Set (Set X) :=
  {s | s ⊆ ball o (4 * D ^ S - D ^ k : ℝ) ∧
       s.PairwiseDisjoint (fun y => ball y (D^k:ℝ)) ∧ (k = S → o ∈ s)}

-- XXX: perhaps `if k = S then {o} else ∅` should be made its own auxiliary definition
variable (X) in
lemma property_set_nonempty (k : ℤ) : (if k = S then {o} else ∅) ∈ property_set X k := by
  sorry

variable (X) in
lemma chain_property_set_has_bound (k : ℤ) :
    ∀ c ⊆ property_set X k, IsChain (· ⊆ ·) c →
      ∃ ub ∈ property_set X k, ∀ s ∈ c, s ⊆ ub := by
  sorry

variable (X) in
lemma zorn_apply_maximal_set (k : ℤ) :
    ∃ s ∈ property_set X k, ∀ s' ∈ property_set X k, s ⊆ s' → s' = s := by
  sorry

variable (X) in
def Yk (k : ℤ) : Set X := (zorn_apply_maximal_set X k).choose

lemma Yk_pairwise (k : ℤ) : (Yk X k).PairwiseDisjoint (ball · (D ^ k)) := by
  sorry

lemma Yk_subset (k : ℤ) : Yk X k ⊆ ball o (4 * D ^ S - D ^ k) := by
  sorry

lemma Yk_maximal (k : ℤ) {s : Set X} (hs_sub : s ⊆ ball o (4 * D ^ S - D ^ k))
    (hs_pairwise : s.PairwiseDisjoint (ball · (D ^ k))) (hmax_sub : Yk X k ⊆ s)
    (hk_s : k = S → o ∈ s) : s = Yk X k := by
  sorry

lemma o_mem_Yk_S : o ∈ Yk X S := by
  sorry

lemma cover_big_ball (k : ℤ) : ball o (4 * D ^ S - D ^ k) ⊆ ⋃ y ∈ Yk X k, ball y (2 * D ^ k) := by
  sorry

variable (X) in
lemma Yk_nonempty {k : ℤ} (hmin : (0 : ℝ) < 4 * D ^ S - D ^ k) : (Yk X k).Nonempty := by
  sorry

-- not sure if we actually need this; just countability seems quite good enough
lemma Yk_finite {k : ℤ} (hk_lower : -S ≤ k) : (Yk X k).Finite := by
  sorry

variable (X) in
lemma Yk_countable (k : ℤ) : (Yk X k).Countable := by
  sorry

variable (X) in
@[implicit_reducible]
def Yk_encodable (k : ℤ) : Encodable (Yk X k) := (Yk_countable X k).toEncodable

@[implicit_reducible]
def Encodable.linearOrder {α : Type*} (i : Encodable α) : LinearOrder α :=
  LinearOrder.lift' (i.encode) (i.encode_injective)

instance {k : ℤ} : LinearOrder (Yk X k) := (Yk_encodable X k).linearOrder
instance {k : ℤ} : WellFoundedLT (Yk X k) where
  wf := by
    apply (@OrderEmbedding.wellFounded (Yk X k) ℕ)
    · use ⟨(Yk_encodable X k).encode,(Yk_encodable X k).encode_injective⟩
      simp only [Embedding.coeFn_mk, Subtype.forall]
      exact fun i hi j hj ↦ by rfl
    exact wellFounded_lt

local instance {k : ℤ} : SizeOf (Yk X k) where
  sizeOf := (Yk_encodable X k).encode

lemma I_induction_proof {k : ℤ} (hk : -S ≤ k) (hneq : ¬k = -S) : -S ≤ k - 1 := by
  sorry

-- Auxiliary lemma used in subsequent mutual blocks.
theorem aux {s k : ℤ} (h1 : 0 ≤ s + (k - 1)) :
    (s + (k - 1)).toNat < (s + k).toNat := by
  sorry

mutual
  def I1 {k : ℤ} (hk : -S ≤ k) (y : Yk X k) : Set X :=
    if hk': k = -S then
      ball y (D^(-S:ℤ))
    else
      let hk'' : -S < k := lt_of_le_of_ne hk fun a_1 ↦ hk' (id a_1.symm)
      have h1 : 0 ≤ S + (k - 1) := by linarith
      ⋃ (y': Yk X (k-1)),
        ⋃ (_ : y' ∈ Yk X (k-1) ↓∩ ball (y:X) (D^k)), I3 (I_induction_proof hk hk') y'
  termination_by (3 * (S+k).toNat, sizeOf y)

  def I2 {k : ℤ} (hk : -S ≤ k) (y : Yk X k) : Set X :=
    if hk': k = -S then
      ball y (2 * D^(-S:ℤ))
    else
      ⋃ (y':Yk X (k-1)),
        ⋃ (_ : y' ∈ Yk X (k-1) ↓∩ ball y (2 * D^k)), I3 (I_induction_proof hk hk') y'
  termination_by (3 * (S+k).toNat, sizeOf y)

  def Xk {k:ℤ} (hk : -S ≤ k) : Set X := ⋃ (y' : Yk X k), I1 hk y'
  termination_by (3 * (S+k).toNat + 1, 0)

  def I3 {k:ℤ} (hk : -S ≤ k) (y:Yk X k) : Set X :=
    I1 hk y ∪ (I2 hk y \ (Xk hk ∪ ⋃ (y' < y), I3 hk y'))
  termination_by (3 * (S+k).toNat + 2, sizeOf y)
end

lemma I3_apply {k : ℤ} (hk : -S ≤ k) (y : Yk X k) :
    I3 hk y = I1 hk y ∪ (I2 hk y \ (Xk hk ∪ ⋃ (y' < y), I3 hk y')) := by
  sorry

lemma I1_subset_I3 {k : ℤ} (hk : -S ≤ k) (y : Yk X k) :
    I1 hk y ⊆ I3 hk y := by
  sorry

lemma I1_subset_I2 {k : ℤ} (hk : -S ≤ k) (y : Yk X k) :
    I1 hk y ⊆ I2 hk y := by
  sorry

lemma I3_subset_I2 {k : ℤ} (hk : -S ≤ k) (y : Yk X k) :
    I3 hk y ⊆ I2 hk y := by
  sorry

mutual
  lemma I1_measurableSet {k : ℤ} (hk : -S ≤ k) (y : Yk X k) : MeasurableSet (I1 hk y) := by
    by_cases hk_s : k = -S
    · rw [I1, dif_pos hk_s]
      exact measurableSet_ball
    · let hk'' : -S < k := lt_of_le_of_ne hk fun a_1 ↦ hk_s (id a_1.symm)
      have h1: 0 ≤ S + (k - 1) := by linarith
      rw [I1, dif_neg hk_s]
      letI := (Yk_countable X (k - 1)).to_subtype
      refine MeasurableSet.biUnion (to_countable (Yk X (k - 1) ↓∩ ball y (D ^ k))) ?_
      simp only [mem_preimage]
      exact fun b _ ↦ I3_measurableSet (I_induction_proof hk hk_s) b
  termination_by (3 * (S+k).toNat, sizeOf y)

  lemma I2_measurableSet {k : ℤ} (hk : -S ≤ k) (y : Yk X k) : MeasurableSet (I2 hk y) := by
    by_cases hk_s : k = -S
    · rw [I2, dif_pos hk_s]
      exact measurableSet_ball
    · let hk'' : -S < k := lt_of_le_of_ne hk fun a_1 ↦ hk_s (id a_1.symm)
      rw [I2, dif_neg hk_s]
      letI := (Yk_countable X (k - 1)).to_subtype
      refine MeasurableSet.biUnion (to_countable (Yk X (k - 1) ↓∩ ball (↑y) (2 * D ^ k))) ?_
      · simp only [mem_preimage]
        exact fun b _ ↦ I3_measurableSet (I_induction_proof hk hk_s) b
  termination_by (3 * (S+k).toNat, sizeOf y)

  lemma Xk_measurableSet {k : ℤ} (hk : -S ≤ k) : MeasurableSet (Xk hk) := by
    rw [Xk]
    letI := (Yk_countable X k).to_subtype
    apply MeasurableSet.iUnion fun b ↦ I1_measurableSet hk b
  termination_by (3 * (S+k).toNat + 1, 0)

  lemma I3_measurableSet {k : ℤ} (hk : -S ≤ k) (y : Yk X k) : MeasurableSet (I3 hk y) := by
    rw [I3]
    refine MeasurableSet.union (I1_measurableSet hk y) ?_
    refine (MeasurableSet.diff (I2_measurableSet hk y))
      (MeasurableSet.union (Xk_measurableSet hk) ?_)
    letI := (Yk_countable X k).to_subtype
    exact (MeasurableSet.iUnion fun b ↦ MeasurableSet.iUnion fun _ ↦ I3_measurableSet hk b)
  termination_by (3 * (S + k).toNat + 2, sizeOf y)
end

section basic_grid_structure

mutual
  lemma I1_prop_1 {k : ℤ} (hk : -S ≤ k) {x : X} {y1 y2 : Yk X k} :
      x ∈ I1 hk y1 ∩ I1 hk y2 → y1 = y2 := by
    rw [I1,I1]
    by_cases hk_s : k = -S
    · rw [dif_pos hk_s,dif_pos hk_s]
      subst hk_s
      intro hx
      ext
      rw [(Yk_pairwise (-S)).elim (y1.property) (y2.property)]
      rw [not_disjoint_iff]
      exact ⟨x, hx⟩
    · have : -S ≤ k - 1 := I_induction_proof hk hk_s
      have : ((2 * (S + (k - 1))).toNat : ℤ) + 1 < 2 * (S + k) := by
        rw [Int.toNat_of_nonneg (by linarith)]
        linarith
      rw [dif_neg hk_s, dif_neg hk_s]
      intro hx
      push _ ∈ _ at hx
      obtain ⟨⟨z1, hz1, hz1'⟩, ⟨z2, hz2, hz2'⟩⟩ := hx
      have hz_eq : z1 = z2 := I3_prop_1 (I_induction_proof hk hk_s) ⟨hz1', hz2'⟩
      subst hz_eq
      ext
      apply (Yk_pairwise k).elim (y1.property) (y2.property)
      rw [not_disjoint_iff]
      use z1
  termination_by (2 * (S + k)).toNat

  lemma I3_prop_1 {k:ℤ} (hk : -S ≤ k) {x : X} {y1 y2 : Yk X k} :
      x ∈ I3 hk y1 ∩ I3 hk y2 → y1 = y2 := by
    intro hx
    have hx' := hx
    rw [I3,I3] at hx
    obtain ⟨hl,hr⟩ := hx'
    push _ ∈ _ at hx
    simp only [not_or, not_exists] at hx
    by_cases hx_mem_Xk : x ∈ Xk hk
    · rw [not_iff_false_intro hx_mem_Xk] at hx
      simp_rw [false_and,and_false,or_false] at hx
      exact I1_prop_1 hk hx
    have hx_notMem_i1 (y' : Yk X k): x ∉ I1 hk y' := by
      simp only [Xk, mem_iUnion, not_exists] at hx_mem_Xk
      exact hx_mem_Xk _
    rw [iff_false_intro (hx_notMem_i1 y1), iff_false_intro (hx_notMem_i1 y2)] at hx
    rw [false_or,false_or,iff_true_intro hx_mem_Xk,true_and,true_and] at hx
    apply Mathlib.Tactic.Linarith.eq_of_not_lt_of_not_gt
    · exact fun h ↦ hx.right.right y1 h hl
    exact fun h ↦ hx.left.right y2 h hr
  termination_by (2 * (S + k)).toNat + 1
end

lemma I3_prop_3_2 {k : ℤ} (hk : -S ≤ k) (y : Yk X k) :
    I3 hk y ⊆ ball (y : X) (4 * D ^ k) := by
  sorry

mutual
  lemma I2_prop_2 {k : ℤ} (hk : -S ≤ k) :
      ball o (4 * D ^ S - 2 * D ^ k) ⊆ ⋃ (y : Yk X k), I2 hk y := by
    simp only [I2, mem_preimage, iUnion_coe_set]
    by_cases hk_s : k = -S
    · simp_rw [dif_pos hk_s]
      subst hk_s
      calc
        ball o (4 * D ^ S - 2 * (D ^ (-S : ℤ)))
          ⊆ ball o (4 * D ^ S - D ^ (-S : ℤ)) := by
            apply ball_subset_ball
            rw [two_mul,tsub_le_iff_right,sub_add_add_cancel,le_add_iff_nonneg_right]
            positivity
        _ ⊆ ⋃ (i ∈ Yk X (-S)), ball i (2 * D ^ (-S : ℤ)) := cover_big_ball (-S : ℤ)
    · simp_rw [dif_neg hk_s]
      intro x hx
      have : -S < k := lt_of_le_of_ne hk fun a_1 ↦ hk_s (id a_1.symm)
      have : ((2 * (S + (k - 1))).toNat : ℤ) + 1 < 2 * (S + k) := by
        rw [Int.toNat_of_nonneg (by linarith)]
        linarith
      have hsub1 : ball o (4 * D ^ S - 2 * D ^ k) ⊆ ⋃ y, I3 (I_induction_proof hk hk_s) y := by
        calc
          ball o (4 * D ^ S - 2 * D ^ k)
            ⊆ ball o (4 * D ^ S - 2 * D ^ (k - 1)) := by
              apply ball_subset_ball
              simp only [tsub_le_iff_right]
              rw [sub_eq_add_neg,add_assoc]
              simp only [le_add_iff_nonneg_right, le_neg_add_iff_add_le, add_zero, Nat.ofNat_pos,
                mul_le_mul_iff_right₀]
              gcongr
              exacts [one_le_realD a, by linarith]
          _ ⊆ ⋃ y, I3 _ y := I3_prop_2 _
      have hmem_i3 : x ∈ ⋃ y, I3 _ y := hsub1 hx
      simp only [mem_iUnion] at hmem_i3
      obtain ⟨y', hy''⟩ := hmem_i3
      have hy''' : x ∈ ball (y' : X) (D ^ k) := by
        apply (?_ : I3 _ y' ⊆ ball (y' : X) (D ^ k)) hy''
        calc
          I3 _ y'
            ⊆ ball y' (4 * D ^ (k - 1)) := I3_prop_3_2 _ y'
          _ ⊆ ball y' (D * D ^ (k - 1)) :=
              ball_subset_ball (by gcongr; exact (four_le_realD X))
          _ = ball (y': X) (D ^ k) := by
            nth_rw 1 [← zpow_one (D : ℝ),← zpow_add₀ (realD_pos a).ne.symm, add_sub_cancel]
      rw [mem_ball_comm] at hy'''
      have hyfin : (y' : X) ∈ ball o (4 * D ^ S - D ^ k) := by
        simp only [mem_ball] at hx hy''' ⊢
        calc
          dist ↑y' o
            ≤ dist (y' : X) x + dist x o := dist_triangle _ _ _
          _ < D ^ k + (4 * D ^ S - 2 * D ^ k) := add_lt_add hy''' hx
          _ ≤ 4 * D ^ S - D ^ k := by linarith
      have hyfin' : (y' : X) ∈ ⋃ (y'' ∈ Yk X k), ball (y'') (2 * D ^ k) := cover_big_ball k hyfin
      rw [← iUnion_coe_set (Yk X k) (fun z ↦ ball (z : X) (2 * D ^ k))] at hyfin'
      simp only [mem_iUnion] at hyfin'
      obtain ⟨y2,hy2'⟩ := hyfin'
      simp only [mem_iUnion, exists_prop, exists_and_left]
      use y2, y2.property, y', hy2', y'.property
  termination_by (2 * (S + k)).toNat

  lemma I3_prop_2 {k : ℤ} (hk : -S ≤ k) :
      ball o (4 * D ^ S - 2 * D ^ k) ⊆ ⋃ (y : Yk X k), I3 hk y := by
    intro x hx
    by_cases hx_mem_Xk : x ∈ Xk hk
    · rw [Xk] at hx_mem_Xk
      simp only [mem_iUnion] at hx_mem_Xk ⊢
      refine hx_mem_Xk.elim (fun y hy ↦ ?_)
      use y
      rw [I3]
      exact mem_union_left _ hy
    · simp only [mem_iUnion]
      have : x ∈ ⋃ (y : Yk X k), I2 hk y := I2_prop_2 hk hx
      simp only [mem_iUnion] at this
      have : {i | x ∈ I2 hk i}.Nonempty := this
      have H := (@wellFounded_lt (Yk X k) _ _)
      let y := H.min {i | x ∈ I2 hk i} this
      have hy_i2 : x ∈ I2 hk y := H.min_mem {i|x ∈ I2 hk i} this
      have hy_is_min : ∀ y', x ∈ I2 hk y' → ¬ y' < y :=
        fun y' hy' ↦ H.not_lt_min {i | x ∈ I2 hk i} hy'
      use y
      revert hy_i2 hy_is_min
      generalize y = y
      intro hy_i2 hy_min
      rw [I3]
      have hx_notMem_i1 : ∀ y',x ∉ I1 hk y' := by
        simp only [Xk,mem_iUnion, not_exists] at hx_mem_Xk
        exact hx_mem_Xk
      push _ ∈ _
      simp only [not_or, not_exists]
      refine Or.inr ⟨hy_i2,hx_mem_Xk, fun y' hy' ↦ ?_⟩
      rw [I3]
      push _ ∈ _
      simp only [not_or, not_exists, not_and]
      exact ⟨hx_notMem_i1 y', fun hy_i2' _ _ ↦ hy_min y' hy_i2' hy'⟩
  termination_by (2 * (S + k)).toNat + 1
end

lemma I3_prop_3_1 {k : ℤ} (hk : -S ≤ k) (y : Yk X k) :
    ball (y : X) (2⁻¹ * D ^ k) ⊆ I3 hk y := by
  sorry

end basic_grid_structure

lemma I3_nonempty {k : ℤ} (hk : -S ≤ k) (y : Yk X k) :
  (I3 hk y).Nonempty := by
  sorry

-- the additional argument `hk` to get decent equality theorems
lemma cover_by_cubes {l : ℤ} (hl : -S ≤ l) :
    ∀ {k : ℤ}, l ≤ k → (hk : -S ≤ k) → ∀ y, I3 hk y ⊆ ⋃ (yl : Yk X l), I3 hl yl := by
  sorry

lemma dyadic_property {l : ℤ} (hl : -S ≤ l) {k : ℤ} (hl_k : l ≤ k) :
    (hk : -S ≤ k) → ∀ (y : Yk X k), ∀ (y' : Yk X l),
    ¬ Disjoint (I3 hl y') (I3 hk y) → I3 hl y' ⊆ I3 hk y := by
  sorry

structure ClosenessProperty {k1 k2 : ℤ} (hk1 : -S ≤ k1) (hk2 : -S ≤ k2)
    (y1 : Yk X k1) (y2 : Yk X k2) : Prop where
  I3_subset : I3 hk1 y1 ⊆ I3 hk2 y2
  I3_infdist_lt : Metric.infEDist (y1 : X) (I3 hk2 y2)ᶜ < (6 * D ^ k1 : ℝ≥0∞)

local macro "clProp(" hkl:term ", " y1:term " | " hkr:term ", " y2:term ")" : term =>
 `(ClosenessProperty $hkl $hkr $y1 $y2)

lemma transitive_boundary' {k1 k2 k3 : ℤ} (hk1 : -S ≤ k1) (hk2 : -S ≤ k2) (hk3 : -S ≤ k3)
  (hk1_2 : k1 < k2) (hk2_3 : k2 ≤ k3) (y1 : Yk X k1) (y2 : Yk X k2) (y3 : Yk X k3)
    (x : X) (hx : x ∈ I3 hk1 y1 ∩ I3 hk2 y2 ∩ I3 hk3 y3) :
    clProp(hk1,y1|hk3,y3) → (clProp(hk1,y1|hk2,y2) ∧ clProp(hk2,y2|hk3,y3)) := by
  sorry

lemma transitive_boundary {k1 k2 k3 : ℤ} (hk1 : -S ≤ k1) (hk2 : -S ≤ k2) (hk3 : -S ≤ k3)
  (hk1_2 : k1 ≤ k2) (hk2_3 : k2 ≤ k3) (y1 : Yk X k1) (y2 : Yk X k2) (y3 : Yk X k3)
    (x : X) (hx : x ∈ I3 hk1 y1 ∩ I3 hk2 y2 ∩ I3 hk3 y3) :
    clProp(hk1,y1|hk3,y3) → (clProp(hk1,y1|hk2,y2) ∧ clProp(hk2,y2|hk3,y3)) := by
  sorry

def const_K : ℕ := 2 ^ (4 * a + 1)

namespace ShortVariables
set_option hygiene false in
scoped notation "K'" => @const_K a
end ShortVariables

lemma K_pos : 0 < (K' : ℝ) := by
  sorry

variable (X) in
def C4_1_7 [ProofData a q K σ₁ σ₂ F G] : ℝ≥0 := As (defaultA a) (2 ^ 4)

variable (X) in
lemma C4_1_7_eq : C4_1_7 X = 2 ^ (4 * a) := by
  sorry

lemma volume_tile_le_volume_ball (k : ℤ) (hk : -S ≤ k) (y : Yk X k) :
    volume (I3 hk y) ≤ C4_1_7 X * volume (ball (y : X) (4⁻¹ * D ^ k)) := by
  sorry

lemma le_s {k : ℤ} (hk_mK : -S ≤ k - K') (k' : Ioc (k - K') k) : (-S : ℤ) ≤ k' := by
  sorry

lemma small_boundary' (k : ℤ) (hk : -S ≤ k) (hk_mK : -S ≤ k - K') (y : Yk X k) :
    ∑' (z : Yk X (k - K')), volume (⋃ (_ : clProp(hk_mK,z|hk,y)), (I3 hk_mK z))
      ≤ 2⁻¹ * volume (I3 hk y) := by
  sorry

lemma small_boundary (k : ℤ) (hk : -S ≤ k) (hk_mK : -S ≤ k - K') (y : Yk X k) :
    ∑' (z : Yk X (k - K')), ∑ᶠ (_ : clProp(hk_mK,z|hk,y)), volume (I3 hk_mK z)
      ≤ 2⁻¹ * volume (I3 hk y) := by
  sorry

lemma le_s_1' (n : ℕ) {k : ℤ} (hk_mn1K : -S ≤ k - (n + 1 : ℕ) * K') : (-S ≤ (k - K') - n * K') := by
  sorry

lemma le_s_2' (n : ℕ) {k : ℤ} (hk_mn1K : -S ≤ k - (n + 1 : ℕ) * K') : (-S ≤ k - K') := by
  sorry

lemma boundary_sum_eq {k : ℤ} (hk : -S ≤ k) {k' : ℤ} (hk' : -S ≤ k') (y : Yk X k) :
    ∑'(y' : Yk X k'), ∑ᶠ (_ : clProp(hk',y'|hk,y)), volume (I3 hk' y') =
      volume (⋃ (y' : Yk X k'), ⋃ (_ : clProp(hk',y'|hk,y)), I3 hk' y') := by
  sorry

lemma smaller_boundary (n : ℕ) :
    ∀ {k : ℤ}, (hk : -S ≤ k) → (hk_mnK : -S ≤ k - n * K') → ∀ (y : Yk X k),
      ∑' (y' : Yk X (k - n * K')), ∑ᶠ (_ : clProp(hk_mnK,y'|hk,y)), volume (I3 hk_mnK y') ≤
        2⁻¹ ^ n * volume (I3 hk y) := by
  sorry

section ProofData
include q K σ₁ σ₂ F G

variable (a) in
def const_n {t : ℝ} (_ht : t ∈ Ioo 0 1) : ℕ := ⌊-Real.logb D t / K'⌋₊

variable {t : ℝ}

variable (X) in
theorem prefloor_nonneg (ht : t ∈ Ioo 0 1) :
    0 ≤ -Real.logb (↑D) t / K' := by
  sorry

variable (X) in
lemma const_n_prop_1 (ht : t ∈ Ioo 0 1) : D ^ (const_n a ht * K') ≤ t⁻¹ := by
  sorry

variable (X) in
lemma const_n_prop_2 (ht : t ∈ Ioo 0 1) (k : ℤ) : t * D ^ k ≤ D ^ (k - const_n a ht * K') := by
  sorry

variable (X) in
lemma const_n_is_max (ht : t ∈ Ioo 0 1) (n : ℕ) : D ^ (n * K') ≤ t⁻¹ → n ≤ const_n a ht := by
  sorry

variable (X) in
lemma const_n_prop_3 (ht : t ∈ Ioo 0 1) :
    (t * D ^ K' : ℝ)⁻¹ ≤ ↑D ^ (const_n a ht * K') := by
  sorry

variable (X) in
lemma const_n_nonneg (ht : t ∈ Ioo 0 1) : 0 ≤ const_n a ht := by
  sorry

variable (X) in
lemma kappa_le_log2D_inv_mul_K_inv : κ ≤ (Real.logb 2 D * K')⁻¹ := by
  sorry

end ProofData

lemma boundary_measure {k : ℤ} (hk : -S ≤ k) (y : Yk X k) {t : ℝ≥0} (ht : t ∈ Set.Ioo 0 1)
    (htD : (D ^ (-S : ℤ) : ℝ) ≤ t * D ^ k) :
    volume ({x | x ∈ I3 hk y ∧ Metric.infEDist x (I3 hk y)ᶜ ≤ (↑t * ↑D ^ k)}) ≤
      2 * t ^ κ * volume (I3 hk y) := by
  sorry

lemma boundary_measure' {k : ℤ} (hk : -S ≤ k) (y : Yk X k) {t : ℝ≥0} (ht : t ∈ Set.Ioo 0 1)
    (htD : (D ^ (-S : ℤ) : ℝ) ≤ t * D ^ k) :
    volume.real ({x | x ∈ I3 hk y ∧ Metric.infEDist x (I3 hk y)ᶜ ≤ (↑t * ↑D ^ k)}) ≤
      2 * t ^ κ * volume.real (I3 hk y) := by
  sorry

variable (X) in
@[ext]
structure 𝓓 where
  k : ℤ
  hk : -S ≤ k
  hk_max : k ≤ S
  y : Yk X k
  hsub : I3 hk y ⊆ I3 (by trans 0 <;> simp : (-S : ℤ) ≤ S) ⟨o,o_mem_Yk_S⟩

variable (X) in
def max_𝓓 : 𝓓 X where
  k := S
  hk := by trans 0 <;> simp
  hk_max := Int.le_refl (S : ℤ)
  y := ⟨o,o_mem_Yk_S⟩
  hsub := fun ⦃a_1⦄ a ↦ a

def 𝓓.coe (z : 𝓓 X) : Set X := I3 z.hk z.y

variable (X) in
def forget_map (x : 𝓓 X) : (k : Set.Icc (-S : ℤ) S) × (Yk X k) := ⟨⟨x.k,And.intro x.hk x.hk_max⟩,x.y⟩

lemma forget_map_inj : Function.Injective (forget_map X) := by
  sorry

variable (X) in
lemma 𝓓_finite : Finite (𝓓 X) := by
  sorry

-- Note: we might want to slightly adapt the construction so that there is only 1 tile at level S
-- with center `o` (then we might not cover all of `ball o (D ^ S)`, but most of it)
variable (X) in
/-- Proof that there exists a grid structure. -/
@[implicit_reducible]
def grid_existence : GridStructure X D κ S o where
  Grid := 𝓓 X
  fintype_Grid := @Fintype.ofFinite (𝓓 X) (𝓓_finite X)
  coeGrid := fun z => z.coe
  s := fun z => z.k
  c := fun z => z.y
  inj := fun ⟨k,hk,hk_max,y,hsub⟩ ⟨k2,hk2,hk2_max,y2,hsub'⟩ h => by
    simp only [Prod.mk.injEq, 𝓓.mk.injEq] at h hsub hsub' ⊢
    dsimp [𝓓.coe] at h hsub hsub'
    obtain ⟨hl, hr⟩ := h
    subst hr
    simp only [heq_eq_eq, true_and]
    apply I3_prop_1 hk2 (x := y)
    rw [← hl]
    simp only [inter_self]
    apply I3_prop_3_1
    simpa using by positivity [realD_pos a]
  range_s_subset i := by
    push _ ∈ _
    simp only [forall_exists_index]
    rintro x rfl
    use x.hk, x.hk_max
  topCube := max_𝓓 X
  s_topCube := rfl
  c_topCube := rfl
  subset_topCube := by
    intro i
    exact i.hsub
  Grid_subset_biUnion := by
    intro i l hl
    simp only [mem_Ico] at hl
    push _ ∈ _
    have : i.coe ⊆ (max_𝓓 X).coe := i.hsub
    intro x hx
    simp only [mem_iUnion, exists_prop]
    have : i.coe ⊆ ⋃ y', I3 hl.left y' := cover_by_cubes hl.left hl.right.le i.hk i.y
    specialize this hx
    simp only [mem_iUnion] at this
    obtain ⟨y', hy'⟩ := this
    have : I3 (hl.left) y' ⊆ (max_𝓓 X).coe := by
      apply dyadic_property
      · exact hl.right.le.trans i.hk_max
      · rw [Set.not_disjoint_iff]
        exact ⟨x, hy', this hx⟩
    use ⟨l,hl.left,hl.right.le.trans i.hk_max,y',this⟩
    simpa only [true_and]
  fundamental_dyadic' := by
    intro i j hk
    by_cases h : Disjoint i.coe j.coe
    · exact Or.inr h
    · exact Or.inl (dyadic_property i.hk hk j.hk j.y i.y h)
  ball_subset_Grid := by
    intro i
    apply Subset.trans (ball_subset_ball _) (I3_prop_3_1 i.hk i.y)
    rw [div_eq_mul_inv,mul_comm]
    gcongr
    norm_num
  Grid_subset_ball {i} := I3_prop_3_2 i.hk i.y
  small_boundary := by
    intro i t ht
    by_cases ht' : t < 1
    · apply boundary_measure' i.hk i.y
      · simp only [mem_Ioo]
        refine ⟨?_, ht'⟩
        apply lt_of_lt_of_le (zpow_pos (realD_pos a) _) ht
      rw [zpow_sub₀, div_le_iff₀] at ht
      · exact ht
      · exact zpow_pos (realD_pos a) _
      apply LT.lt.ne'
      exact realD_pos a
    · trans volume.real i.coe
      · apply measureReal_mono (fun x hx => hx.left) <|
          volume.mono (I3_prop_3_2 i.hk i.y) |>.trans_lt _ |>.ne
        simp only [OuterMeasure.measureOf_eq_coe, Measure.coe_toOuterMeasure]
        exact measure_ball_lt_top
      apply le_mul_of_one_le_left (measureReal_nonneg)
      have : 1 ≤ (t : ℝ) ^ κ := Real.one_le_rpow (le_of_not_gt ht') κ_nonneg
      linarith
  coeGrid_measurable {i} := I3_measurableSet i.hk i.y

/-! ## Proof that there exists a tile structure on a grid structure. -/

variable [GridStructure X D κ S o] {I : Grid X}

/-- The constant appearing in 4.2.2 (3 / 10). -/
@[simp] def C𝓩 : ℝ := 3 / 10

section
variable (I)

open scoped Classical in
def 𝓩_cands : Finset (Finset (Θ X)) :=
  Q.range.powerset.filter fun z ↦ (SetLike.coe z).PairwiseDisjoint (ball_{I} · C𝓩)

lemma exists_𝓩_max_card : ∃ zmax ∈ 𝓩_cands I, ∀ z ∈ 𝓩_cands I, z.card ≤ zmax.card := by
  sorry

/-- A finset of maximal cardinality satisfying (4.2.1) and (4.2.2). -/
def 𝓩 : Finset (Θ X) := (exists_𝓩_max_card I).choose

end

lemma 𝓩_spec : 𝓩 I ⊆ Q.range ∧ (SetLike.coe (𝓩 I)).PairwiseDisjoint (ball_{I} · C𝓩) ∧
    ∀ z ∈ 𝓩_cands I, z.card ≤ (𝓩 I).card := by
  sorry

lemma 𝓩_subset : 𝓩 I ⊆ Q.range := by
  sorry
lemma 𝓩_pairwiseDisjoint : (SetLike.coe (𝓩 I)).PairwiseDisjoint (ball_{I} · C𝓩) := by
  sorry
lemma 𝓩_max_card : ∀ z ∈ 𝓩_cands I, z.card ≤ (𝓩 I).card := by
  sorry

lemma 𝓩_nonempty : (𝓩 I).Nonempty := by
  sorry

instance : Inhabited (𝓩 I) := ⟨⟨_, 𝓩_nonempty.choose_spec⟩⟩

/-- 7 / 10 -/
@[simp] def C4_2_1 : ℝ := 7 / 10 /- 0.6 also works? -/

set_option backward.isDefEq.respectTransparency false in
/-- Equation (4.2.3), Lemma 4.2.1 -/
lemma frequency_ball_cover : (SetLike.coe Q.range) ⊆ ⋃ z ∈ 𝓩 I, ball_{I} z C4_2_1 := by
  sorry

local instance tileData_existence [GridStructure X D κ S o] : PreTileStructure Q D κ S o where
  𝔓 := Σ I : Grid X, 𝓩 I
  fintype_𝔓 := Sigma.instFintype
  𝓘 p := p.1
  surjective_𝓘 I := ⟨⟨I, default⟩, rfl⟩
  𝒬 p := p.2
  range_𝒬 := by rintro _ ⟨p, rfl⟩; rw [← SimpleFunc.mem_range]; exact 𝓩_subset p.2.2

namespace Construction

def Ω₁_aux (I : Grid X) (k : ℕ) : Set (Θ X) :=
  if hk : k < Nat.card (𝓩 I) then
    let z : Θ X := (Finite.equivFin (𝓩 I) |>.symm ⟨k, hk⟩).1
    ball_{I} z C4_2_1 \ (⋃ i ∈ SetLike.coe (𝓩 I) \ {z}, ball_{I} i C𝓩) \ ⋃ i < k, Ω₁_aux I i
  else ∅

lemma Ω₁_aux_disjoint (I : Grid X) {k l : ℕ} (hn : k ≠ l) : Disjoint (Ω₁_aux I k) (Ω₁_aux I l) := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma disjoint_ball_Ω₁_aux (I : Grid X) {z z' : Θ X} (hz : z ∈ 𝓩 I) (hz' : z' ∈ 𝓩 I) (hn : z ≠ z') :
    Disjoint (ball_{I} z' C𝓩) (Ω₁_aux I (Finite.equivFin (𝓩 I) ⟨z, hz⟩)) := by
  sorry

def Ω₁ (p : 𝔓 X) : Set (Θ X) := Ω₁_aux p.1 (Finite.equivFin (𝓩 p.1) p.2)

/-- Lemma 4.2.2 -/
lemma disjoint_frequency_cubes {f g : 𝓩 I} (h : (Ω₁ ⟨I, f⟩ ∩ Ω₁ ⟨I, g⟩).Nonempty) : f = g := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Equation (4.2.6), first inclusion -/
lemma ball_subset_Ω₁ (p : 𝔓 X) : ball_(p) (𝒬 p) C𝓩 ⊆ Ω₁ p := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Equation (4.2.6), second inclusion -/
lemma Ω₁_subset_ball (p : 𝔓 X) : Ω₁ p ⊆ ball_(p) (𝒬 p) C4_2_1 := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Equation (4.2.5) -/
lemma iUnion_ball_subset_iUnion_Ω₁ : ⋃ z ∈ 𝓩 I, ball_{I} z C4_2_1 ⊆ ⋃ f : 𝓩 I, Ω₁ ⟨I, f⟩ := by
  sorry

/-- 1 / 5 -/
@[simp] def CΩ : ℝ := 1 / 5

open scoped Classical in
def Ω (p : 𝔓 X) : Set (Θ X) :=
  if h : IsMax p.1 then Ω₁ p else
  have := Grid.opSize_succ_lt h
  ball_(p) (𝒬 p) CΩ ∪ ⋃ (z : Θ X) (hz : z ∈ SetLike.coe (𝓩 p.1.succ) ∩ Ω₁ p), Ω ⟨p.1.succ, ⟨z, hz.1⟩⟩
termination_by p.1.opSize

lemma 𝔓_induction (P : 𝔓 X → Prop) (base : ∀ p, IsMax p.1 → P p)
    (ind : ∀ p, ¬IsMax p.1 → (∀ z : 𝓩 p.1.succ, P ⟨p.1.succ, by exact z⟩) → P p) :
    ∀ p, P p := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma Ω_subset_cball {p : 𝔓 X} : Ω p ⊆ ball_(p) (𝒬 p) 1 := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma Ω_disjoint_aux {I : Grid X} (nmaxI : ¬IsMax I) {y z : 𝓩 I} (hn : y ≠ z) :
    Disjoint (ball_{I} y.1 CΩ)
      (⋃ z', ⋃ (x : z' ∈ SetLike.coe (𝓩 I.succ) ∩ Ω₁ ⟨I, z⟩), Ω ⟨I.succ, ⟨z', x.1⟩⟩) := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma Ω_disjoint {p p' : 𝔓 X} (hn : p ≠ p') (h𝓘 : 𝓘 p = 𝓘 p') : Disjoint (Ω p) (Ω p') := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma Ω_biUnion {I : Grid X} : SetLike.coe Q.range ⊆ ⋃ p ∈ 𝓘 ⁻¹' ({I} : Set (Grid X)), Ω p := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma Ω_RFD {p q : 𝔓 X} (h𝓘 : 𝓘 p ≤ 𝓘 q) : Disjoint (Ω p) (Ω q) ∨ Ω q ⊆ Ω p := by
  sorry

end Construction

variable (X) in
set_option backward.isDefEq.respectTransparency false in
@[implicit_reducible] def tile_existence : TileStructure Q D κ S o where
  Ω := Construction.Ω
  biUnion_Ω {I} := by rw [← SimpleFunc.coe_range]; exact Construction.Ω_biUnion
  disjoint_Ω := Construction.Ω_disjoint
  relative_fundamental_dyadic {p q} := Construction.Ω_RFD
  cball_subset {p} := by
    rw [Construction.Ω]; split_ifs with h
    · have : ball_(p) (𝒬 p) 5⁻¹ ⊆ ball_(p) (𝒬 p) C𝓩 := ball_subset_ball (by norm_num)
      exact this.trans (Construction.ball_subset_Ω₁ p)
    · simp
  subset_cball {p} := Construction.Ω_subset_cball
