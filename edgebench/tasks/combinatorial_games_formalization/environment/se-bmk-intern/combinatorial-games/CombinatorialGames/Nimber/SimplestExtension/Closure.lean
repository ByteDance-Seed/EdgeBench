/-
Copyright (c) 2026 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios, Daniel Weber
-/
module

public import CombinatorialGames.Nimber.SimplestExtension.Basic

import Mathlib.Algebra.Field.Subfield.Defs
import Mathlib.Algebra.Field.ZMod
import Mathlib.Data.Rat.Cast.CharZero
import Mathlib.SetTheory.Cardinal.Subfield
import Mathlib.Algebra.CharP.Algebra

/-!
# Closures

We define `groupClosure`, `ringClosure`, and `fieldClosure`, which represent the smallest nimber
equal or greater to another, which satisfies `IsGroup`, `IsRing`, or `IsField`.
-/

universe u

public section

/-! ### For Mathlib -/

section
variable {R : Type*}

@[simp]
theorem Subring.coe_eq_univ [Ring R] {H : Subring R} : (H : Set R) = .univ ↔ H = ⊤ := by
  sorry

@[simp]
theorem Subfield.coe_eq_univ [Field R] {H : Subfield R} : (H : Set R) = .univ ↔ H = ⊤ := by
  sorry

@[simp]
theorem Subfield.toSubring_eq_top [Field R] {H : Subfield R} : H.toSubring = ⊤ ↔ H = ⊤ := by
  sorry

@[simp]
theorem Subfield.coe_bot [DivisionRing R] :
    (⊥ : Subfield R) = Set.range ((↑) : ℚ → R) := by
  sorry

instance Subfield.small_closure (s : Set R) [DivisionRing R] [Small.{u} s] :
    Small.{u} (Subfield.closure s) := by
  rw [Cardinal.small_iff_lift_mk_lt_univ] at *
  apply (Cardinal.lift_le.2 (Subfield.cardinalMk_closure_le_max s)).trans_lt
  rename_i h
  simp only [Cardinal.lift_max, Cardinal.lift_aleph0, gt_iff_lt, sup_lt_iff, h, true_and]
  exact Cardinal.aleph0_lt_univ

instance Subfield.small_closure' (s : Set R) [DivisionRing R] [Small.{u} s] :
    Small.{u} (Subfield.closure s : Set R) :=
  Subfield.small_closure s

end

noncomputable section

namespace Nimber
open Set

/-! ### Groups -/

section AddSubgroup
open AddSubgroup

theorem isGroup_sInf_compl (s : AddSubgroup Nimber) (hs : s ≠ ⊤) : IsGroup (sInf sᶜ) := by
  sorry

theorem isLowerSet_addSubgroupClosure {s : Set Nimber} (hs : IsLowerSet s) :
    IsLowerSet (closure s : Set Nimber) := by
  sorry

instance small_addSubgroupClosure (s : Set Nimber) [Small.{u} s] : Small.{u} (closure s) := by
  apply small_subset (s := (Subfield.closure s : Set Nimber))
  change closure s ≤ (Subfield.closure s).toAddSubgroup
  simp

theorem addSubgroupClosure_Iio_eq_Iio (x : Nimber) :
    ∃ y, (closure (Iio x) : Set Nimber) = Iio y := by
  sorry

/-- Returns the smallest `IsGroup` that's at least `x`. -/
def groupClosure (x : Nimber) : Nimber := Classical.choose (addSubgroupClosure_Iio_eq_Iio x)

@[simp]
theorem coe_addSubgroupClosure_Iio (x : Nimber) :
    (closure (Iio x) : Set Nimber) = Iio (groupClosure x) := by
  sorry

@[simp]
theorem mem_addSubgroupClosure_Iio {x y : Nimber} : y ∈ closure (Iio x) ↔ y < groupClosure x := by
  sorry

@[simp]
theorem le_groupClosure (x : Nimber) : x ≤ groupClosure x := by
  sorry

@[simp]
protected theorem IsGroup.groupClosure (x : Nimber) : IsGroup (groupClosure x) := by
  sorry

theorem IsGroup.groupClosure_le_iff {x y : Nimber} (h : IsGroup x) :
    y.groupClosure ≤ x ↔ y ≤ x := by
  sorry

theorem IsGroup.lt_groupClosure_iff {x y : Nimber} (h : IsGroup x) :
    x < y.groupClosure ↔ x < y := by
  sorry

theorem IsGroup.groupClosure_eq {x : Nimber} (h : IsGroup x) : groupClosure x = x := by
  sorry

theorem groupClosure_mono : Monotone groupClosure := by
  sorry

@[simp]
theorem groupClosure_zero : groupClosure 0 = 1 := by
  sorry

@[simp]
theorem groupClosure_one : groupClosure 1 = 1 := by
  sorry

@[simp]
theorem groupClosure_two : groupClosure (∗2) = ∗2 := by
  sorry

@[simp]
theorem groupClosure.two_opow (x : Ordinal) : groupClosure (∗(2 ^ x)) = ∗(2 ^ x) := by
  sorry

theorem groupClosure_of_not_isGroup {x : Nimber} (h : ¬ IsGroup x) (hx₀ : x ≠ 0) :
    groupClosure x = ∗(2 ^ (Ordinal.log 2 x.val + 1)) := by
  sorry

