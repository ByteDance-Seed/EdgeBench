/-
Copyright (c) 2022 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import Mathlib.SetTheory.Ordinal.Family

import CombinatorialGames.Tactic.OrdinalAlias
import Mathlib.Tactic.Abel

/-!
# Natural operations on ordinals

The goal of this file is to define natural addition and multiplication on ordinals, also known as
the Hessenberg sum and product, and provide a basic API. The natural addition of two ordinals
`a + b` is recursively defined as the least ordinal greater than `a' + b` and `a + b'` for `a' < a`
and `b' < b`. The natural multiplication `a * b` is likewise recursively defined as the least
ordinal such that `a * b + a' * b'` is greater than `a' * b + a * b'` for any `a' < a` and
`b' < b`.

These operations give the ordinals a `CommSemiring` + `IsStrictOrderedRing` structure. To make the
best use of it, we define them on a type alias `NatOrdinal`.

An equivalent characterization explains the relevance of these operations to game theory: they are
the restrictions of surreal addition and multiplication to the ordinals.

## Implementation notes

To reduce API duplication, we opt not to implement operations on `NatOrdinal` on `Ordinal`. The
order isomorphisms `NatOrdinal.of` and `NatOrdinal.val` allow us to cast between them whenever
needed.

For similar reasons, most results about ordinals and games are written using `NatOrdinal` rather
than `Ordinal` (except when `Nimber` would make more sense).
-/

universe u v

open Order Set

public noncomputable section

/-! ### Basic casts between `Ordinal` and `NatOrdinal` -/

ordinal_alias!
  /-- A type synonym for ordinals with natural addition and multiplication. -/ NatOrdinal

namespace NatOrdinal

variable {a b c d a' b' c' : NatOrdinal.{u}}

/-! ### Natural addition -/

private def add (a b : NatOrdinal.{u}) : NatOrdinal.{u} :=
  max (⨆ x : Iio a, succ (add x.1 b)) (⨆ x : Iio b, succ (add a x.1))
termination_by (a, b)
decreasing_by all_goals cases x; decreasing_tactic

#adaptation_note /-- noncomputable is now needed -/ in
/-- Natural addition on ordinals `a + b`, also known as the Hessenberg sum, is recursively defined
as the least ordinal greater than `a' + b` and `a + b'` for all `a' < a` and `b' < b`. In contrast
to normal ordinal addition, it is commutative.

Natural addition can equivalently be characterized as the ordinal resulting from adding up
corresponding coefficients in the Cantor normal forms of `a` and `b`. -/
@[no_expose] noncomputable instance : Add NatOrdinal := ⟨add⟩

theorem add_def (a b : NatOrdinal) :
    a + b = max (⨆ x : Iio a, succ (x.1 + b)) (⨆ x : Iio b, succ (a + x.1)) := by
  sorry

theorem lt_add_iff : a < b + c ↔ (∃ b' < b, a ≤ b' + c) ∨ ∃ c' < c, a ≤ b + c' := by
  sorry

theorem add_le_iff : b + c ≤ a ↔ (∀ b' < b, b' + c < a) ∧ ∀ c' < c, b + c' < a := by
  sorry

instance : AddLeftStrictMono NatOrdinal where
  elim _a _b _c h := lt_add_iff.2 (.inr ⟨_, h, le_rfl⟩)

instance : AddRightStrictMono NatOrdinal where
  elim _a _b _c h := lt_add_iff.2 (.inl ⟨_, h, le_rfl⟩)

instance : AddLeftMono NatOrdinal :=
  addLeftMono_of_addLeftStrictMono _

instance : AddRightMono NatOrdinal :=
  addRightMono_of_addRightStrictMono _

private theorem add_comm' (a b : NatOrdinal) : a + b = b + a := by
  sorry

private theorem add_zero' (a : NatOrdinal) : a + 0 = a := by
  sorry

private theorem iSup_add_of_monotone (f : NatOrdinal.{u} → NatOrdinal.{u}) (h : Monotone f) :
    ⨆ x : Iio (a + b), f x = max (⨆ a' : Iio a, f (a'.1 + b)) (⨆ b' : Iio b, f (a + b'.1)) := by
  sorry

private theorem add_assoc' (a b c : NatOrdinal) : a + b + c = a + (b + c) := by
  sorry

instance : AddCommMonoid NatOrdinal where
  add_zero := private add_zero'
  zero_add x := by rw [add_comm', add_zero']
  add_comm := private add_comm'
  add_assoc := private add_assoc'
  nsmul := nsmulRec

