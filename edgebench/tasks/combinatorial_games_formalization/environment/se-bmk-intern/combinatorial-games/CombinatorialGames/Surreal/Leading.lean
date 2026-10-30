/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Surreal.Pow
public import Mathlib.Algebra.Order.Ring.StandardPart

/-!
# Leading term and coefficient

We define `Surreal.leadingCoeff` and `Surreal.leadingTerm` for the leading coefficient/term of a
surreal's Hahn series.

We don't yet prove this characterization; rather, these functions are a key ingredient in defining
the map from surreals into Hahn series.
-/

@[expose] public noncomputable section
namespace Surreal

open ArchimedeanClass

/-! ### Leading coefficient -/

/-- The leading coefficient of a surreal's Hahn series. -/
def leadingCoeff (x : Surreal) : ℝ :=
  stdPart (x / ω^ x.wlog)

@[simp]
theorem leadingCoeff_realCast (r : ℝ) : leadingCoeff r = r := by
  sorry

@[simp]
theorem leadingCoeff_ratCast (q : ℚ) : leadingCoeff q = q := by
  sorry

@[simp]
theorem leadingCoeff_intCast (n : ℤ) : leadingCoeff n = n := by
  sorry

@[simp]
theorem leadingCoeff_natCast (n : ℕ) : leadingCoeff n = n := by
  sorry

@[simp]
theorem leadingCoeff_zero : leadingCoeff 0 = 0 := by
  sorry

@[simp]
theorem leadingCoeff_one : leadingCoeff 1 = 1 := by
  sorry

@[simp]
theorem leadingCoeff_neg (x : Surreal) : leadingCoeff (-x) = -leadingCoeff x := by
  sorry

@[simp]
theorem leadingCoeff_mul (x y : Surreal) :
    leadingCoeff (x * y) = leadingCoeff x * leadingCoeff y := by
  sorry

@[simp]
theorem leadingCoeff_inv (x : Surreal) : leadingCoeff x⁻¹ = (leadingCoeff x)⁻¹ := by
  sorry

@[simp]
theorem leadingCoeff_div (x y : Surreal) :
    leadingCoeff (x / y) = leadingCoeff x / leadingCoeff y := by
  sorry

@[simp]
theorem leadingCoeff_wpow (x : Surreal) : leadingCoeff (ω^ x) = 1 := by
  sorry

@[simp]
theorem leadingCoeff_eq_zero {x : Surreal} : leadingCoeff x = 0 ↔ x = 0 := by
  sorry

private theorem leadingCoeff_nonneg {x : Surreal} (h : 0 ≤ x) : 0 ≤ leadingCoeff x := by
  sorry

private theorem leadingCoeff_nonpos {x : Surreal} (h : x ≤ 0) : leadingCoeff x ≤ 0 := by
  sorry

@[simp]
theorem leadingCoeff_nonneg_iff {x : Surreal} : 0 ≤ leadingCoeff x ↔ 0 ≤ x := by
  sorry

@[simp]
theorem leadingCoeff_nonpos_iff {x : Surreal} : leadingCoeff x ≤ 0 ↔ x ≤ 0 := by
  sorry

@[simp]
theorem leadingCoeff_pos_iff {x : Surreal} : 0 < leadingCoeff x ↔ 0 < x := by
  sorry

@[simp]
theorem leadingCoeff_neg_iff {x : Surreal} : leadingCoeff x < 0 ↔ x < 0 := by
  sorry

