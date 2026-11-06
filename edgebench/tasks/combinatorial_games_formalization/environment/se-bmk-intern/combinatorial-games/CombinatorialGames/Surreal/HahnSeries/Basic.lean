/-
Copyright (c) 2026 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Surreal.Pow
public import Mathlib.Order.Shrink
public import Mathlib.RingTheory.HahnSeries.Lex

import Mathlib.Algebra.Field.Subfield.Basic
import Mathlib.Algebra.Ring.Subring.Order
import Mathlib.RingTheory.HahnSeries.Cardinal

/-!
# Surreal Hahn series

Hahn series are a generalization of power series and Puiseux series. A Hahn series `R⟦Γ⟧` is defined
as a function `Γ → R` whose support is well-founded. This condition is sufficient to define addition
and multiplication as with polynomials, so that under suitable conditions, `R⟦Γ⟧` has the structure
of an ordered field.

The aphorism goes that surreals are real Hahn series over themselves. However, there are a few
technicalities. Hahn series are conventionally defined so that the support has well-founded `<`,
whereas for surreals it's more natural to assume well-founded `>`. Moreover, the Hahn series that
correspond to surreals must have a `Small` support. Because of this, we often prefer to identify
these surreal Hahn series with ordinal-indexed sequences of surreal exponents and their
coefficients.

This file provides the translation layer between Hahn series as they're implemented in Mathlib, and
the Hahn series relevant to surreal numbers, by defining the type `SurrealHahnSeries` for the
latter.
-/

universe u

public noncomputable section

/-! ### For Mathlib -/

attribute [aesop simp] Pi.single_apply

theorem Set.IsWF.to_subtype {α : Type*} [LT α] {s : Set α} (h : IsWF s) : WellFoundedLT s := by
  sorry

/-- This is like `RelIso.cast` with better def-eqs. -/
def RelIso.subrel {α : Type*} (r : α → α → Prop) {p q : α → Prop} (H : ∀ x, p x ↔ q x) :
    Subrel r p ≃r Subrel r q where
  map_rel_iff' := .rfl
  __ := Equiv.subtypeEquiv (Equiv.refl _) H

private def toLexRingEquiv {R : Type*} [Ring R] : R ≃+* Lex R where
  toFun := toLex
  invFun := ofLex
  map_add' _ _ := rfl
  map_mul' _ _ := rfl

open Order Set

/-! ### Basic defs and instances -/

/-- `SurrealHahnSeries` as a subfield. -/
private def surrealHahnSeriesSubfield : Subfield (Lex <| HahnSeries Surrealᵒᵈ ℝ) :=
  have : Fact (_ < _) := ⟨Cardinal.aleph0_lt_univ.{u, u}⟩
  (HahnSeries.cardSuppLTSubfield Surrealᵒᵈ ℝ .univ).comap toLexRingEquiv.toRingHom

/-- The type of `u`-small Hahn series over `Surrealᵒᵈ`, endowed with the lexicographic ordering. We
will show that this type is isomorphic as an ordered field to the surreals themselves. -/
def SurrealHahnSeries : Type (u + 1) :=
  surrealHahnSeriesSubfield

namespace SurrealHahnSeries

@[no_expose]
instance : Field SurrealHahnSeries :=
  inferInstanceAs (Field surrealHahnSeriesSubfield)

@[no_expose]
instance : LinearOrder SurrealHahnSeries :=
  inferInstanceAs (LinearOrder surrealHahnSeriesSubfield)

instance : IsStrictOrderedRing SurrealHahnSeries :=
  inferInstanceAs (IsStrictOrderedRing surrealHahnSeriesSubfield)

open Cardinal in
/-- A constructor for `SurrealHahnSeries` which hides various implementation details. -/
def mk (f : Surreal.{u} → ℝ) (small : Small.{u} (Function.support f))
    (wf : (Function.support f).WellFoundedOn (· > ·)) : SurrealHahnSeries where
  val := toLex ⟨f ∘ OrderDual.ofDual, IsWF.isPWO wf⟩
  property := by rwa [small_iff_lift_mk_lt_univ, lift_id, univ_umax.{u, u}] at small

