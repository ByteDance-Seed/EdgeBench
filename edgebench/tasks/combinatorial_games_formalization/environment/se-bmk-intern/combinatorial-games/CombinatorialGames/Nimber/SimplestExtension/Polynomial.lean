/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Nimber.SimplestExtension.Basic
public import Mathlib.Algebra.Polynomial.EraseLead
public import Mathlib.Algebra.Polynomial.Eval.Defs
public import Mathlib.Algebra.Polynomial.Splits
public import Mathlib.Data.Finsupp.WellFounded

import Mathlib.Algebra.Polynomial.Degree.Lemmas
import Mathlib.Algebra.Polynomial.Eval.Coeff
import Mathlib.RingTheory.Polynomial.UniqueFactorization
import Mathlib.Tactic.ComputeDegree
import Mathlib.Algebra.Polynomial.Degree.Domain

/-!
# Nimber polynomials

This file contains multiple auxiliary results and definitions for working with nimber polynomials:

- `IsField.embed`: embeds a polynomial `p : Nimber[X]` into the subfield `Iio x`, for `IsField x`.
- `Lex.instLinearOrderPolynomial`: a linear order instance on nimber polynomials, defined as the
  colexicographic ordering.
- `leastNoRoots x`: the smallest non-constant polynomial in `x` without roots less than `x`.
-/

universe u

public section

open Order Polynomial

/-! ### For Mathlib -/

-- TODO: should some of these be global?
attribute [local aesop simp] Function.update

-- TODO: upstream attr.
attribute [simp] mem_lowerBounds

namespace Polynomial

variable {R : Type*} [Semiring R] {p : R[X]}

theorem natDegree_eq_zero_iff : p.natDegree = 0 ↔ p = 0 ∨ p.degree = 0 := by
  sorry

theorem self_sub_X_pow_of_monic {R} [Ring R] {p : R[X]} (h : p.Monic) :
    p - X ^ p.natDegree = p.eraseLead := by
  sorry

theorem degree_pos_of_mem_roots {R} [CommRing R] [IsDomain R] {p : R[X]} {r} (h : r ∈ p.roots) :
    0 < p.degree := by
  sorry

theorem monomial_induction {motive : R[X] → Prop} (zero : motive 0)
    (add : ∀ a n q, degree q < .some n → motive q → motive (C a * X ^ n + q)) (p : R[X]) :
    motive p := by
  sorry

theorem eq_add_C_mul_X_pow_of_degree_le {p : R[X]} {n : ℕ} (h : p.degree ≤ n) :
    ∃ (a : R) (q : R[X]), p = q + C a * X ^ n ∧ q.degree < n := by
  sorry

end Polynomial

theorem WithBot.le_zero_iff {α} [AddZeroClass α] [PartialOrder α] [CanonicallyOrderedAdd α]
    {x : WithBot α} : x ≤ 0 ↔ x = ⊥ ∨ x = 0 := by
  sorry

theorem WithBot.coe_add_one (n : ℕ) : WithBot.some (n + 1) = WithBot.some n + 1 := by
  sorry

@[simp]
theorem WithBot.natCast_eq_coe (n : ℕ) : (n : WithBot ℕ) = WithBot.some n := by
  sorry

-- TODO: Generalize to a SuccAddOrder
@[simp]
theorem WithBot.lt_add_one {x : WithBot ℕ} (n : ℕ) : x < WithBot.some n + 1 ↔ x ≤ n := by
  sorry

-- TODO: presumably we should PR this along with all the other versions.
theorem WithBot.add_pos_of_pos_of_nonneg {α : Type*} [AddZeroClass α] [Preorder α] [AddLeftMono α]
    {a b : WithBot α} (ha : 0 < a) (hb : 0 ≤ b) : 0 < a + b := by
  sorry

@[simp] theorem WithBot.succ_one' : Order.succ (1 : WithBot ℕ) = 2 := by
  sorry

theorem WithTop.untop_eq {α} {x : WithTop α} {y : α} (h : x = y) :
    x.untop (h ▸ coe_ne_top) = y := by
  sorry

theorem WithTop.eq_untop {α} {x : WithTop α} {y : α} (h : y = x) :
    y = x.untop (h ▸ coe_ne_top) := by
  sorry

namespace Nimber

/-! ### Basic results -/

