/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Nimber.Basic
public import Mathlib.Data.Nat.Lattice

import CombinatorialGames.Tactic.OrdinalAlias

/-!
# Finite nimber arithmetic

This file defines the type alias `NatNimber` of the natural numbers, endowed with nimber arithmetic.
The goal is to define the field structure computably, and prove that it matches that on `Nimber`.
-/

alias! /-- The natural numbers, endowed with nim operations. -/ NatNimber Nat

namespace NatNimber

instance : LinearOrder NatNimber := Nat.instLinearOrder

instance : Lean.ToExpr NatNimber where
  toExpr x := .app (.const `NatNimber.of []) (Lean.toExpr x.val)
  toTypeExpr := .const `NatNimber []

instance : ToString NatNimber where
  toString x := "∗" ++ x.val.repr

@[simp] theorem lt_one_iff_zero {a : NatNimber} : a < 1 ↔ a = 0 := by
  sorry
@[simp] theorem one_le_iff_ne_zero {a : NatNimber} : 1 ≤ a ↔ a ≠ 0 := by
  sorry
theorem le_one_iff {a : NatNimber} : a ≤ 1 ↔ a = 0 ∨ a = 1 := by
  sorry

/-- The embedding `NatNimber ↪o Nimber`. -/
def toNimber : NatNimber ↪o Nimber where
  toFun x := .of x.val
  inj' x y := by simp
  map_rel_iff' := by simp

@[simp] theorem toNimber_zero : toNimber 0 = 0 := by
  sorry
@[simp] theorem toNimber_one : toNimber 1 = 1 := by
  sorry
@[simp] theorem toNimber_of (n : ℕ) : toNimber (of n) = Nimber.of n := by
  sorry

instance : Neg NatNimber where
  neg n := n

instance : Add NatNimber where
  add m n := of (m.val ^^^ n.val)

instance : Sub NatNimber where
  sub m n := m + n

@[simp]
theorem toNimber_add (x y : NatNimber) : toNimber (x + y) = .of x.val + .of y.val := by
  sorry

@[simp] theorem sub_eq (x y : NatNimber) : x - y = x + y := by
  sorry
@[simp] theorem neg_eq (x : NatNimber) : -x = x := by
  sorry

/-- Multiplies `x` by `∗2 ^ (2 ^ t - 1)`, whenever `x < ∗2 ^ 2 ^ t`. This is a subroutine needed to
multiply two general nimbers. This makes use of the formula:

$$(a2^{2^t}+b)2^{2^{t+1}-1} = (a2^{2^t-1})2^{2^t-1}+((a+b)2^{2^t-1})2^{2^t}$$

for $a, b < \ast 2 ^ {2 ^ t}$. -/
private def mulHalf (t : ℕ) (x : NatNimber) : NatNimber :=
  match t with
  | 0 => x
  | t + 1 =>
    let a := of (x.val / 2 ^ 2 ^ t)
    let b := of (x.val % 2 ^ 2 ^ t)
    of ((mulHalf t (a + b)).val * 2 ^ 2 ^ t) + mulHalf t (mulHalf t a)

/-- Multiplies `x` by `y`, whenever `x, y < ∗2 ^ 2 ^ t`. This makes use of the formula:

$$(a2^{2^t}+b)(c2^{2^t}+d)=(ac)2^{2^t-1}+(ac+ad+bc)2^{2^t}+bd$$

for $a, b, c, d < \ast 2 ^ {2 ^ t}$. -/
private def mul (t : ℕ) (x y : NatNimber) : NatNimber :=
  match t with
  | 0 => if x = 0 then 0 else if y = 0 then 0 else 1
  | t + 1 =>
    let a := of (x.val / 2 ^ 2 ^ t)
    let b := of (x.val % 2 ^ 2 ^ t)
    let c := of (y.val / 2 ^ 2 ^ t)
    let d := of (y.val % 2 ^ 2 ^ t)
    let z := mul t a c
    mulHalf t z + of ((z + mul t a d + mul t b c).val * 2 ^ 2 ^ t) + mul t b d

-- TODO: prove correctness
instance : Mul NatNimber where
  mul x y := mul (max x.val.log2.log2 y.val.log2.log2 + 1) x y

end NatNimber

example : Nimber.of 3 + Nimber.of 5 = Nimber.of 6 := by
  sorry