/-! #### `coeff` -/

/-- Returns the coefficient for `X ^ i`. -/
@[no_expose]
def coeff (x : SurrealHahnSeries) (i : Surreal) : ℝ :=
  x.1.coeff <| OrderDual.toDual i

@[simp, grind =] theorem coeff_mk (f small wf) : coeff (mk f small wf) = f := by
  sorry
@[simp, grind =] theorem coeff_zero : coeff 0 = 0 := by
  sorry

@[simp, grind =]
theorem coeff_neg (x : SurrealHahnSeries) : (-x).coeff = -x.coeff := by
  sorry

@[simp, grind =]
theorem coeff_add (x y : SurrealHahnSeries) : (x + y).coeff = x.coeff + y.coeff := by
  sorry

@[simp, grind =]
theorem coeff_sub (x y : SurrealHahnSeries) : (x - y).coeff = x.coeff - y.coeff := by
  sorry

theorem coeff_add_apply (x y : SurrealHahnSeries) (i : Surreal) :
    (x + y).coeff i = x.coeff i + y.coeff i := by
  sorry

theorem coeff_sub_apply (x y : SurrealHahnSeries) (i : Surreal) :
    (x - y).coeff i = x.coeff i - y.coeff i := by
  sorry

@[ext]
theorem ext {x y : SurrealHahnSeries} (h : x.coeff = y.coeff) : x = y := by
  sorry

/-! #### `support` -/

/-- The support of the Hahn series. -/
@[expose]
def support (x : SurrealHahnSeries) : Set Surreal :=
  Function.support x.coeff

@[simp]
theorem support_coeff (x : SurrealHahnSeries) : Function.support x.coeff = x.support := by
  sorry

@[simp]
theorem support_mk (f small wf) : support (mk f small wf) = Function.support f := by
  sorry

@[simp, grind =]
theorem mem_support_iff {x : SurrealHahnSeries} {i : Surreal} : i ∈ x.support ↔ x.coeff i ≠ 0 := by
  sorry

@[simp]
theorem support_eq_empty {x : SurrealHahnSeries} : support x = ∅ ↔ x = 0 := by
  sorry

@[simp]
theorem support_zero : support 0 = ∅ := by
  sorry

theorem support_add_subset {x y : SurrealHahnSeries} : (x + y).support ⊆ x.support ∪ y.support := by
  sorry

theorem wellFoundedOn_support (x : SurrealHahnSeries) : x.support.WellFoundedOn (· > ·) := by
  sorry

instance (x : SurrealHahnSeries) : WellFoundedGT x.support :=
  x.1.isWF_support.to_subtype

instance (x : SurrealHahnSeries) :
    IsWellOrder x.support (Subrel (· > ·) (· ∈ x.support)) :=
  inferInstanceAs (IsWellOrder x.support (· > ·))

instance small_support (x : SurrealHahnSeries.{u}) : Small.{u} x.support := by
  rw [Cardinal.small_iff_lift_mk_lt_univ, Cardinal.lift_id]
  exact lt_of_lt_of_eq x.2 Cardinal.univ_umax.symm

@[simp]
theorem mk_coeff (x : SurrealHahnSeries) : mk x.coeff x.small_support x.wellFoundedOn_support = x := by
  sorry

theorem lt_def {x y : SurrealHahnSeries} : x < y ↔ toColex x.coeff < toColex y.coeff := by
  sorry
theorem le_def {x y : SurrealHahnSeries} : x ≤ y ↔ toColex x.coeff ≤ toColex y.coeff := by
  sorry

/-! #### `single` -/

/-- The Hahn series with a single entry. -/
def single (x : Surreal) (r : ℝ) : SurrealHahnSeries :=
  mk (Pi.single x r) (small_subset Pi.support_single_subset)
    (WellFoundedOn.subset wellFoundedOn_singleton Pi.support_single_subset)

@[aesop simp]
theorem coeff_single (x : Surreal) (r : ℝ) : (single x r).coeff = Pi.single x r := by
  sorry

@[simp, grind =]
theorem coeff_single_self (x : Surreal) (r : ℝ) : (single x r).coeff x = r := by
  sorry