end AddSubgroup

/-! ### Rings -/

section Subring
open Subring

theorem isRing_sInf_compl (s : Subring Nimber) (hs : s ≠ ⊤) : IsRing (sInf sᶜ) := by
  sorry

theorem isLowerSet_subringClosure {s : Set Nimber} (hs : IsLowerSet s) :
    IsLowerSet (closure s : Set Nimber) := by
  sorry

instance small_subringClosure (s : Set Nimber) [Small.{u} s] : Small.{u} (closure s) := by
  apply small_subset (s := (Subfield.closure s : Set Nimber))
  change closure s ≤ (Subfield.closure s).toSubring
  simp

theorem subringClosure_Iio_eq_Iio (x : Nimber) : ∃ y, (closure (Iio x) : Set Nimber) = Iio y := by
  sorry

/-- Returns the smallest `IsRing` that's at least `x`. -/
def ringClosure (x : Nimber) : Nimber := Classical.choose (subringClosure_Iio_eq_Iio x)

@[simp]
theorem coe_subringClosure_Iio (x : Nimber) :
    (closure (Iio x) : Set Nimber) = Iio (ringClosure x) := by
  sorry

@[simp]
theorem mem_subringClosure_Iio {x y : Nimber} : y ∈ closure (Iio x) ↔ y < ringClosure x := by
  sorry

@[simp]
theorem le_ringClosure (x : Nimber) : x ≤ ringClosure x := by
  sorry

@[simp]
protected theorem IsRing.ringClosure (x : Nimber) : IsRing (ringClosure x) := by
  sorry

theorem IsRing.ringClosure_le_iff {x y : Nimber} (h : IsRing x) :
    y.ringClosure ≤ x ↔ y ≤ x := by
  sorry

theorem IsRing.lt_ringClosure_iff {x y : Nimber} (h : IsRing x) :
    x < y.ringClosure ↔ x < y := by
  sorry

theorem IsRing.ringClosure_eq {x : Nimber} (h : IsRing x) : ringClosure x = x := by
  sorry

theorem ringClosure_mono : Monotone ringClosure := by
  sorry

@[simp]
theorem ringClosure_zero : ringClosure 0 = ∗2 := by
  sorry

@[simp]
theorem ringClosure_one : ringClosure 1 = ∗2 := by
  sorry

@[simp]
theorem ringClosure_two : ringClosure (∗2) = ∗2 := by
  sorry

theorem groupClosure_le_ringClosure (x : Nimber) : groupClosure x ≤ ringClosure x := by
  sorry

end Subring

/-! ### Fields -/

section Subfield
open Subfield

theorem isField_sInf_compl (s : Subfield Nimber) (hs : s ≠ ⊤) : IsField (sInf sᶜ) := by
  sorry

theorem isLowerSet_subfieldClosure {s : Set Nimber} (hs : IsLowerSet s) :
    IsLowerSet (closure s : Set Nimber) := by
  sorry

instance small_subfieldClosure (s : Set Nimber) [Small.{u} s] : Small.{u} (closure s) :=
  inferInstance

theorem subfieldClosure_Iio_eq_Iio (x : Nimber) : ∃ y, (closure (Iio x) : Set Nimber) = Iio y := by
  sorry

/-- Returns the smallest `IsField` that's at least `x`. -/
def fieldClosure (x : Nimber) : Nimber := Classical.choose (subfieldClosure_Iio_eq_Iio x)

@[simp]
theorem coe_subfieldClosure_Iio (x : Nimber) :
    (closure (Iio x) : Set Nimber) = Iio (fieldClosure x) := by
  sorry

@[simp]
theorem mem_subfieldClosure_Iio {x y : Nimber} : y ∈ closure (Iio x) ↔ y < fieldClosure x := by
  sorry

@[simp]
theorem le_fieldClosure (x : Nimber) : x ≤ fieldClosure x := by
  sorry

@[simp]
protected theorem IsField.fieldClosure (x : Nimber) : IsField (fieldClosure x) := by
  sorry

theorem IsField.fieldClosure_le_iff {x y : Nimber} (h : IsField x) :
    y.fieldClosure ≤ x ↔ y ≤ x := by
  sorry

theorem IsField.lt_fieldClosure_iff {x y : Nimber} (h : IsField x) :
    x < y.fieldClosure ↔ x < y := by
  sorry

theorem IsField.fieldClosure_eq {x : Nimber} (h : IsField x) : fieldClosure x = x := by
  sorry

theorem fieldClosure_mono : Monotone fieldClosure := by
  sorry

@[simp]
theorem fieldClosure_zero : fieldClosure 0 = ∗2 := by
  sorry

@[simp]
theorem fieldClosure_one : fieldClosure 1 = ∗2 := by
  sorry

@[simp]
theorem fieldClosure_two : fieldClosure (∗2) = ∗2 := by
  sorry

theorem ringClosure_le_fieldClosure (x : Nimber) : ringClosure x ≤ fieldClosure x := by
  sorry

theorem groupClosure_le_fieldClosure (x : Nimber) : groupClosure x ≤ fieldClosure x := by
  sorry

end Subfield
end Nimber
end
