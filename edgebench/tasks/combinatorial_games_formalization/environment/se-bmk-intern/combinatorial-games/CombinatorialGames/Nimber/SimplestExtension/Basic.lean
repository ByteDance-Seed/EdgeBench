/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios, Daniel Weber
-/
module

public import CombinatorialGames.Nimber.Field
public import Mathlib.Algebra.Field.Subfield.Basic
public import Mathlib.SetTheory.Ordinal.Exponential

import Mathlib.Algebra.Order.Monoid.Canonical.Basic
import Mathlib.SetTheory.Ordinal.Principal

/-!
# Simplest extension theorems

We say that a nimber `x` is a group when the lower set `Iio x` is closed under addition. Likewise,
we say that `x` is a ring when `Iio x` is closed under addition and multiplication, and we say that
`x` is a field when it's closed under addition, multiplication, and division.

The simplest extension theorem states:

- If `x` is not a group, then `x` can be written as `y + z` for some `y, z < x`.
- If `x` is a group but not a ring, then `x` can be written as `y * z` for some `y, z < x`.
- If `x` is a ring but not a field, then `x` can be written as `y⁻¹` for some `y < x`.
- If `x` is a field that isn't algebraically closed, then `x` is the root of some polynomial with
  coefficients `< x`.

This file proves the first 3/4 parts of the theorem. The last part will be proven in
`CombinatorialGames.Nimber.SimplestExtension.Algebraic`.

The proof follows Aaron Siegel's Combinatorial Games, pp. 440-444.
-/

open Order Ordinal Set

@[expose] public section

/-! ### Order lemmas -/

theorem Maximal.isGreatest {α : Type*} [LinearOrder α] {P : α → Prop} {x : α} (h : Maximal P x) :
    IsGreatest {y | P y} x := by
  sorry

/-! #### Ordinal lemmas -/

namespace Ordinal

theorem mul_add_lt {a b c d : Ordinal} (h₁ : c < a) (h₂ : b < d) : a * b + c < a * d := by
  sorry

-- TODO: come up with a better name, probably rename `log_eq_zero` while we're at it.
theorem log_eq_zero' {b x : Ordinal} (hb : b ≤ 1) : log b x = 0 := by
  sorry

theorem log_eq_zero_iff {b x : Ordinal} : log b x = 0 ↔ b ≤ 1 ∨ x < b := by
  sorry

end Ordinal

namespace Nimber
variable {x y z w : Nimber}

/-! ### Groups -/

/-- A nonzero nimber `x` is a group when `Iio x` is closed under addition. -/
@[mk_iff]
structure IsGroup (x : Nimber) where
  add_lt ⦃y z : Nimber⦄ (hy : y < x) (hz : z < x) : y + z < x
  ne_zero : x ≠ 0

theorem IsGroup.neZero (h : IsGroup x) : NeZero x := by
  sorry

@[aesop forward safe]
theorem IsGroup.zero_lt (h : IsGroup x) : 0 < x := by
  sorry
alias IsGroup.pos := IsGroup.zero_lt

theorem IsGroup.sum_lt (h : IsGroup x) {ι} {s : Finset ι}
    {f : ι → Nimber} (hs : ∀ y ∈ s, f y < x) : s.sum f < x := by
  sorry

/-- `Iio x` as a subgroup of `Nimber`. -/
def IsGroup.toAddSubgroup (h : IsGroup x) : AddSubgroup Nimber where
  carrier := Iio x
  zero_mem' := h.zero_lt
  add_mem' := @h.add_lt
  neg_mem' := id

@[simp] theorem val_toAddSubgroup_lt (h : IsGroup x) (y : h.toAddSubgroup) : y < x := by
  sorry
@[simp] theorem mem_toAddSubgroup_iff (h : IsGroup x) : y ∈ h.toAddSubgroup ↔ y < x := by
  sorry

theorem IsGroup.closure_Iio (h : IsGroup x) : AddSubgroup.closure (Iio x) = h.toAddSubgroup := by
  sorry