theorem polynomial_eq_zero_of_le_one {x : Nimber} {p : Nimber[X]}
    (hx₁ : x ≤ 1) (h : ∀ k, p.coeff k < x) : p = 0 := by
  sorry

theorem IsRing.eval_lt {x y : Nimber} (h : IsRing x) {p : Nimber[X]} (hp : ∀ k, p.coeff k < x)
    (hy : y < x) : p.eval y < x := by
  sorry

theorem coeff_X_pow_lt {x : Nimber} (n : ℕ) (h : 1 < x) : ∀ k, (X ^ n).coeff k < x := by
  sorry

theorem coeff_X_lt {x : Nimber} (h : 1 < x) : ∀ k, X.coeff k < x := by
  sorry

theorem IsGroup.coeff_add_lt {x : Nimber} {p q : Nimber[X]} (h : IsGroup x)
    (hp : ∀ k, p.coeff k < x) (hq : ∀ k, q.coeff k < x) : ∀ k, (p + q).coeff k < x := by
  sorry

theorem IsGroup.coeff_sum_lt {x : Nimber} {ι} {f : ι → Nimber[X]} {s : Finset ι} (h : IsGroup x)
    (hs : ∀ y ∈ s, ∀ k, (f y).coeff k < x) : ∀ k, (s.sum f).coeff k < x := by
  sorry

theorem coeff_zero_lt {x : Nimber} (h : x ≠ 0) :
    ∀ k, (0 : Nimber[X]).coeff k < x := by
  sorry

theorem IsRing.coeff_mul_lt {x : Nimber} {p q : Nimber[X]} (h : IsRing x)
    (hp : ∀ k, p.coeff k < x) (hq : ∀ k, q.coeff k < x) : ∀ k, (p * q).coeff k < x := by
  sorry

theorem IsRing.coeff_prod_lt {x : Nimber} {ι} {f : ι → Nimber[X]} {s : Finset ι} (h : IsRing x)
    (hs : ∀ y ∈ s, ∀ k, (f y).coeff k < x) : ∀ k, (s.prod f).coeff k < x := by
  sorry

theorem coeff_one_lt {x : Nimber} (h : 1 < x) :
    ∀ k, (1 : Nimber[X]).coeff k < x := by
  sorry

theorem coeff_C_lt {x y : Nimber} (h : y < x) : ∀ k, (C y).coeff k < x := by
  sorry

/-! ### Embedding in a subfield -/

/-- Reinterpret a polynomial in the nimbers as a polynomial in the subfield `x`.

We could define this under the weaker assumption `IsRing`, but due to proof erasure, this leads to
issues where `Field (h.toSubring ⋯)` can't be inferred, even if `h : IsField x`. -/
@[expose]
def IsField.embed {x : Nimber} (h : IsField x) (p : Nimber[X])
    (hp : ∀ k, p.coeff k < x) : h.toSubfield[X] :=
  .ofFinsupp <| .mk p.support (fun k ↦ ⟨p.coeff k, hp k⟩) (by simp [← Subtype.val_inj])

@[simp]
theorem IsField.coeff_embed {x : Nimber} (h : IsField x) {p : Nimber[X]}
    (hp : ∀ k, p.coeff k < x) (k : ℕ) : (h.embed p hp).coeff k = ⟨p.coeff k, hp k⟩ := by
  sorry

@[simp]
theorem IsField.degree_embed {x : Nimber} (h : IsField x) {p : Nimber[X]}
    (hp : ∀ k, p.coeff k < x) : (h.embed p hp).degree = p.degree := by
  sorry

@[simp]
theorem IsField.leadingCoeff_embed {x : Nimber} (h : IsField x) {p : Nimber[X]}
    (hp : ∀ k, p.coeff k < x) : (h.embed p hp).leadingCoeff = ⟨p.leadingCoeff, hp _⟩ := by
  sorry

@[simp]
theorem IsField.monic_embed {x : Nimber} (h : IsField x) {p : Nimber[X]}
    (hp : ∀ k, p.coeff k < x) : (h.embed p hp).Monic ↔ p.Monic := by
  sorry

@[simp]
theorem IsField.map_embed {x : Nimber} (h : IsField x) {p : Nimber[X]}
    (hp : ∀ k, p.coeff k < x) : (h.embed p hp).map (Subfield.subtype _) = p := by
  sorry

