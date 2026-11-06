/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Nimber.SimplestExtension.Closure
public import CombinatorialGames.Nimber.SimplestExtension.Polynomial
public import Mathlib.FieldTheory.IsAlgClosed.Basic

/-!
# Nimbers are algebraically closed

This file proves the last part of the simplest extension theorem (see
`CombinatorialGames.Nimber.SimplestExtension.Basic`), and deduces as a corollary that the nimbers
are algebraically closed.
-/

universe u

open Order Ordinal Polynomial Set

public section

namespace Nimber

/-! ### Lemmas relating rings to `leastNoRoots` -/

-- TODO: We're missing `IsRing.root_lt` which would avoid the duplication.
private theorem IsField.eval_eq_of_lt {n : ℕ} {x : Nimber} (h : IsField x)
    (h' : .some (X ^ n) ≤ leastNoRoots x) {p : Nimber[X]}
    (hpn : p.degree < n) (hpk : ∀ k, p.coeff k < x) : p.eval x = oeval x p := by
  sorry

theorem IsRing.eval_eq_of_lt {n : ℕ} {x : Nimber} (h : IsRing x)
    (h' : .some (X ^ n) ≤ leastNoRoots x) {p : Nimber[X]}
    (hpn : p.degree < n) (hpk : ∀ k, p.coeff k < x) : p.eval x = oeval x p := by
  sorry

theorem IsRing.pow_mul_eq {n : ℕ} {x y : Nimber} (h : IsRing x)
    (h' : .some (X ^ (n + 1)) ≤ leastNoRoots x) (hy : y < x) :
    x ^ n * y = ∗(x.val ^ n * y.val) := by
  sorry

theorem IsRing.pow_eq {n : ℕ} {x : Nimber} (h : IsRing x)
    (h' : .some (X ^ (n + 1)) ≤ leastNoRoots x) : x ^ n = ∗(x.val ^ n) := by
  sorry

proof_wanted leastNoRoots_omega0 : leastNoRoots (∗ω) = .some (X ^ 3 + C (∗2))

/-! ### Algebraically closed fields -/

/-- A nimber `x` is algebraically closed when `IsRing x`, and every non-constant polynomial in the
nimbers with coefficients less than `x` has a root that's less than `x`. Note that `0` and `1` are
algebraically closed under this definition.

For simplicity, the constructor takes a `0 < p.degree` assumption. The theorem
`IsAlgClosed.exists_root` proves that this theorem applies (vacuously) when `p = 0` as well. -/
structure IsAlgClosed (x : Nimber) extends IsField x where
  exists_root' ⦃p : Nimber[X]⦄ (hp₀ : 0 < p.degree) (hp : ∀ k, p.coeff k < x) : ∃ r < x, p.IsRoot r
  inv_lt' := (by
    intro y hy0 hyx
    let p : toIsRing.toSubring[X] := C ⟨y, hyx⟩ * X - 1
    have hpd : 0 < (p.map toIsRing.toSubring.subtype).degree :=
      degree_pos_of_root (ne_of_apply_ne (·.coeff 0) (by simp [p]))
        (show IsRoot _ y⁻¹ by simp [hy0, p])
    have hpp (k : ℕ) : (p.map toIsRing.toSubring.subtype).coeff k < x :=
      (coeff_map toIsRing.toSubring.subtype k).trans_lt (p.coeff k).2
    obtain ⟨r, hrx, hr⟩ := exists_root' hpd hpp
    refine Eq.trans_lt ?_ hrx
    simpa [sub_eq_zero, mul_eq_one_iff_inv_eq₀ hy0, p] using hr)

theorem IsAlgClosed.exists_root {x : Nimber} (h : IsAlgClosed x) {p : Nimber[X]}
    (hp₀ : p.degree ≠ 0) (hp : ∀ n, p.coeff n < x) : ∃ r < x, p.IsRoot r := by
  sorry

theorem IsAlgClosed.leastNoRoots_eq_top {x : Nimber} (h : IsAlgClosed x) :
    leastNoRoots x = ⊤ := by
  sorry

theorem isAlgClosed_iff_leastNoRoots_eq_top {x : Nimber} (h : IsRing x) :
    IsAlgClosed x ↔ leastNoRoots x = ⊤ := by
  sorry

protected theorem IsAlgClosed.sSup {s : Set Nimber} (H : ∀ x ∈ s, IsAlgClosed x)
    (ne : s.Nonempty) (bdd : BddAbove s) : IsAlgClosed (sSup s) := by
  sorry

protected theorem IsAlgClosed.iSup {ι} [Nonempty ι] {f : ι → Nimber} (H : ∀ i, IsAlgClosed (f i))
    (bdd : BddAbove (range f) := by apply Nimber.bddAbove_of_small) : IsAlgClosed (⨆ i, f i) :=
  IsAlgClosed.sSup (by simpa) (range_nonempty f) bdd

theorem IsAlgClosed.eval_eq_of_lt {x : Nimber} (h : IsAlgClosed x)
    {p : Nimber[X]} (hpk : ∀ k, p.coeff k < x) : p.eval x = oeval x p := by
  sorry

theorem IsAlgClosed.pow_mul_eq {n : ℕ} {x y : Nimber} (h : IsAlgClosed x) (hy : y < x) :
    x ^ n * y = ∗(x.val ^ n * y.val) := by
  sorry

theorem IsAlgClosed.pow_eq {n : ℕ} {x : Nimber} (h : IsAlgClosed x) :
    x ^ n = ∗(x.val ^ n) := by
  sorry

/-- If `x` is a field, to prove it algebraically closed, it suffices to check
*monic* polynomials. -/
theorem IsAlgClosed.ofMonic {x : Nimber} (h : IsField x)
    (hp : ∀ p : Nimber[X], p.Monic → 0 < p.degree → (∀ k, p.coeff k < x) → ∃ r < x, p.IsRoot r) :
    IsAlgClosed x := by
  sorry

attribute [simp] eval_prod eval_multiset_prod leadingCoeff_prod in
private theorem IsField.isRoot_leastNoRoots {x : Nimber} (h : IsField x) (ht) :
    (x.leastNoRoots.untop ht).IsRoot x := by
  sorry

/-- The fourth **simplest extension theorem**: if `x` is a ring that isn't algebraically closed,
then `x` is the root of some polynomial with coefficients `< x`. -/
theorem IsRing.isRoot_leastNoRoots {x : Nimber} (h : IsRing x) (ht) :
    (x.leastNoRoots.untop ht).IsRoot x := by
  sorry

theorem IsRing.pow_degree_leastNoRoots {x : Nimber} (h : IsRing x) (ht) {n : ℕ}
    (hn : (x.leastNoRoots.untop ht).degree = n) : IsRing (of (val x ^ n)) := by
  sorry

theorem IsField.pow_degree_leastNoRoots {x : Nimber} (hf : IsField x) (ht) {n : ℕ}
    (hn : (x.leastNoRoots.untop ht).degree = n) : IsField (of (val x ^ n)) := by
  sorry

theorem IsAlgClosed.isRing_opow_omega0 {t : Nimber} (ht : IsAlgClosed t) :
    IsRing (of (val t ^ ω)) := by
  sorry

/-! ### Nimbers are algebraically closed -/

open Pointwise

private instance (x : Nimber.{u}) : Small.{u} {p : Nimber[X] // ∀ k, p.coeff k < x} := by
  refine small_of_injective (β := ℕ → Iio x) (f := fun p k ↦ ⟨_, p.2 k⟩) fun p q h ↦ ?_
  ext k
  simpa using congrFun h k

/-- The set of roots of polynomials with coefficients less than `x`. -/
private def rootSet (x : Nimber) : Set Nimber :=
  ⋃ p : {p : Nimber[X] // ∀ k, p.coeff k < x}, p.1.roots.toFinset

private instance (x : Nimber.{u}) : Small.{u} x.rootSet :=
  small_iUnion _

/-- Returns the smallest `IsAlgClosed` that's at least `x`. -/
noncomputable def algClosure (x : Nimber) : Nimber :=
  sSup (succ '' rootSet x.fieldClosure)

mutual

private theorem isAlgebraic_of_not_isField {x y : Nimber} (h : y ≤ algClosure x)
    (hyf : ¬IsField y) : IsAlgebraic (IsField.fieldClosure x).toSubfield y := by
  obtain rfl | hy0 := eq_or_ne y 0
  · exact isAlgebraic_zero
  obtain rfl | hy1 := eq_or_ne y 1
  · exact isAlgebraic_one
  by_cases! hyg : ¬y.IsGroup
  · obtain ⟨y1, hy1, y2, hy2, rfl⟩ := exists_add_of_not_isGroup hyg hy0
    exact (isAlgebraic_of_lt (hy1.trans_le h)).add (isAlgebraic_of_lt (hy2.trans_le h))
  by_cases! hyr : ¬y.IsRing
  · obtain ⟨y1, hy1, y2, hy2, rfl⟩ := hyg.exists_mul_of_not_isRing hyr hy1
    exact (isAlgebraic_of_lt (hy1.trans_le h)).mul (isAlgebraic_of_lt (hy2.trans_le h))
  have hy := hyr.inv_lt_self_of_not_isField hyf
  exact inv_inv y ▸ (isAlgebraic_of_lt (hy.trans_le h)).inv
termination_by (y, 0)

private theorem isAlgebraic_of_leastNoRoots {x y : Nimber} (h : y ≤ x.algClosure)
    (ht : leastNoRoots y ≠ ⊤) : IsAlgebraic (IsField.fieldClosure x).toSubfield y := by
  by_cases! hyf : ¬y.IsField
  · exact isAlgebraic_of_not_isField h hyf
  by_cases! hxy : y < x.fieldClosure
  · exact isAlgebraic_algebraMap (R := IsField.toSubfield _) ⟨y, hxy⟩
  have hcf : x.fieldClosure.IsField := IsField.fieldClosure x
  let alg : Algebra hcf.toSubfield hyf.toSubfield :=
    (Subfield.inclusion (Iio_subset_Iio hxy)).toAlgebra
  have tower : IsScalarTower hcf.toSubfield hyf.toSubfield Nimber := ⟨fun _ _ _ => mul_assoc ..⟩
  have int : Algebra.IsAlgebraic hcf.toSubfield hyf.toSubfield :=
    ⟨fun z => have := z.2; (isAlgebraic_of_lt (z.2.trans_le h)).of_ringHom_of_comp_eq
      (RingHom.id _) (algebraMap _ _) Function.surjective_id (RingHom.injective _) rfl⟩
  refine IsAlgebraic.restrictScalars _
    ⟨hyf.embed (y.leastNoRoots.untop ht) (coeff_leastNoRoots_lt ht), ?_, ?_⟩
  · exact ne_of_apply_ne (Polynomial.map (Subfield.subtype _)) (by simp)
  · rw [aeval_def, Subfield.algebraMap_ofSubfield, eval₂_eq_eval_map, hyf.map_embed]
    exact hyf.isRoot_leastNoRoots ht
termination_by (y, 1)

private theorem isAlgebraic_of_lt {x y : Nimber} (h : y < algClosure x) :
    IsAlgebraic (IsField.fieldClosure x).toSubfield y := by
  by_cases! hyf : ¬y.IsField
  · exact isAlgebraic_of_not_isField h.le hyf
  by_cases! hxy : y < x.fieldClosure
  · exact isAlgebraic_algebraMap (R := IsField.toSubfield _) ⟨y, hxy⟩
  obtain ⟨c, hc, hyc⟩ : ∃ c ∈ x.fieldClosure.rootSet, y < succ c :=
    ((lt_csSup_iff' (bddAbove_of_small _)).trans exists_mem_image).1 h
  rw [rootSet, mem_iUnion] at hc
  obtain ⟨⟨p, hp⟩, hc⟩ := hc
  rw [SetLike.mem_coe, Multiset.mem_toFinset, mem_roots', IsRoot.def] at hc
  have int : IsIntegral hyf.toSubfield c := IsAlgebraic.isIntegral
    ⟨hyf.embed p fun k => (hp k).trans_le hxy,
      ne_of_apply_ne (Polynomial.map (Subfield.subtype _)) (by simp [hc.1]),
      by simp [aeval_def, Subfield.algebraMap_ofSubfield, eval₂_eq_eval_map, hc.2]⟩
  have ht : leastNoRoots y ≤ (minpoly hyf.toSubfield c).map (Subfield.subtype _) :=
    leastNoRoots_le_of_not_isRoot (by simp [minpoly.degree_pos int]) (by simp) fun r hr => by
      change ¬Polynomial.IsRoot _ (hyf.toSubfield.subtype ⟨r, hr⟩)
      rw [isRoot_map_iff (RingHom.injective _)]
      apply (minpoly.irreducible int).not_isRoot_of_natDegree_ne_one
      simp [minpoly.natDegree_eq_one_iff, Subfield.algebraMap_ofSubfield,
        mt succ_le_of_lt hyc.not_ge]
  exact isAlgebraic_of_leastNoRoots h.le (ne_of_lt (ht.trans_lt (WithTop.coe_lt_top _)))
termination_by (y, 2)

end

theorem lt_algClosure_iff_isAlgebraic {x y : Nimber} :
    y < algClosure x ↔ IsAlgebraic (IsField.fieldClosure x).toSubfield y := by
  sorry

@[simp]
theorem le_algClosure (x : Nimber) : x ≤ algClosure x := by
  sorry

theorem IsAlgClosed.algClosure (x : Nimber) : (algClosure x).IsAlgClosed := by
  sorry

theorem IsAlgClosed.algClosure_le_iff {x y : Nimber} (h : IsAlgClosed x) :
    y.algClosure ≤ x ↔ y ≤ x := by
  sorry

theorem IsAlgClosed.lt_algClosure_iff {x y : Nimber} (h : IsAlgClosed x) :
    x < y.algClosure ↔ x < y := by
  sorry

theorem algClosure_mono : Monotone algClosure := by
  sorry

/-- The nimbers are an algebraically closed field. -/
instance : _root_.IsAlgClosed Nimber := by
  refine .of_exists_root Nimber fun p _ hp ↦ ?_
  have hk (k : ℕ) : p.coeff k < algClosure (succ (p.support.sup p.coeff)) := Classical.byCases
    (fun hk => (lt_succ_iff.2 (Finset.le_sup hk)).trans_le (le_algClosure _))
    (fun hk => (notMem_support_iff.1 hk).trans_lt (IsAlgClosed.algClosure _).pos)
  obtain ⟨r, -, hr⟩ := (IsAlgClosed.algClosure _).exists_root hp.degree_pos.ne' hk
  exact ⟨r, hr⟩

/-- TODO: characterize the fields of nimbers below the first transcendental, get this as a
corollary. -/
proof_wanted algClosure_zero : algClosure 0 = ∗(ω ^ ω ^ ω)

/-! ### Square roots -/

/-- The square root of a nimber `x` is the unique value with `(√x)^2 = x`. -/
noncomputable def sqrt : Nimber ≃+* Nimber :=
  (frobeniusEquiv _ 2).symm

@[inherit_doc] scoped prefix:max "√" => sqrt
recommended_spelling "sqrt" for "√" in [sqrt, «term√_»]

theorem sqrt_zero : √0 = 0 := by
  sorry
theorem sqrt_one : √1 = 1 := by
  sorry
theorem sqrt_add (x y : Nimber) : √(x + y) = √x + √y := by
  sorry
theorem sqrt_mul (x y : Nimber) : √(x * y) = √x * √y := by
  sorry
theorem sqrt_inj {x y : Nimber} : √x = √y ↔ x = y := by
  sorry

@[simp] theorem sqrt_sq (x : Nimber) : √(x ^ 2) = x := by
  sorry
@[simp] theorem sq_sqrt (x : Nimber) : √x ^ 2 = x := by
  sorry
@[simp] theorem sqrt_self_mul_self (x : Nimber) : √(x * x) = x := by
  sorry
@[simp] theorem sqrt_mul_sqrt_self (x : Nimber) : √x * √x = x := by
  sorry

theorem sqrt_eq_iff {x y : Nimber} : √y = x ↔ x ^ 2 = y := by
  sorry

alias ⟨_, sqrt_eq⟩ := sqrt_eq_iff

theorem IsField.sqrt_lt {x y : Nimber} (h : IsField x) (hy : y < x)
    (hx : .some (X ^ 2 + C y) < leastNoRoots x) : √y < x := by
  sorry

theorem IsField.sqrt_lt' {x y : Nimber} (h : IsField x) (hy : y < x)
    (hx : .some (X ^ 2 + X) ≤ leastNoRoots x) : √y < x := by
  sorry

end Nimber
end