@[simp]
theorem IsGroup.one : IsGroup 1 := by
  sorry

protected theorem IsGroup.sSup {s : Set Nimber} (H : ∀ x ∈ s, IsGroup x)
    (ne : s.Nonempty) (bdd : BddAbove s) : IsGroup (sSup s) := by
  sorry

protected theorem IsGroup.iSup {ι} [Nonempty ι] {f : ι → Nimber} (H : ∀ i, IsGroup (f i))
    (bdd : BddAbove (range f) := by apply Nimber.bddAbove_of_small) : IsGroup (⨆ i, f i) :=
  .sSup (by simpa) (range_nonempty f) bdd

theorem IsGroup.le_add_self (h : IsGroup x) (hy : y < x) : x ≤ x + y := by
  sorry

/-- The first **simplest extension theorem**: if `x ≠ 0` is not a group, then `x` can be written as
`y + z` for some `y, z < x`. -/
theorem exists_add_of_not_isGroup (h : ¬IsGroup x) (ne : x ≠ 0) : ∃ y < x, ∃ z < x, y + z = x := by
  sorry

/-- A version of `IsGroup.mul_add_eq_of_lt` stated in terms of `Ordinal`. -/
theorem IsGroup.mul_add_eq_of_lt' {x y : Ordinal} (h : IsGroup (∗x)) (hy : y < x) (z : Ordinal) :
    ∗(x * z + y) = ∗(x * z) + ∗y := by
  sorry

theorem IsGroup.mul_add_eq_of_lt (h : IsGroup x) (hy : y < x) (z : Ordinal) :
    ∗(x.val * z + y.val) = ∗(x.val * z) + y := by
  sorry

theorem IsGroup.add_eq_of_lt (h : IsGroup x) (hy : y < x) : ∗(x.val + y.val) = x + y := by
  sorry

/-- A version of `IsGroup.add_eq_of_lt` stated in terms of `Ordinal`. -/
theorem IsGroup.add_eq_of_lt' {x y : Ordinal} (h : IsGroup (∗x)) (hy : y < x) :
    x + y = val (∗x + ∗y) := by
  sorry

@[simp]
theorem IsGroup.two_opow (x : Ordinal) : IsGroup (∗2 ^ x) := by
  sorry

@[simp]
theorem IsGroup.omega0_opow (x : Ordinal) : IsGroup (∗ω ^ x) := by
  sorry

@[simp] theorem IsGroup.two : IsGroup (∗2) := by
  sorry

theorem two_opow_log_add {o : Ordinal} (ho : o ≠ 0) : ∗(2 ^ log 2 o) + ∗(o % 2 ^ log 2 o) = ∗o := by
  sorry

theorem add_lt_of_log_eq {a b : Ordinal} (ha₀ : a ≠ 0) (hb₀ : b ≠ 0) (h : log 2 a = log 2 b) :
    ∗a + ∗b < ∗2 ^ log 2 a := by
  sorry

theorem exists_isGroup_add_lt (hx : x ≠ 0) : ∃ y ≤ x, IsGroup y ∧ x + y < y := by
  sorry

/-- The nimbers that are groups are exactly the powers of `2`. -/
theorem isGroup_iff_mem_range_two_opow : IsGroup x ↔ x ∈ range fun y : Ordinal ↦ ∗2 ^ y := by
  sorry

/-- A version of `isGroup_iff_zero_or_mem_range_two_opow` stated in terms of `Ordinal`. -/
theorem isGroup_iff_zero_or_mem_range_two_opow' {x : Ordinal} :
    IsGroup (∗x) ↔ x ∈ range (2 ^ · : Ordinal → _) := by
  sorry

theorem IsGroup.opow (h : IsGroup x) (a : Ordinal) : IsGroup (∗x.val ^ a) := by
  sorry