@[grind =]
theorem coeff_single_of_ne {x y : Surreal} (h : x ≠ y) (r : ℝ) : (single x r).coeff y = 0 := by
  sorry

@[simp]
theorem single_zero (x : Surreal) : single x 0 = 0 := by
  sorry

theorem support_single_subset {x : Surreal} {r : ℝ} : support (single x r) ⊆ {x} := by
  sorry

/-! #### `trunc` -/

/-- Zeroes out any terms of the Hahn series less than or equal to `i`. -/
def trunc (x : SurrealHahnSeries) (i : Surreal) : SurrealHahnSeries :=
  let g j := if i < j then x.coeff j else 0
  have hg : Function.support g ⊆ x.support := by simp [g]
  mk _ (small_subset hg) (WellFoundedOn.subset x.wellFoundedOn_support hg)

@[aesop simp]
theorem coeff_trunc (x : SurrealHahnSeries) (i : Surreal) :
    (x.trunc i).coeff = fun j ↦ if i < j then x.coeff j else 0 := by
  sorry

@[simp, grind =]
theorem support_trunc (x : SurrealHahnSeries) (i : Surreal) :
    (x.trunc i).support = x.support ∩ Ioi i := by
  sorry

theorem support_trunc_subset (x : SurrealHahnSeries) (i : Surreal) :
    (x.trunc i).support ⊆ x.support := by
  sorry

theorem support_trunc_anti {x : SurrealHahnSeries} : Antitone fun i ↦ (trunc x i).support := by
  sorry

@[simp]
theorem coeff_trunc_of_lt {x : SurrealHahnSeries} {i j : Surreal} (h : i < j) :
    (x.trunc i).coeff j = x.coeff j := by
  sorry

@[simp]
theorem coeff_trunc_of_le {x : SurrealHahnSeries} {i j : Surreal} (h : j ≤ i) :
    (x.trunc i).coeff j = 0 := by
  sorry

theorem coeff_trunc_eq_zero {x : SurrealHahnSeries} {i j : Surreal} (h : x.coeff i = 0) :
    (x.trunc j).coeff i = 0 := by
  sorry

theorem coeff_trunc_of_mem {x : SurrealHahnSeries} {i j : Surreal} (h : j ∈ (x.trunc i).support) :
    (x.trunc i).coeff j = x.coeff j := by
  sorry

@[simp]
theorem trunc_add (x y : SurrealHahnSeries) (i : Surreal) :
    (x + y).trunc i = x.trunc i + y.trunc i := by
  sorry

@[simp]
theorem trunc_sub (x y : SurrealHahnSeries) (i : Surreal) :
    (x - y).trunc i = x.trunc i - y.trunc i := by
  sorry

@[simp]
theorem trunc_single_of_le {i j : Surreal} {r : ℝ} (h : i ≤ j) :
    (single i r).trunc j = 0 := by
  sorry

@[simp]
theorem trunc_single_of_lt {i j : Surreal} {r : ℝ} (h : j < i) :
    (single i r).trunc j = single i r := by
  sorry

@[simp]
theorem trunc_trunc (x : SurrealHahnSeries) (i j : Surreal) :
    (x.trunc i).trunc j = x.trunc (max i j) := by
  sorry

theorem trunc_eq_self_iff {x : SurrealHahnSeries} {i : Surreal} :
    x.trunc i = x ↔ ∀ j ∈ x.support, i < j := by
  sorry

alias ⟨_, trunc_eq_self⟩ := trunc_eq_self_iff

theorem trunc_eq_trunc {x : SurrealHahnSeries} {i j : Surreal} (h : i ≤ j)
    (H : ∀ k, i < k → k ≤ j → x.coeff k = 0) : x.trunc i = x.trunc j := by
  sorry

theorem trunc_add_single {x : SurrealHahnSeries} {i : Surreal} (hi : i ∈ lowerBounds x.support) :
    x.trunc i + single i (x.coeff i) = x := by
  sorry

/-! ### Indexing the support by ordinals -/

open Ordinal

local instance (x : SurrealHahnSeries.{u}) : IsWellOrder (Shrink.{u} x.support) (· > ·) :=
  (orderIsoShrink x.support).dual.symm.toRelIsoLT.toRelEmbedding.isWellOrder