@[simp]
theorem IsField.embed_C {x : Nimber} (h : IsField x) {y hy} :
    h.embed (C y) hy = C ⟨y, by simpa using hy 0⟩ := by
  sorry

@[simp]
theorem IsField.eval_embed {x : Nimber} (h : IsField x) {p : Nimber[X]}
    (hp : ∀ k, p.coeff k < x) (y) : (h.embed p hp).eval y = ⟨_, h.eval_lt hp y.2⟩ := by
  sorry

/-! ### Lexicographic ordering on polynomials -/

namespace Lex

/-- The colexicographic ordering on nimber polynomials. -/
noncomputable instance : LinearOrder (Nimber[X]) where
  lt p q := ∃ n, (∀ k, n < k → p.coeff k = q.coeff k) ∧ p.coeff n < q.coeff n
  __ := LinearOrder.lift'
    (fun p : Nimber[X] ↦ toColex (α := ℕ →₀ _) p.toFinsupp)
    (toFinsupp_injective.comp toColex.injective)

theorem lt_def {p q : Nimber[X]} : p < q ↔ ∃ n,
    (∀ k, n < k → p.coeff k = q.coeff k) ∧ p.coeff n < q.coeff n := by
  sorry

instance : WellFoundedLT (Colex (ℕ →₀ Nimber)) where
  wf := Finsupp.Lex.wellFounded' Nimber.not_neg lt_wf wellFounded_lt

instance : WellFoundedLT (Nimber[X]) where
  wf := InvImage.wf (fun p : Nimber[X] ↦ toColex (α := ℕ →₀ _) p.toFinsupp) wellFounded_lt

noncomputable instance : OrderBot (Nimber[X]) where
  bot := 0
  bot_le p := by rw [← not_lt, lt_def]; simp

@[simp] theorem bot_eq_zero : (⊥ : Nimber[X]) = 0 := by
  sorry
@[simp] theorem le_zero_iff {p : Nimber[X]} : p ≤ 0 ↔ p = 0 := by
  sorry

noncomputable instance : ConditionallyCompleteLinearOrderBot (Nimber[X]) :=
  WellFoundedLT.conditionallyCompleteLinearOrderBot _

theorem forall_lt_quadratic {P : Nimber[X] → Prop} {x y z : Nimber} :
    (∀ p < C x * X ^ 2 + C y * X + C z, P p) ↔
      (∀ c < z, P (C x * X ^ 2 + C y * X + C c)) ∧
      (∀ b < y, ∀ c, P (C x * X ^ 2 + C b * X + C c)) ∧
      (∀ a < x, ∀ b c, P (C a * X ^ 2 + C b * X + C c)) := by
  sorry

theorem forall_le_quadratic {P : Nimber[X] → Prop} {x y z : Nimber} :
    (∀ p ≤ C x * X ^ 2 + C y * X + C z, P p) ↔
      (∀ c ≤ z, P (C x * X ^ 2 + C y * X + C c)) ∧
      (∀ b < y, ∀ c, P (C x * X ^ 2 + C b * X + C c)) ∧
      (∀ a < x, ∀ b c, P (C a * X ^ 2 + C b * X + C c)) := by
  sorry

theorem exists_lt_quadratic {P : Nimber[X] → Prop} {x y z : Nimber} :
    (∃ p < C x * X ^ 2 + C y * X + C z, P p) ↔
      (∃ c < z, P (C x * X ^ 2 + C y * X + C c)) ∨
      (∃ b < y, ∃ c, P (C x * X ^ 2 + C b * X + C c)) ∨
      (∃ a < x, ∃ b c, P (C a * X ^ 2 + C b * X + C c)) := by
  sorry

theorem exists_le_quadratic {P : Nimber[X] → Prop} {x y z : Nimber} :
    (∃ p ≤ C x * X ^ 2 + C y * X + C z, P p) ↔
      (∃ c ≤ z, P (C x * X ^ 2 + C y * X + C c)) ∨
      (∃ b < y, ∃ c, P (C x * X ^ 2 + C b * X + C c)) ∨
      (∃ a < x, ∃ b c, P (C a * X ^ 2 + C b * X + C c)) := by
  sorry

theorem forall_lt_linear {P : Nimber[X] → Prop} {x y : Nimber} :
    (∀ p < C x * X + C y, P p) ↔
      (∀ b < y, P (C x * X + C b)) ∧ (∀ a < x, ∀ b, P (C a * X + C b)) := by
  sorry