/-- A version of `IsGroup.opow` stated in terms of `Ordinal`. -/
theorem IsGroup.opow' {x : Ordinal} (h : IsGroup (∗x)) (a : Ordinal) : IsGroup (∗x ^ a) := by
  sorry

theorem IsGroup.pow (h : IsGroup x) (n : ℕ) : IsGroup (∗x.val ^ n) := by
  sorry

/-- A version of `IsGroup.pow` stated in terms of `Ordinal`. -/
theorem IsGroup.pow' {x : Ordinal} (h : IsGroup (∗x)) (n : ℕ) : IsGroup (∗x ^ n) := by
  sorry

/-! ### Rings -/

/-- A nimber `x` is a ring when `1 < x` and `Iio x` is closed under addition and multiplication. -/
@[mk_iff]
structure IsRing (x : Nimber) extends IsGroup x where
  mul_lt ⦃y z : Nimber⦄ (hy : y < x) (hz : z < x) : y * z < x
  ne_one : x ≠ 1

attribute [aesop forward safe] IsRing.toIsGroup

@[aesop forward safe]
theorem IsRing.one_lt (h : IsRing x) : 1 < x := by
  sorry

theorem IsRing.pow_lt (h : IsRing x) {n : ℕ} (hy : y < x) :
    y ^ n < x := by
  sorry

@[simp]
theorem IsRing.two : IsRing (∗2) := by
  sorry

/-- `Iio x` as a subring of `Nimber`. -/
def IsRing.toSubring (h : IsRing x) : Subring Nimber where
  toAddSubgroup := h.toAddSubgroup
  one_mem' := h.one_lt
  mul_mem' := @h.mul_lt

@[simp] theorem val_toSubring_lt (h : IsRing x) (y : h.toSubring) : y < x := by
  sorry
@[simp] theorem mem_toSubring_iff (h : IsRing x) : y ∈ h.toSubring ↔ y < x := by
  sorry

theorem IsRing.closure_Iio (h : IsRing x) : Subring.closure (Iio x) = h.toSubring := by
  sorry

protected theorem IsRing.sSup {s : Set Nimber} (H : ∀ x ∈ s, IsRing x)
    (ne : s.Nonempty) (bdd : BddAbove s) : IsRing (sSup s) := by
  sorry

protected theorem IsRing.iSup {ι} [Nonempty ι] {f : ι → Nimber} (H : ∀ i, IsRing (f i))
    (bdd : BddAbove (range f) := by apply Nimber.bddAbove_of_small) : IsRing (⨆ i, f i) :=
  .sSup (by simpa) (range_nonempty f) bdd

theorem IsGroup.mul_le_of_forall_lt (h : IsGroup x) {y z : Nimber}
    (hyl : ∀ l < z, y * l < x) (hrz : ∀ r < y, r * z < x)
    (hrl : ∀ r < y, ∀ l < z, r * l < x) : y * z ≤ x := by
  sorry