theorem leadingCoeff_monotoneOn (x : Surreal) : MonotoneOn leadingCoeff (wlog ⁻¹' {x}) := by
  sorry

private theorem stdPart_eq' {x y : Surreal} {r : ℝ}
    (hL : ∀ s < r, s * ω^ y ≤ x) (hR : ∀ s > r, x ≤ s * ω^ y) : stdPart (x / ω^ y) = r := by
  sorry

theorem wlog_eq {x y : Surreal} {r : ℝ} (hr : r ≠ 0)
    (hL : ∀ s < r, s * ω^ y ≤ x) (hR : ∀ s > r, x ≤ s * ω^ y) : x.wlog = y := by
  sorry

theorem leadingCoeff_eq {x y : Surreal} {r : ℝ} (hr : r ≠ 0)
    (hL : ∀ s < r, s * ω^ y ≤ x) (hR : ∀ s > r, x ≤ s * ω^ y) : leadingCoeff x = r := by
  sorry

theorem leadingCoeff_add_eq_left {x y : Surreal} (h : y <ᵥ x) :
    leadingCoeff (x + y) = leadingCoeff x := by
  sorry

theorem leadingCoeff_add_eq_right {x y : Surreal} (h : y <ᵥ x) :
    leadingCoeff (y + x) = leadingCoeff x := by
  sorry

theorem leadingCoeff_sub_eq_left {x y : Surreal} : y <ᵥ x →
    leadingCoeff (x - y) = leadingCoeff x := by
  sorry

theorem leadingCoeff_sub_eq_right {x y : Surreal} : y <ᵥ x →
    leadingCoeff (y - x) = -leadingCoeff x := by
  sorry

/-! ### Leading term -/

/-- The leading term of a surreal's Hahn series. -/
def leadingTerm (x : Surreal) : Surreal :=
  x.leadingCoeff * ω^ x.wlog

@[simp]
theorem leadingTerm_realCast (r : ℝ) : leadingTerm r = r := by
  sorry

@[simp]
theorem leadingTerm_ratCast (q : ℚ) : leadingTerm q = q := by
  sorry

@[simp]
theorem leadingTerm_intCast (n : ℤ) : leadingTerm n = n := by
  sorry

@[simp]
theorem leadingTerm_natCast (n : ℕ) : leadingTerm n = n := by
  sorry

@[simp]
theorem leadingTerm_zero : leadingTerm 0 = 0 := by
  sorry

@[simp]
theorem leadingTerm_one : leadingTerm 1 = 1 := by
  sorry

@[simp]
theorem leadingTerm_neg (x : Surreal) : leadingTerm (-x) = -leadingTerm x := by
  sorry

@[simp]
theorem leadingTerm_mul (x y : Surreal) : leadingTerm (x * y) = leadingTerm x * leadingTerm y := by
  sorry

@[simp]
theorem leadingTerm_inv (x : Surreal) : leadingTerm x⁻¹ = (leadingTerm x)⁻¹ := by
  sorry

@[simp]
theorem leadingTerm_div (x y : Surreal) : leadingTerm (x / y) = leadingTerm x / leadingTerm y := by
  sorry

@[simp]
theorem leadingTerm_wpow (x : Surreal) : leadingTerm (ω^ x) = ω^ x := by
  sorry

@[simp]
theorem leadingTerm_eq_zero {x : Surreal} : leadingTerm x = 0 ↔ x = 0 := by
  sorry

@[simp]
theorem leadingTerm_nonneg_iff {x : Surreal} : 0 ≤ leadingTerm x ↔ 0 ≤ x := by
  sorry

@[simp]
theorem leadingTerm_nonpos_iff {x : Surreal} : leadingTerm x ≤ 0 ↔ x ≤ 0 := by
  sorry

@[simp]
theorem leadingTerm_pos_iff {x : Surreal} : 0 < leadingTerm x ↔ 0 < x := by
  sorry

@[simp]
theorem leadingTerm_neg_iff {x : Surreal} : leadingTerm x < 0 ↔ x < 0 := by
  sorry

theorem mk_lt_mk_sub_leadingTerm {x : Surreal} (hx : x ≠ 0) :
    ArchimedeanClass.mk x < .mk (x - x.leadingTerm) := by
  sorry

@[simp]
theorem mk_leadingTerm (x : Surreal) : ArchimedeanClass.mk x.leadingTerm = .mk x := by
  sorry

theorem leadingTerm_veq (x : Surreal) : x.leadingTerm =ᵥ x := by
  sorry

@[simp]
theorem wlog_leadingTerm (x : Surreal) : x.leadingTerm.wlog = x.wlog := by
  sorry

@[simp]
theorem leadingCoeff_leadingTerm (x : Surreal) : x.leadingTerm.leadingCoeff = x.leadingCoeff := by
  sorry

@[simp]
theorem leadingTerm_leadingTerm (x : Surreal) : x.leadingTerm.leadingTerm = x.leadingTerm := by
  sorry

private theorem leadingTerm_mono' {x y : Surreal} (hx : 0 ≤ x) (h : x ≤ y) :
    x.leadingTerm ≤ y.leadingTerm := by
  sorry

theorem leadingTerm_mono : Monotone leadingTerm := by
  sorry

theorem leadingTerm_eq {x y : Surreal} {r : ℝ} (hr : r ≠ 0)
    (hL : ∀ s < r, s * ω^ y ≤ x) (hR : ∀ s > r, x ≤ s * ω^ y) : leadingTerm x = r * ω^ y := by
  sorry

theorem leadingTerm_add_eq_left {x y : Surreal} (h : y <ᵥ x) :
    leadingTerm (x + y) = leadingTerm x := by
  sorry

theorem leadingTerm_add_eq_right {x y : Surreal} (h : y <ᵥ x) :
    leadingTerm (y + x) = leadingTerm x := by
  sorry

theorem leadingTerm_sub_eq_left {x y : Surreal} : y <ᵥ x →
    leadingTerm (x - y) = leadingTerm x := by
  sorry

theorem leadingTerm_sub_eq_right {x y : Surreal} : y <ᵥ x →
    leadingTerm (y - x) = -leadingTerm x := by
  sorry

end Surreal
end