theorem forall_le_linear {P : Nimber[X] → Prop} {x y : Nimber} :
    (∀ p ≤ C x * X + C y, P p) ↔
      (∀ b ≤ y, P (C x * X + C b)) ∧ (∀ a < x, ∀ b, P (C a * X + C b)) := by
  sorry

theorem exists_lt_linear {P : Nimber[X] → Prop} {x y : Nimber} :
    (∃ p < C x * X + C y, P p) ↔
      (∃ b < y, P (C x * X + C b)) ∨ (∃ a < x, ∃ b, P (C a * X + C b)) := by
  sorry

theorem exists_le_linear {P : Nimber[X] → Prop} {x y : Nimber} :
    (∃ p ≤ C x * X + C y, P p) ↔
      (∃ b ≤ y, P (C x * X + C b)) ∨ (∃ a < x, ∃ b, P (C a * X + C b)) := by
  sorry

@[simp]
theorem forall_lt_C {P : Nimber[X] → Prop} {x : Nimber} :
    (∀ p < C x, P p) ↔ ∀ a < x, P (C a) := by
  sorry

@[simp]
theorem forall_le_C {P : Nimber[X] → Prop} {x : Nimber} :
    (∀ y ≤ C x, P y) ↔ ∀ y ≤ x, P (C y) := by
  sorry

@[simp]
theorem exists_lt_C {P : Nimber[X] → Prop} {x : Nimber} :
    (∃ y < C x, P y) ↔ ∃ y < x, P (C y) := by
  sorry

@[simp]
theorem exists_le_C {P : Nimber[X] → Prop} {x : Nimber} :
    (∃ y ≤ C x, P y) ↔ ∃ y ≤ x, P (C y) := by
  sorry

theorem degree_mono : Monotone (α := Nimber[X]) degree := by
  sorry

theorem natDegree_mono : Monotone (α := Nimber[X]) natDegree := by
  sorry

theorem C_strictMono : StrictMono (α := Nimber) C := by
  sorry

@[simp]
theorem C_lt_C_iff {x y : Nimber} : C x < C y ↔ x < y := by
  sorry

@[simp]
theorem C_le_C_iff {x y : Nimber} : C x ≤ C y ↔ x ≤ y := by
  sorry

theorem lt_of_degree_lt {p q : Nimber[X]} (h : p.degree < q.degree) : p < q := by
  sorry

theorem lt_of_natDegree_lt {p q : Nimber[X]} (h : p.natDegree < q.natDegree) : p < q := by
  sorry

@[simp]
theorem lt_X_pow_iff {p : Nimber[X]} {n : ℕ} : p < X ^ n ↔ p.degree < n := by
  sorry

@[simp]
theorem coe_lt_X_pow_iff {p : Nimber[X]} {n : ℕ} : WithTop.some p < .some X ^ n ↔ p.degree < n := by
  sorry

@[simp]
theorem X_pow_le_iff {p : Nimber[X]} {n : ℕ} : X ^ n ≤ p ↔ n ≤ p.degree := by
  sorry

@[simp]
theorem X_pow_le_coe_iff {p : Nimber[X]} {n : ℕ} : .some X ^ n ≤ WithTop.some p ↔ n ≤ p.degree := by
  sorry

theorem strictMono_X_pow : StrictMono fun n ↦ (X : Nimber[X]) ^ n := by
  sorry

theorem X_pow_le_X_pow_iff {m n : ℕ} : (X : Nimber[X]) ^ m ≤ X ^ n ↔ m ≤ n := by
  sorry

theorem X_pow_lt_X_pow_iff {m n : ℕ} : (X : Nimber[X]) ^ m < X ^ n ↔ m < n := by
  sorry

@[simp]
theorem coe_X_pow_le_coe_X_pow_iff {m n : ℕ} :
    (.some X : WithTop Nimber[X]) ^ m ≤ .some X ^ n ↔ m ≤ n := by
  sorry

@[simp]
theorem coe_X_pow_lt_coe_X_pow_iff {m n : ℕ} :
    (.some X : WithTop Nimber[X]) ^ m < .some X ^ n ↔ m < n := by
  sorry

theorem X_pow_add_lt {p q : Nimber[X]} (hm : p.Monic) (h : q < X ^ p.natDegree + p) :
    X ^ p.natDegree + q < p := by
  sorry