/-- The second **simplest extension theorem**: if `x ≠ 1` is a group but not a ring, then `x` can be
written as `y * z` for some `y, z < x`. -/
theorem IsGroup.exists_mul_of_not_isRing (h' : IsGroup x) (h : ¬IsRing x) (ne : x ≠ 1) :
    ∃ y < x, ∃ z < x, y * z = x := by
  sorry

/-- A version of `IsGroup.mul_eq_of_lt` stated in terms of `Ordinal`. -/
theorem IsGroup.mul_eq_of_lt' {x y z w : Ordinal}
    (hx : IsGroup (∗x)) (hy : IsGroup (∗y)) (hz : IsGroup (∗z))
    (hyx : y ≤ x) (hyz : y ≤ z) (hwy : w < y)
    (H : ∀ a < y, (∗a)⁻¹ < ∗z) (H' : ∀ ⦃a b⦄, a < x → b < z → ∗a * ∗b < ∗x) :
    x * w = val (∗x * ∗w) := by
  sorry

theorem IsGroup.mul_eq_of_lt (hx : IsGroup x) (hy : IsGroup y) (hz : IsGroup z)
    (hyx : y ≤ x) (hyz : y ≤ z) (hwy : w < y)
    (H : ∀ a < y, a⁻¹ < z) (H' : ∀ ⦃a b⦄, a < x → b < z → a * b < x) : ∗(x.val * w.val) = x * w := by
  sorry

/-- A version of `IsRing.mul_eq_of_lt` stated in terms of `Ordinal`. -/
theorem IsRing.mul_eq_of_lt' {x y z : Ordinal} (hx : IsRing (∗x)) (hy : IsGroup (∗y))
    (hyx : y ≤ x) (hzy : z < y) (H : ∀ z < y, (∗z)⁻¹ < ∗x) : x * z = val (∗x * ∗z) := by
  sorry

theorem IsRing.mul_eq_of_lt (hx : IsRing x) (hy : IsGroup y)
    (hyx : y ≤ x) (hzy : z < y) (H : ∀ z < y, z⁻¹ < x) : ∗(x.val * z.val) = x * z := by
  sorry

-- TODO: characterize nim arithmetic on the naturals.
proof_wanted IsRing.two_two_pow (n : ℕ) : IsRing (∗(2 ^ 2 ^ n))

/-! ### Fields -/

/-- A nimber `x` is a field when `1 < x` and `Iio x` is closed under
addition, multiplication, and division.

For simplicity, the constructor takes a redundant `y ≠ 0` assumption. The lemma `IsField.inv_lt`
proves that this theorem applies when `y = 0` as well. -/
@[mk_iff]
structure IsField (x : Nimber) extends IsRing x where
  inv_lt' ⦃y : Nimber⦄ (hy₀ : y ≠ 0) (hy : y < x) : y⁻¹ < x

attribute [aesop forward safe] IsField.toIsRing

theorem IsField.inv_lt (h : IsField x) (hy : y < x) : y⁻¹ < x := by
  sorry

theorem IsField.div_lt (h : IsField x) (hy : y < x) (hz : z < x) : y / z < x := by
  sorry

@[simp]
theorem IsField.two : IsField (∗2) := by
  sorry

/-- `Iio x` as a subring of `Nimber`. -/
def IsField.toSubfield (h : IsField x) : Subfield Nimber where
  toSubring := h.toSubring
  inv_mem' := @h.inv_lt

@[simp] theorem val_toSubfield_lt (h : IsField x) (y : h.toSubfield) : y < x := by
  sorry
@[simp] theorem mem_toSubfield_iff (h : IsField x) : y ∈ h.toSubfield ↔ y < x := by
  sorry

theorem IsField.closure_Iio (h : IsField x) : Subfield.closure (Iio x) = h.toSubfield := by
  sorry

protected theorem IsField.sSup {s : Set Nimber} (H : ∀ x ∈ s, IsField x)
    (ne : s.Nonempty) (bdd : BddAbove s) : IsField (sSup s) := by
  sorry

protected theorem IsField.iSup {ι} [Nonempty ι] {f : ι → Nimber} (H : ∀ i, IsField (f i))
    (bdd : BddAbove (range f) := by apply Nimber.bddAbove_of_small) : IsField (⨆ i, f i) :=
  .sSup (by simpa) (range_nonempty f) bdd

theorem IsField.mul_eq_of_lt (hx : IsRing x) (hy : IsField y) (hyx : y ≤ x) (hzy : z < y) :
    ∗(x.val * z.val) = x * z := by
  sorry

/-- A version of `IsField.mul_eq_of_lt` stated in terms of `Ordinal`. -/
theorem IsField.mul_eq_of_lt' {x y z : Ordinal} (hx : IsRing (∗x)) (hy : IsField (∗y))
    (hyx : y ≤ x) (hzy : z < y) : x * z = val (∗x * ∗z) := by
  sorry

private theorem inv_lt_of_not_isField_aux (h' : IsRing x) (h : ¬IsField x) :
    x⁻¹ < x ∧ ∀ y < x⁻¹, y⁻¹ < x := by
  sorry

theorem IsRing.inv_lt_of_not_isField (h' : IsRing x) (h : ¬ IsField x)
    (hy : y < x⁻¹) : y⁻¹ < x := by
  sorry

theorem IsRing.inv_le_of_not_isField (h' : IsRing x) (h : ¬ IsField x)
    (hy : y ≤ x⁻¹) : y⁻¹ ≤ x := by
  sorry

/-- The third **simplest extension theorem**: if `x` is a ring but not a field, then `x` can be
written as `y⁻¹` for some `y < x`. In simpler wording, `x⁻¹ < x`. -/
theorem IsRing.inv_lt_self_of_not_isField (h' : IsRing x) (h : ¬ IsField x) : x⁻¹ < x := by
  sorry

/-- A version of `IsField.opow_mul_eq_of_lt` stated in terms of `Ordinal`. -/
theorem IsField.opow_mul_eq_of_lt' {x z : Ordinal}
    (hx : IsField (∗x)) (y : Ordinal) (hz : z < x) : x ^ y * z = val (∗(x ^ y) * ∗z) := by
  sorry

theorem IsField.opow_mul_eq_of_lt (hx : IsField x) (y : Ordinal) (hz : z < x) :
    ∗(val x ^ y * val z) = ∗(val x ^ y) * z := by
  sorry

/-- A version of `IsField.pow_mul_eq_of_lt` stated in terms of `Ordinal`. -/
theorem IsField.pow_mul_eq_of_lt' {x z : Ordinal}
    (hx : IsField (∗x)) (n : ℕ) (hz : z < x) : x ^ n * z = val (∗(x ^ n) * ∗z) := by
  sorry

theorem IsField.pow_mul_eq_of_lt
    (hx : IsField x) (n : ℕ) (hz : z < x) : ∗(val x ^ n * val z) = ∗(val x ^ n) * z := by
  sorry

/-- If `x` is a field and `y` is an `x`-subspace, then `y` is an ordinal power of `x`. -/
theorem IsField.opow_log_eq_of_isGroup (hx : IsField x) (hy : IsGroup y)
    (hxy : ∀ z w, z < x → w < y → z * w < y) : ∗(x.val ^ log x.val y.val) = y := by
  sorry

/-- If `x` is a field and `y` is a ring with `x ≤ y`, then `y` is an ordinal power of `x`. -/
theorem IsField.opow_log_eq_of_isRing (hx : IsField x) (hy : IsRing y) (hxy : x ≤ y) :
    ∗(x.val ^ log x.val y.val) = y := by
  sorry

theorem IsField.mul_lt_opow_of_left_lt {x y z : Nimber} {o : Ordinal}
    (h : IsField x) (hy : y < x) (hz : z < ∗(val x ^ o)) : y * z < ∗(val x ^ o) := by
  sorry

theorem IsField.mul_lt_opow_of_right_lt {x y z : Nimber} {o : Ordinal}
    (h : IsField x) (hy : y < ∗(val x ^ o)) (hz : z < x) : y * z < ∗(val x ^ o) := by
  sorry

theorem IsField.mul_lt_pow_of_left_lt {x y z : Nimber} {n : ℕ}
    (h : IsField x) (hy : y < x) (hz : z < ∗(val x ^ n)) : y * z < ∗(val x ^ n) := by
  sorry

theorem IsField.mul_lt_pow_of_right_lt {x y z : Nimber} {n : ℕ}
    (h : IsField x) (hy : y < ∗(val x ^ n)) (hz : z < x) : y * z < ∗(val x ^ n) := by
  sorry

-- TODO: this follows from `IsRing.two_two_pow` and the surjectivity of `a * ·` for `a ≠ 0`.
proof_wanted IsField.two_two_pow (n : ℕ) : IsField (∗(2 ^ 2 ^ n))

end Nimber
end
