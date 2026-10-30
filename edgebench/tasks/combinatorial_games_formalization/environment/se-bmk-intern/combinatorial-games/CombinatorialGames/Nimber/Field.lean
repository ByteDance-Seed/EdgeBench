/-
Copyright (c) 2024 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Nimber.Basic
public import Mathlib.Algebra.CharP.Two
public import Mathlib.Algebra.Field.Defs
public import Mathlib.Algebra.Ring.Int.Parity

import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.Abel
import Mathlib.Tactic.Ring

/-!
# Nimber multiplication and division

The nim product `a * b` is recursively defined as the least nimber not equal to any
`a' * b + a * b' + a' * b'` for `a' < a` and `b' < b`. When endowed with this operation, the nimbers
form a field.

It's possible to show the existence of the nimber inverse implicitly via the simplest extension
theorem. Instead, we employ the explicit formula given in [On Numbers And Games][conway2001]
(p. 56), which uses mutual induction and mimics the definition for the surreal inverse. This
definition `invAux` "accidentally" gives the inverse of `0` as `1`, which the real inverse corrects.
-/

universe u v

open Function Order

public noncomputable section

namespace Nimber

/-! ### Nimber multiplication -/

variable {a b c : Nimber.{u}}

instance : CharP Nimber 2 := by
  apply CharTwo.of_one_ne_zero_of_two_eq_zero one_ne_zero
  rw [← one_add_one_eq_two, add_self]

private theorem two_zsmul (x : Nimber) : (2 : ℤ) • x = 0 := by
  sorry

private theorem add_eq_iff_eq_add : a + b = c ↔ a = c + b := by
  sorry

-- We write the binders like this so that the termination checker works.
private def mul (a b : Nimber.{u}) : Nimber.{u} :=
  sInf {x | ∃ a', ∃ (_ : a' < a), ∃ b', ∃ (_ : b' < b),
    Nimber.mul a' b + Nimber.mul a b' + Nimber.mul a' b' = x}ᶜ
termination_by (a, b)

#adaptation_note /-- noncomputable is now needed -/ in
/-- Nimber multiplication is recursively defined so that `a * b` is the smallest nimber not equal to
`a' * b + a * b' + a' * b'` for `a' < a` and `b' < b`. -/
@[no_expose]
noncomputable instance : Mul Nimber :=
  ⟨Nimber.mul⟩

theorem mul_def (a b : Nimber) :
    a * b = sInf {x | ∃ a' < a, ∃ b' < b, a' * b + a * b' + a' * b' = x}ᶜ := by
  sorry

/-- The set in the definition of `Nimber.mul` is nonempty. -/
private theorem mul_nonempty (a b : Nimber.{u}) :
    {x | ∃ a' < a, ∃ b' < b, a' * b + a * b' + a' * b' = x}ᶜ.Nonempty := by
  sorry

theorem exists_of_lt_mul (h : c < a * b) : ∃ a' < a, ∃ b' < b, a' * b + a * b' + a' * b' = c := by
  sorry

theorem mul_le_of_forall_ne (h : ∀ a' < a, ∀ b' < b, a' * b + a * b' + a' * b' ≠ c) :
    a * b ≤ c := by
  sorry

instance : MulZeroClass Nimber where
  mul_zero a := by
    rw [← Nimber.le_zero]
    exact mul_le_of_forall_ne fun _ _ _ h ↦ (Nimber.not_neg _ h).elim
  zero_mul a := by
    rw [← Nimber.le_zero]
    exact mul_le_of_forall_ne fun _ h ↦ (Nimber.not_neg _ h).elim

private theorem mul_ne_of_lt {a' : Nimber} (ha : a' < a) {b' : Nimber} (hb : b' < b) :
    a' * b + a * b' + a' * b' ≠ a * b := by
  sorry

instance : NoZeroDivisors Nimber where
  eq_zero_or_eq_zero_of_mul_eq_zero {a b} h := by
    by_contra! hab
    iterate 2 rw [← Nimber.pos_iff_ne_zero] at hab
    apply (mul_ne_of_lt hab.1 hab.2).symm
    simpa only [zero_add, mul_zero, zero_mul]

protected theorem mul_comm (a b : Nimber) : a * b = b * a := by
  sorry

protected theorem mul_add (a b c : Nimber) : a * (b + c) = a * b + a * c := by
  sorry

protected theorem add_mul (a b c : Nimber) : (a + b) * c = a * c + b * c := by
  sorry

private theorem add_ne_zero_of_lt {a b : Nimber} (h : b < a) : a + b ≠ 0 := by
  sorry

protected theorem mul_assoc (a b c : Nimber) : a * b * c = a * (b * c) := by
  sorry

instance : IsCancelMulZero Nimber where
  mul_left_cancel_of_ne_zero ha a b h := by
    rw [← add_eq_zero, ← Nimber.mul_add, mul_eq_zero] at h
    exact add_eq_zero.1 (h.resolve_left ha)
  mul_right_cancel_of_ne_zero ha a b h := by
    rw [← add_eq_zero, ← Nimber.add_mul, mul_eq_zero] at h
    exact add_eq_zero.1 (h.resolve_right ha)

protected theorem one_mul (a : Nimber) : 1 * a = a := by
  sorry

protected theorem mul_one (a : Nimber) : a * 1 = a := by
  sorry

instance : CommRing Nimber where
  left_distrib := Nimber.mul_add
  right_distrib := Nimber.add_mul
  zero_mul := zero_mul
  mul_zero := mul_zero
  mul_assoc := Nimber.mul_assoc
  mul_comm := Nimber.mul_comm
  one_mul := Nimber.one_mul
  mul_one := Nimber.mul_one
  __ : AddCommGroupWithOne Nimber := inferInstance