/-! #### `length` -/

/-- The length of a surreal Hahn series is the order type of its support. -/
def length (x : SurrealHahnSeries.{u}) : Ordinal.{u} :=
  type (α := Shrink.{u} x.support) (· > ·)

@[simp]
theorem type_support (x : SurrealHahnSeries.{u}) :
    type (α := x.support) (· > ·) = lift.{u + 1} x.length := by
  sorry

@[simp]
theorem length_eq_zero {x : SurrealHahnSeries} : length x = 0 ↔ x = 0 := by
  sorry

@[simp]
theorem length_zero : length 0 = 0 := by
  sorry

@[gcongr]
theorem length_mono {x y : SurrealHahnSeries} (h : x.support ⊆ y.support) :
    x.length ≤ y.length := by
  sorry

/-! #### `exp` -/

/-- Returns the `i`-th largest exponent with a non-zero coefficient.

This is registered as a `RelIso` between `Iio x.length` and `x.support`, so that `x.exp.symm` can be
used to return the index of an element in the support. -/
def exp (x : SurrealHahnSeries) : (· < · : Iio x.length → _ → _) ≃r (· > · : x.support → _ → _) :=
  (enum _).trans (orderIsoShrink x.support).dual.toRelIsoLT.symm

@[simp]
theorem symm_exp_lt {x : SurrealHahnSeries} (i) : x.exp.symm i < x.length := by
  sorry

theorem exp_strictAnti {x : SurrealHahnSeries} : StrictAnti x.exp := by
  sorry

theorem exp_anti {x : SurrealHahnSeries} : Antitone x.exp := by
  sorry

@[simp]
theorem exp_lt_exp_iff {x : SurrealHahnSeries} {i j : Iio x.length} :
    x.exp i < x.exp j ↔ j < i := by
  sorry

@[simp]
theorem exp_le_exp_iff {x : SurrealHahnSeries} {i j : Iio x.length} :
    x.exp i ≤ x.exp j ↔ j ≤ i := by
  sorry

@[simp]
theorem symm_exp_lt_symm_exp_iff {x : SurrealHahnSeries} {i j : x.support} :
    x.exp.symm i < x.exp.symm j ↔ j < i := by
  sorry

@[simp]
theorem symm_exp_le_symm_exp_iff {x : SurrealHahnSeries} {i j : x.support} :
    x.exp.symm i ≤ x.exp.symm j ↔ j ≤ i := by
  sorry

theorem eq_exp_of_mem_support {x : SurrealHahnSeries} {i : Surreal} (h : i ∈ x.support) :
    ∃ j, x.exp j = i := by
  sorry

/-- This lemma is useful for rewriting. -/
theorem exp_congr {x y : SurrealHahnSeries} (h : x = y) (i : Iio x.length) :
    (x.exp i).1 = (y.exp ⟨i.1, h ▸ i.2⟩).1 := by
  sorry

@[simp]
theorem typein_support {x : SurrealHahnSeries.{u}} (i : x.support) :
    typein (· > ·) i = lift.{u + 1} (x.exp.symm i) := by
  sorry

/-! #### `coeffIdx` -/

/-- Returns the coefficient which corresponds to the `i`-th largest exponent, or `0` if no such
coefficient exists. -/
def coeffIdx (x : SurrealHahnSeries) (i : Ordinal) : ℝ :=
  if h : i < x.length then x.coeff (x.exp ⟨i, h⟩) else 0

theorem coeffIdx_of_lt {x : SurrealHahnSeries} {i : Ordinal} (h : i < x.length) :
    x.coeffIdx i = x.coeff (x.exp ⟨i, h⟩) := by
  sorry

theorem coeffIdx_of_le {x : SurrealHahnSeries} {i : Ordinal} (h : x.length ≤ i) :
    x.coeffIdx i = 0 := by
  sorry

@[simp]
theorem coeffIdx_zero : coeffIdx 0 = 0 := by
  sorry

@[simp]
theorem coeff_exp (x : SurrealHahnSeries) (i) : x.coeff (x.exp i) = x.coeffIdx i := by
  sorry