instance : IsOrderedCancelAddMonoid NatOrdinal where
  add_le_add_left _ _ := add_le_add_left
  le_of_add_le_add_left a b c h := by
    by_contra! h'
    exact h.not_gt (add_lt_add_right h' a)

theorem le_add_left : a ≤ b + a := by
  sorry
theorem le_add_right : a ≤ a + b := by
  sorry

@[simp]
theorem add_eq_zero_iff : a + b = 0 ↔ a = 0 ∧ b = 0 := by
  sorry

private theorem succ_eq_add_one' (a : NatOrdinal) : succ a = a + 1 := by
  sorry

instance : SuccAddOrder NatOrdinal := ⟨by exact succ_eq_add_one'⟩

@[simp] theorem of_add_one (a : Ordinal) : of (a + 1) = of a + 1 := by
  sorry
@[simp] theorem val_add_one (a : NatOrdinal) : val (a + 1) = val a + 1 := by
  sorry

instance : AddMonoidWithOne NatOrdinal where
  natCast n := of n
  natCast_succ n := by
    rw [Nat.cast_add, Nat.cast_one, of_add_one]

@[simp] theorem of_natCast (n : ℕ) : of n = n := by
  sorry
@[simp] theorem val_natCast (n : ℕ) : val n = n := by
  sorry

@[simp]
theorem natCast_image_Iio (n : ℕ) : Nat.cast '' Iio n = Iio (n : NatOrdinal) := by
  sorry

@[simp]
theorem forall_lt_natCast {P : NatOrdinal → Prop} {n : ℕ} : (∀ a < ↑n, P a) ↔ ∀ a < n, P a := by
  sorry

@[simp]
theorem exists_lt_natCast {P : NatOrdinal → Prop} {n : ℕ} : (∃ a < ↑n, P a) ↔ ∃ a < n, P a := by
  sorry

theorem lt_omega0 {o : NatOrdinal} : o < of .omega0 ↔ ∃ n : ℕ, o = n := by
  sorry

theorem natCast_lt_omega0 (n : ℕ) : n < of .omega0 := by
  sorry

instance : CharZero NatOrdinal where
  cast_injective m n h := by
    apply_fun val at h
    simpa using h

@[simp]
theorem of_add_natCast (a : Ordinal) (n : ℕ) : of (a + n) = of a + n := by
  sorry

@[simp]
theorem val_add_natCast (a : NatOrdinal) (n : ℕ) : val (a + n) = val a + n := by
  sorry

/-- A version of `oadd_le_add` stated in terms of `Ordinal`. -/
theorem oadd_le_add' (a b : Ordinal) : a + b ≤ val (of a + of b) := by
  sorry

theorem oadd_le_add (a b : NatOrdinal) : of (a.val + b.val) ≤ a + b := by
  sorry

/-! ### Natural multiplication -/

private def mul (a b : NatOrdinal.{u}) : NatOrdinal.{u} :=
  sInf {c | ∀ a' < a, ∀ b' < b, mul a' b + mul a b' < c + mul a' b'}
termination_by (a, b)

#adaptation_note /-- noncomputable is now needed -/ in
/-- Natural multiplication on ordinals `a * b`, also known as the Hessenberg product, is recursively
defined as the least ordinal such that `a * b + a' * b'` is greater than `a' * b + a * b'` for all
`a' < a` and `b < b'`. In contrast to normal ordinal multiplication, it is commutative and
distributive (over natural addition).

Natural multiplication can equivalently be characterized as the ordinal resulting from multiplying
the Cantor normal forms of `a` and `b` as if they were polynomials in `ω`. Addition of exponents is
done via natural addition. -/
@[no_expose] noncomputable instance : Mul NatOrdinal := ⟨mul⟩

theorem mul_def (a b : NatOrdinal) :
    a * b = sInf {c | ∀ a' < a, ∀ b' < b, a' * b + a * b' < c + a' * b'} := by
  sorry

/-- The set in the definition of `mul` is nonempty. -/
private theorem mul_nonempty (a b : NatOrdinal.{u}) :
    {c : NatOrdinal.{u} | ∀ a' < a, ∀ b' < b, a' * b + a * b' < c + a' * b'}.Nonempty := by
  sorry

theorem mul_add_lt (ha : a' < a) (hb : b' < b) : a' * b + a * b' < a * b + a' * b' := by
  sorry

theorem mul_add_le (ha : a' ≤ a) (hb : b' ≤ b) : a' * b + a * b' ≤ a * b + a' * b' := by
  sorry

theorem lt_mul_iff : c < a * b ↔ ∃ a' < a, ∃ b' < b, c + a' * b' ≤ a' * b + a * b' := by
  sorry

theorem mul_le_iff : a * b ≤ c ↔ ∀ a' < a, ∀ b' < b, a' * b + a * b' < c + a' * b' := by
  sorry

private theorem mul_comm' (a b : NatOrdinal) : a * b = b * a := by
  sorry

instance : CommMagma NatOrdinal where
  mul_comm := private mul_comm'

private theorem mul_zero' (a : NatOrdinal) : a * 0 = 0 := by
  sorry

instance : MulZeroClass NatOrdinal where
  mul_zero := private mul_zero'
  zero_mul a := by rw [mul_comm', mul_zero']

private theorem mul_one' (a : NatOrdinal) : a * 1 = a := by
  sorry

instance : MulZeroOneClass NatOrdinal where
  mul_one := private mul_one'
  one_mul a := by rw [mul_comm', mul_one']

instance : PosMulStrictMono NatOrdinal where
  mul_lt_mul_of_pos_left a ha b c h := lt_mul_iff.2 ⟨0, ha, b, h, by simp⟩

instance : MulPosStrictMono NatOrdinal where
  mul_lt_mul_of_pos_right a ha b c h := lt_mul_iff.2 ⟨b, h, 0, ha, by simp⟩

instance : MulLeftMono NatOrdinal where
  elim a b c h := by
    obtain rfl | h₁ := h.eq_or_lt; · simp
    obtain rfl | h₂ := NatOrdinal.eq_zero_or_pos a; · simp
    exact (mul_lt_mul_of_pos_left h₁ h₂).le

instance : MulRightMono NatOrdinal where
  elim a b c h := by convert mul_le_mul_right h a using 1 <;> exact mul_comm ..

private theorem mul_add (a b c : NatOrdinal) : a * (b + c) = a * b + a * c := by
  sorry

instance : Distrib NatOrdinal where
  left_distrib := private mul_add
  right_distrib a b c := by rw [mul_comm, mul_add, mul_comm, mul_comm c]

theorem mul_add_lt₃ (ha : a' < a) (hb : b' < b) (hc : c' < c) :
    a' * b * c + a * b' * c + a * b * c' + a' * b' * c' <
      a * b * c + a' * b' * c + a' * b * c' + a * b' * c' := by
  sorry

theorem mul_add_le₃ {a' b' c' : NatOrdinal} (ha : a' ≤ a) (hb : b' ≤ b) (hc : c' ≤ c) :
    a' * b * c + a * b' * c + a * b * c' + a' * b' * c' ≤
      a * b * c + a' * b' * c + a' * b * c' + a * b' * c' := by
  sorry

private theorem mul_add_lt₃' {a' b' c' : NatOrdinal} (ha : a' < a) (hb : b' < b) (hc : c' < c) :
    a' * (b * c) + a * (b' * c) + a * (b * c') + a' * (b' * c') <
      a * (b * c) + a' * (b' * c) + a' * (b * c') + a * (b' * c') := by
  sorry