theorem X_pow_add_le {p q : Nimber[X]} (hm : p.Monic) (h : q ≤ X ^ p.natDegree + p) :
    X ^ p.natDegree + q ≤ p := by
  sorry

theorem mul_leadingCoeff_inv_lt {p : Nimber[X]} (h₀ : p ≠ 0) (h₁ : ¬p.Monic) :
    p * C p.leadingCoeff⁻¹ < p := by
  sorry

theorem mul_leadingCoeff_inv_le (p : Nimber[X]) :
    p * C p.leadingCoeff⁻¹ ≤ p := by
  sorry

instance : NoMaxOrder (Nimber[X]) where
  exists_gt p := by
    use X ^ (p.natDegree + 1)
    simpa using degree_le_natDegree

noncomputable instance : SuccOrder (Nimber.{u}[X]) := by
  refine .ofCore (fun p ↦ .ofFinsupp (p.toFinsupp.update 0 (succ (p.coeff 0)))) ?_ (by simp)
  refine @fun p _ q ↦ ⟨fun hpq ↦ ?_, ?_⟩
  · obtain ⟨n, hn, hpq⟩ := hpq
    cases n with
    | zero =>
      obtain hpq' | hpq' := (succ_le_of_lt hpq).lt_or_eq
      · refine le_of_lt ⟨0, ?_⟩
        aesop
      · apply le_of_eq
        ext k
        cases k <;> aesop
    | succ n => refine le_of_lt ⟨n + 1, ?_⟩; aesop
  · rw [le_iff_lt_or_eq]
    rintro (hpq | rfl)
    · obtain ⟨n, hn, hpq⟩ := hpq
      refine ⟨n, fun k hk ↦ ?_, ?_⟩
      · specialize hn k hk
        aesop
      · have (a b : Nimber.{u}) (h : succ a < b) : a < b := (le_succ a).trans_lt h
        aesop
    · use 0
      aesop

@[aesop simp]
theorem coeff_succ (p : Nimber[X]) :
    (succ p).coeff = Function.update p.coeff 0 (succ (p.coeff 0)) := by
  sorry

@[simp]
theorem coeff_succ_zero (p : Nimber[X]) :
    (succ p).coeff 0 = succ (p.coeff 0) := by
  sorry

@[simp]
theorem coeff_succ_of_ne_zero (p : Nimber[X]) {k : ℕ} (h : k ≠ 0) :
    (succ p).coeff k = p.coeff k := by
  sorry

theorem succ_eq_add_one_of_coeff_zero {p : Nimber[X]} (h : p.coeff 0 = 0) : succ p = p + 1 := by
  sorry

end Lex

/-! ### Evaluating nimber polynomials as ordinals -/

open Ordinal

/-- Evaluate a nimber polynomial using ordinal arithmetic.

TODO: once the `Ordinal.CNF` API is more developed, use it to redefine this. -/
noncomputable def oeval (x : Nimber) (p : Nimber[X]) : Nimber :=
  ∗((List.range (p.natDegree + 1)).reverse.map fun k ↦ x.val ^ k * (p.coeff k).val).sum

@[simp]
theorem oeval_zero (x : Nimber) : oeval x 0 = 0 := by
  sorry

theorem oeval_eq_of_natDegree_le {p : Nimber[X]} {n : ℕ} (h : p.natDegree + 1 ≤ n) (x : Nimber) :
    oeval x p = ∗((List.range n).reverse.map fun k ↦ x.val ^ k * (p.coeff k).val).sum := by
  sorry

theorem oeval_C_mul_X_pow_add {n : ℕ} {p : Nimber[X]} (hp : p.degree < n) (x a : Nimber) :
    oeval x (C a * X ^ n + p) = ∗(x.val ^ n * a.val + val (oeval x p)) := by
  sorry

theorem oeval_eq (x : Nimber) (p : Nimber[X]) :
    oeval x p = ∗(x.val ^ p.natDegree * p.leadingCoeff.val + val (oeval x p.eraseLead)) := by
  sorry

@[simp]
theorem oeval_X_pow_mul (x : Nimber) (n : ℕ) (p : Nimber[X]) :
    oeval x (X ^ n * p) = ∗(x.val ^ n * (oeval x p).val) := by
  sorry