@[simp]
theorem coeffIdx_symm_exp (x : SurrealHahnSeries) (i) : x.coeffIdx (x.exp.symm i) = x.coeff i := by
  sorry

@[simp]
theorem coeffIdx_eq_zero_iff {x : SurrealHahnSeries} {i : Ordinal} :
    x.coeffIdx i = 0 ↔ x.length ≤ i := by
  sorry

/-! #### `truncIdx` -/

/-- Truncates the series at the `i`-th largest exponent, or returns it unchanged if no such
coefficient exists. -/
def truncIdx (x : SurrealHahnSeries) (i : Ordinal.{u}) : SurrealHahnSeries :=
  if h : i < x.length then x.trunc (x.exp ⟨i, h⟩) else x

@[aesop simp]
theorem support_truncIdx (x : SurrealHahnSeries) (i : Ordinal) :
    (truncIdx x i).support =
      if hi : i < x.length then x.support ∩ Ioi (x.exp ⟨i, hi⟩) else x.support := by
  sorry

theorem truncIdx_of_lt {x : SurrealHahnSeries} {i : Ordinal} (h : i < x.length) :
    x.truncIdx i = x.trunc (x.exp ⟨i, h⟩) := by
  sorry

theorem truncIdx_of_le {x : SurrealHahnSeries} {i : Ordinal} (h : x.length ≤ i) :
    x.truncIdx i = x := by
  sorry

@[simp]
theorem truncIdx_zero : truncIdx 0 = 0 := by
  sorry

@[simp, grind =]
theorem trunc_exp (x : SurrealHahnSeries) (i) : x.trunc (x.exp i) = x.truncIdx i := by
  sorry

@[simp]
theorem truncIdx_symm_exp (x : SurrealHahnSeries) (i) : x.truncIdx (x.exp.symm i) = x.trunc i := by
  sorry

theorem support_truncIdx_ssubset {x : SurrealHahnSeries} {i : Ordinal} (h : i < x.length) :
    support (truncIdx x i) ⊂ support x := by
  sorry

theorem support_truncIdx_subset (x : SurrealHahnSeries) (i : Ordinal) :
    support (truncIdx x i) ⊆ support x := by
  sorry

@[simp, grind =]
theorem length_truncIdx (x : SurrealHahnSeries) (i : Ordinal) :
    (x.truncIdx i).length = min i x.length := by
  sorry

theorem length_trunc_lt {x : SurrealHahnSeries} {i : Surreal} (h : i ∈ x.support) :
    (x.trunc i).length < x.length := by
  sorry

theorem truncIdx_ne {x : SurrealHahnSeries} {i : Ordinal} (h : i < x.length) :
    x.truncIdx i ≠ x := by
  sorry

theorem coeff_truncIdx_of_mem {x : SurrealHahnSeries} {i : Ordinal} {j k : Surreal}
    (hjk : j ≤ k) (h : j ∈ (x.truncIdx i).support) : (x.truncIdx i).coeff k = x.coeff k := by
  sorry

theorem trunc_truncIdx_of_mem {x : SurrealHahnSeries} {i : Ordinal} {a b : Surreal}
    (hab : a ≤ b) (ha : a ∈ (x.truncIdx i).support) : (x.truncIdx i).trunc b = x.trunc b := by
  sorry

/-! #### `term` -/

/-- Returns the `i`-th largest term of the sum, or `0` if it doesn't exist. -/
def term (x : SurrealHahnSeries) (i : Ordinal) : Surreal :=
  if hi : i < x.length then x.coeffIdx i * ω^ (x.exp ⟨i, hi⟩).1 else 0

theorem term_of_lt {x : SurrealHahnSeries} {i : Ordinal} (hi : i < x.length) :
    x.term i = x.coeffIdx i * ω^ (x.exp ⟨i, hi⟩).1 := by
  sorry

@[simp]
theorem term_eq_zero {x : SurrealHahnSeries} {i : Ordinal} : x.term i = 0 ↔ x.length ≤ i := by
  sorry

alias ⟨_, term_of_le⟩ := term_eq_zero

end SurrealHahnSeries