instance : IsDomain Nimber where

theorem mul_ne_of_ne {a' b' : Nimber} (ha : a' ≠ a) (hb : b' ≠ b) :
    a' * b + a * b' + a' * b' ≠ a * b := by
  sorry

-- TODO: upstream
theorem _root_.Fin.comp_cons_apply {α β} {n : ℕ}
    (g : α → β) (a : α) (f : Fin n → α) (i : Fin (n + 1)) :
    g (Fin.cons (α := fun _ ↦ α) a f i) = Fin.cons (α := fun _ ↦ β) (g a) (g ∘ f) i := by
  sorry

theorem pow_le_of_forall_ne {a b : Nimber} {n : ℕ}
    (H : ∀ f : Fin n → Set.Iio a, a ^ n + ∏ i, (a + f i) ≠ b) : a ^ n ≤ b := by
  sorry

/-! ### Nimber division -/

mutual

/-- The nimber inverse `a⁻¹` is mutually recursively defined as the smallest nimber not in the set
`s = invSet a`, which itself is defined as the smallest set with `0 ∈ s` and
`(1 + (a + a') * b) / a' ∈ s` for `0 < a' < a` and `b ∈ s`.

This preliminary definition "accidentally" satisfies `invAux 0 = 1`, which the real inverse
corrects. The lemma `inv_eq_invAux` can be used to transfer between the two. -/
def invAux (a : Nimber) : Nimber :=
  sInf (invSet a)ᶜ
termination_by (a, 1)

/-- The set in the definition of `invAux a`. -/
def invSet (a : Nimber) : Set Nimber :=
  ⋂₀ {s | 0 ∈ s ∧ ∀ a' < a, a' ≠ 0 → ∀ b ∈ s, invAux a' * (1 + (a + a') * b) ∈ s}
termination_by (a, 0)

end

theorem zero_mem_invSet (a : Nimber) : 0 ∈ invSet a := by
  sorry

/-- "cons" is our operation `(1 + (a + a') * b) / a'` in the definition of the inverse. -/
theorem cons_mem_invSet {a' : Nimber} (ha₀ : a' ≠ 0) (ha : a' < a) (hb : b ∈ invSet a) :
    invAux a' * (1 + (a + a') * b) ∈ invSet a := by
  sorry

/-- A recursion principle for `invSet`. -/
@[elab_as_elim]
theorem invSet_recOn {p : Nimber → Prop} (a : Nimber) (h0 : p 0)
    (hi : ∀ a' < a, a' ≠ 0 → ∀ b, p b → p (invAux a' * (1 + (a + a') * b))) (x : Nimber)
    (hx : x ∈ invSet a) : p x := by
  sorry

/-- An enumeration of elements in `invSet` by a type in the same universe. -/
private def List.toNimber {a : Nimber} : List a.val.ToType → Nimber
  | [] => 0
  | x :: l => invAux (∗x) * (1 + (a + ∗x) * toNimber l)

instance (a : Nimber.{u}) : Small.{u} (invSet a) := by
  refine @small_subset.{u, u + 1} _ _ _ ?_ (small_range (@List.toNimber a))
  refine fun x hx ↦ invSet_recOn a ⟨[], rfl⟩ ?_ x hx
  rintro a' ha _ _ ⟨l, rfl⟩
  use Ordinal.ToType.mk ⟨val a', ha⟩ :: l
  rw [List.toNimber]
  simp

/-- The complement of `invSet a` is nonempty. -/
private theorem invSet_nonempty (a : Nimber) : (invSet a)ᶜ.Nonempty := by
  sorry

theorem invAux_ne_zero (a : Nimber) : invAux a ≠ 0 := by
  sorry

theorem mem_invSet_of_lt_invAux (h : b < invAux a) : b ∈ invSet a := by
  sorry

theorem invAux_notMem_invSet (a : Nimber) : invAux a ∉ invSet a := by
  sorry

theorem invAux_mem_invSet_of_lt (ha : a ≠ 0) (hb : a < b) : invAux a ∈ invSet b := by
  sorry

/-- We set up a simultaneous induction to prove that `invAux a` is the inverse of `a`, and no
element in its defining set `invSet a` is. -/
private theorem mul_inv_cancel_aux (a : Nimber) :
    (∀ b ∈ invSet a, a * b ≠ 1) ∧ (a ≠ 0 → a * invAux a = 1) := by
  sorry

theorem mul_invAux_cancel (h : a ≠ 0) : a * invAux a = 1 := by
  sorry

instance : Inv Nimber where
  inv a := if a = 0 then 0 else invAux a

theorem inv_eq_invAux (ha : a ≠ 0) : a⁻¹ = invAux a := by
  sorry

instance : Field Nimber where
  mul_inv_cancel a ha := by rw [inv_eq_invAux ha, mul_invAux_cancel ha]
  inv_zero := dif_pos rfl
  nnqsmul := _
  qsmul := _

-- TODO: PR this
section Mathlib

@[simp]
theorem inv_natCast (n : ℕ) : (n : Nimber)⁻¹ = n := by
  sorry

@[simp]
theorem inv_intCast (n : ℤ) : (n : Nimber)⁻¹ = n := by
  sorry

theorem ratCast_eq_if (q : ℚ) : (q : Nimber) = if Odd q.num ∧ Odd q.den then 1 else 0 := by
  sorry

@[simp]
theorem range_ratCast : Set.range ((↑) : ℚ → Nimber) = {0, 1} := by
  sorry

end Mathlib
end Nimber