@[simp]
theorem oeval_mul_X_pow (x : Nimber) (n : ℕ) (p : Nimber[X]) :
    oeval x (p * X ^ n) = ∗(x.val ^ n * (oeval x p).val) := by
  sorry

theorem oeval_C_mul_X_pow (x a : Nimber) (n : ℕ) :
    oeval x (C a * X ^ n) = ∗(x.val ^ n * a.val) := by
  sorry

@[simp]
theorem oeval_X_pow (x : Nimber) (n : ℕ) : oeval x (X ^ n) = ∗(x.val ^ n) := by
  sorry

@[simp]
theorem oeval_X (x : Nimber) : oeval x X = x := by
  sorry

@[simp]
theorem oeval_C (x a : Nimber) : oeval x (C a) = a := by
  sorry

@[simp]
theorem oeval_one (x : Nimber) : oeval x 1 = 1 := by
  sorry

theorem mul_coeff_le_oeval (x : Nimber) (p : Nimber[X]) (k : ℕ) :
    ∗(x.val ^ k * (p.coeff k).val) ≤ oeval x p := by
  sorry

theorem opow_natDegree_le_oeval (x : Nimber) {p : Nimber[X]} (hp : p ≠ 0) :
    ∗(x.val ^ p.natDegree) ≤ oeval x p := by
  sorry

theorem oeval_lt_pow {x : Nimber} {p : Nimber[X]} {n : ℕ}
    (hpk : ∀ k, p.coeff k < x) (hn : p.degree < n) : oeval x p < ∗(x.val ^ n) := by
  sorry

theorem oeval_lt_pow_iff {x : Nimber} {p : Nimber[X]} {n : ℕ}
    (hpk : ∀ k, p.coeff k < x) : oeval x p < ∗(x.val ^ n) ↔ p.degree < n := by
  sorry

theorem oeval_lt_opow_omega0 {x : Nimber} {p : Nimber[X]}
    (hpk : ∀ k, p.coeff k < x) : oeval x p < ∗(x.val ^ ω) := by
  sorry

theorem oeval_lt_oeval {x : Nimber} {p q : Nimber[X]} (h : p < q)
    (hpk : ∀ k, p.coeff k < x) (hqk : ∀ k, q.coeff k < x) : oeval x p < oeval x q := by
  sorry

theorem oeval_le_oeval {x : Nimber} {p q : Nimber[X]} (h : p ≤ q)
    (hpk : ∀ k, p.coeff k < x) (hqk : ∀ k, q.coeff k < x) : oeval x p ≤ oeval x q := by
  sorry

theorem oeval_lt_oeval_iff {x : Nimber} {p q : Nimber[X]}
    (hpk : ∀ k, p.coeff k < x) (hqk : ∀ k, q.coeff k < x) : oeval x p < oeval x q ↔ p < q := by
  sorry

theorem oeval_le_oeval_iff {x : Nimber} {p q : Nimber[X]}
    (hpk : ∀ k, p.coeff k < x) (hqk : ∀ k, q.coeff k < x) : oeval x p ≤ oeval x q ↔ p ≤ q := by
  sorry

theorem oeval_inj {x : Nimber} {p q : Nimber[X]}
    (hpk : ∀ k, p.coeff k < x) (hqk : ∀ k, q.coeff k < x) : oeval x p = oeval x q ↔ p = q := by
  sorry

theorem oeval_eq_zero_iff {x : Nimber} {p : Nimber[X]} (hx : x ≠ 0) : oeval x p = 0 ↔ p = 0 := by
  sorry

/-- A version of `eq_oeval_of_lt_pow` stated in terms of `Ordinal`. -/
theorem eq_oeval_of_lt_pow' {x y : Ordinal} {n : ℕ} (hx₀ : x ≠ 0) (h : y < x ^ n) :
    ∃ p : Nimber[X], p.degree < n ∧ (∀ k, val (p.coeff k) < x) ∧ val (oeval (∗x) p) = y := by
  sorry

theorem eq_oeval_of_lt_pow {x y : Nimber} {n : ℕ} (hx₀ : x ≠ 0) (h : y < of (x.val ^ n)) :
    ∃ p : Nimber[X], p.degree < n ∧ (∀ k, p.coeff k < x) ∧ oeval x p = y := by
  sorry