theorem lt_mul_iff₃ : d < a * b * c ↔ ∃ a' < a, ∃ b' < b, ∃ c' < c,
    d + a' * b' * c + a' * b * c' + a * b' * c' ≤
      a' * b * c + a * b' * c + a * b * c' + a' * b' * c' := by
  sorry

theorem mul_le_iff₃ : a * b * c ≤ d ↔ ∀ a' < a, ∀ b' < b, ∀ c' < c,
    a' * b * c + a * b' * c + a * b * c' + a' * b' * c' <
      d + a' * b' * c + a' * b * c' + a * b' * c' := by
  sorry

private theorem mul_le_iff₃' : a * (b * c) ≤ d ↔ ∀ a' < a, ∀ b' < b, ∀ c' < c,
    a' * (b * c) + a * (b' * c) + a * (b * c') + a' * (b' * c') <
      d + a' * (b' * c) + a' * (b * c') + a * (b' * c') := by
  sorry

private theorem mul_assoc (a b c : NatOrdinal) : a * b * c = a * (b * c) := by
  sorry

instance : CommSemiring NatOrdinal where
  mul_assoc := private mul_assoc

instance : IsStrictOrderedRing NatOrdinal where

/-- A version of `omul_le_mul` stated in terms of `Ordinal`. -/
theorem omul_le_mul' (a b : Ordinal) : a * b ≤ val (of a * of b) := by
  sorry

theorem omul_le_mul (a b : NatOrdinal) : of (a.val * b.val) ≤ a * b := by
  sorry

end NatOrdinal