theorem eq_oeval_of_lt_opow_omega0 {x y : Nimber} (h : y < of (x.val ^ ω)) :
    ∃ p : Nimber[X], (∀ k, p.coeff k < x) ∧ oeval x p = y := by
  sorry

theorem eq_oeval_of_lt_oeval {x y : Nimber} {p : Nimber[X]} (hx₀ : x ≠ 0)
    (hpk : ∀ k, p.coeff k < x) (h : y < oeval x p) :
    ∃ q : Nimber[X], q < p ∧ (∀ k, q.coeff k < x) ∧ oeval x q = y := by
  sorry

theorem forall_lt_oeval_iff {x : Nimber} {P : Ordinal → Prop}
    {p : Nimber[X]} (hpk : ∀ k, p.coeff k < x) :
    (∀ y < oeval x p, P y) ↔ ∀ q < p, (∀ k, q.coeff k < x) → P (oeval x q) := by
  sorry

/-! ### Least irreducible polynomial -/

attribute [-simp] WithTop.coe_add WithTop.coe_mul WithTop.coe_pow

/-- Returns the lexicographically earliest non-constant polynomial, all of whose coefficients are
less than `x`, without any roots less than `x`. If none exists, returns `⊤`.

This function takes values on `WithTop (Nimber[X])`, which is a well-ordered complete lattice (the
order on `Nimber[X]` is the lexicographic order). -/
noncomputable def leastNoRoots (x : Nimber) : WithTop (Nimber[X]) :=
  sInf (WithTop.some '' {p | 0 < p.degree ∧ (∀ k, p.coeff k < x) ∧ ∀ r < x, p.eval r ≠ 0})

private theorem leastNoRoots_mem {x : Nimber} (ht) :
    x.leastNoRoots.untop ht ∈
      {p | 0 < p.degree ∧ (∀ k, p.coeff k < x) ∧ ∀ r < x, p.eval r ≠ 0} := by
  sorry

theorem degree_leastNoRoots_pos {x : Nimber} (ht) :
    0 < (x.leastNoRoots.untop ht).degree := by
  sorry

theorem natDegree_leastNoRoots_pos {x : Nimber} (ht) :
    0 < (x.leastNoRoots.untop ht).natDegree := by
  sorry

theorem one_le_degree_leastNoRoots_pos {x : Nimber} (ht) :
    1 ≤ (x.leastNoRoots.untop ht).degree := by
  sorry

theorem one_le_natDegree_leastNoRoots {x : Nimber} (ht) :
    1 ≤ (x.leastNoRoots.untop ht).natDegree := by
  sorry

theorem coeff_leastNoRoots_lt {x : Nimber} (ht) :
    ∀ k, (x.leastNoRoots.untop ht).coeff k < x := by
  sorry

theorem not_isRoot_leastNoRoots_of_lt {x r : Nimber} (ht) (hr : r < x) :
    ¬ IsRoot (x.leastNoRoots.untop ht) r := by
  sorry

@[simp]
theorem leastNoRoots_zero : leastNoRoots 0 = ⊤ := by
  sorry

@[simp]
theorem leastNoRoots_one : leastNoRoots 1 = ⊤ := by
  sorry

theorem leastNoRoots_of_le_one {x : Nimber} (h : x ≤ 1) : leastNoRoots x = ⊤ := by
  sorry

@[simp]
theorem coeff_leastNoRoots_zero_ne {x : Nimber} (ht) :
    (x.leastNoRoots.untop ht).coeff 0 ≠ 0 := by
  sorry

@[simp]
theorem leastNoRoots_ne_zero (x : Nimber) : leastNoRoots x ≠ 0 := by
  sorry

@[simp]
theorem leastNoRoots_ne_zero' {x : Nimber} (ht) : x.leastNoRoots.untop ht ≠ 0 := by
  sorry

theorem leastNoRoots_ne_X_pow' (x : Nimber) (ht) (n : ℕ) :
    x.leastNoRoots.untop ht ≠ X ^ n := by
  sorry

theorem leastNoRoots_ne_X_pow (x : Nimber) (n : ℕ) :
    leastNoRoots x ≠ .some (X ^ n) := by
  sorry

theorem X_pow_lt_leastNoRoots_of_le_degree {x : Nimber} {n : ℕ} (ht)
    (h : n ≤ (x.leastNoRoots.untop ht).degree) : .some (X ^ n) < x.leastNoRoots := by
  sorry

theorem leastNoRoots_le_of_not_isRoot {x : Nimber} {p : Nimber[X]}
    (hp₀ : 0 < p.degree) (hpk : ∀ k, p.coeff k < x) (hr : ∀ r < x, ¬ p.IsRoot r) :
    leastNoRoots x ≤ p := by
  sorry

theorem exists_root_of_lt_leastNoRoots {x : Nimber} {p : Nimber[X]}
    (hp₀ : p.degree ≠ 0) (hpk : ∀ k, p.coeff k < x) (hpn : p < leastNoRoots x) :
    ∃ r < x, p.IsRoot r := by
  sorry

theorem le_leastNoRoots_of_exists_isRoot {x : Nimber} {p : Nimber[X]}
    (hp : ∀ c < p, 0 < c.degree → (∀ k, c.coeff k < x) → ∃ r < x, c.IsRoot r) :
    p ≤ leastNoRoots x := by
  sorry

theorem IsField.exists_root_subfield {x : Nimber} (h : IsField x)
    {p : h.toSubfield[X]} (hp₀ : p.degree ≠ 0)
    (hpn : map (Subfield.subtype _) p < leastNoRoots x) : ∃ r, p.IsRoot r := by
  sorry

theorem IsField.splits_subfield {x : Nimber} (h : IsField x)
    {p : h.toSubfield[X]} (hpn : map (Subfield.subtype _) p < leastNoRoots x) :
    p.Splits := by
  sorry

theorem IsField.roots_eq_map {x : Nimber} (h : IsField x) {p : Nimber[X]}
    (hpn : p < leastNoRoots x) (hpk : ∀ k, p.coeff k < x) :
    p.roots = (h.embed p hpk).roots.map (Subfield.subtype _) := by
  sorry

-- TODO: use `Polynomial.toSubring` and generalize to rings.
theorem IsField.root_lt {x r : Nimber} (h : IsField x) {p : Nimber[X]}
    (hpn : p < leastNoRoots x) (hpk : ∀ k, p.coeff k < x) (hr : r ∈ p.roots) : r < x := by
  sorry

theorem IsField.eq_prod_roots_of_lt_leastNoRoots {x : Nimber} (h : IsField x)
    {p : Nimber[X]} (hpn : p < leastNoRoots x) (hpk : ∀ k, p.coeff k < x) :
    p = C p.leadingCoeff * (p.roots.map fun a ↦ X - C a).prod := by
  sorry

theorem IsRing.leastNoRoots_eq_of_not_isField {x : Nimber} (h : IsRing x) (h' : ¬ IsField x) :
    leastNoRoots x = .some (C x⁻¹ * X + 1) := by
  sorry

theorem IsField.X_sq_lt_leastNoRoots {x : Nimber} (h : IsField x) :
    .some (X ^ 2) < leastNoRoots x := by
  sorry

theorem IsRing.toIsField_of_X_sq_lt_leastNoRoots {x : Nimber} (h : IsRing x)
    (h' : .some (X ^ 2) ≤ leastNoRoots x) : IsField x := by
  sorry

theorem IsField.monic_leastNoRoots {x : Nimber} (h : IsField x) (ht) :
    Monic (x.leastNoRoots.untop ht) := by
  sorry

theorem IsField.irreducible_embed_leastNoRoots {x : Nimber} (h : IsField x) (ht) :
    Irreducible (h.embed (x.leastNoRoots.untop ht) (coeff_leastNoRoots_lt ht)) := by
  sorry

-- TODO: can we golf this using `finite_range_coeff`?
theorem _root_.Polynomial.exists_gt_of_forall_coeff_gt {s : Set Nimber} {p : Nimber[X]}
    (h : ∀ k, ∃ a ∈ s, p.coeff k < a) : ∃ a ∈ s, ∀ k, p.coeff k < a := by
  sorry

theorem le_leastNoRoots_sSup {s : Set Nimber} {p : WithTop Nimber[X]}
    (H : ∀ x ∈ s, p ≤ leastNoRoots x) : p ≤ leastNoRoots (sSup s) := by
  sorry

theorem le_leastNoRoots_iSup {ι} {f : ι → Nimber} {p : WithTop Nimber[X]}
    (H : ∀ i, p ≤ leastNoRoots (f i)) : p ≤ leastNoRoots (⨆ i, f i) := by
  sorry

end Nimber
end
