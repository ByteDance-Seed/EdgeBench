/-
Copyright (c) 2025 Aaron Liu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aaron Liu, Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Surreal.Birthday.Basic
public import Mathlib.Order.Concept
public import Mathlib.Order.UpperLower.CompleteLattice

import Mathlib.Algebra.Order.Group.OrderIso

/-!
# Surreal cuts

A surreal cut is defined as consisting of two sets of surreals with the following properties:

- They are complementary sets.
- Every surreal in the first set is less than every surreal in the second set.

This construction resembles the construction of the surreals themselves, but yields a "bigger"
structure, which can embed the surreals, but is also a complete linear order.

Note that surreal cuts are is **not** the same as the Dedekind completion of the surreals. Whereas
the Dedekind completion maps every element of the original order to a unique Dedekind cut, every
surreal number `x` actually corresponds to two cuts `(Iio x, Ici x)` and `(Iic x, Ioi x)`, which we
call the left and right cut, respectively.

The theory of concept lattices gives us a very simple definition of surreal cuts as
`Concept Surreal Surreal (⬝ < ⬝)`. However, we've attempted to provide a thin wrapper for all
concept terminology.
-/

universe u

@[expose] public section

namespace Surreal
open Set IGame

/-- A surreal cut, sometimes called a section, consists of two complementary sets of surreals,
where every surreal in the former is less than every surreal in the latter. -/
abbrev Cut := Concept Surreal Surreal (· < ·)

namespace Cut

/-! ### Basic definitions -/

/-- The left set in a cut. This is an alias for `Concept.extent`. -/
def left (x : Cut) := x.extent
/-- The right set in a cut. This is an alias for `Concept.intent`. -/
def right (x : Cut) := x.intent

theorem left_lt_right {x : Cut} {y z : Surreal} (hy : y ∈ x.left) (hz : z ∈ x.right) : y < z := by
  sorry

theorem disjoint_left_right (x : Cut) : Disjoint x.left x.right := by
  sorry
theorem codisjoint_left_right (x : Cut) : Codisjoint x.left x.right := by
  sorry
theorem isCompl_left_right (x : Cut) : IsCompl x.left x.right := by
  sorry

theorem isLowerSet_left (c : Cut) : IsLowerSet c.left := by
  sorry

theorem isUpperSet_right (c : Cut) : IsUpperSet c.right := by
  sorry

@[ext] theorem ext {c d : Cut} (h : c.left = d.left) : c = d := by
  sorry
theorem ext' {c d : Cut} (h : c.right = d.right) : c = d := by
  sorry

theorem left_injective : Function.Injective left := by
  sorry
theorem right_injective : Function.Injective right := by
  sorry

@[simp] theorem left_inj {c d : Cut} : c.left = d.left ↔ c = d := by
  sorry
@[simp] theorem right_inj {c d : Cut} : c.right = d.right ↔ c = d := by
  sorry

@[simp] theorem left_subset_left_iff {c d : Cut} : c.left ⊆ d.left ↔ c ≤ d := by
  sorry
@[simp] theorem left_ssubset_left_iff {c d : Cut} : c.left ⊂ d.left ↔ c < d := by
  sorry

@[simp] theorem right_subset_right_iff {c d : Cut} : c.right ⊆ d.right ↔ d ≤ c := by
  sorry
@[simp] theorem right_ssubset_right_iff {c d : Cut} : c.right ⊂ d.right ↔ d < c := by
  sorry

@[simp] theorem compl_left (x : Cut) : x.leftᶜ = x.right := by
  sorry
@[simp] theorem compl_right (x : Cut) : x.rightᶜ = x.left := by
  sorry

@[simp] theorem notMem_left_iff {x : Cut} {y : Surreal} : y ∉ x.left ↔ y ∈ x.right := by
  sorry
@[simp] theorem notMem_right_iff {x : Cut} {y : Surreal} : y ∉ x.right ↔ y ∈ x.left := by
  sorry

@[simp] theorem right_bot : (⊥ : Cut).right = univ := by
  sorry
@[simp] theorem left_bot : (⊥ : Cut).left = ∅ := by
  sorry

@[simp] theorem left_top : (⊤ : Cut).left = univ := by
  sorry
@[simp] theorem right_top : (⊤ : Cut).right = ∅ := by
  sorry

instance : @Std.Total Cut (· ≤ ·) where
  total a b := le_total (α := LowerSet _) ⟨_, isLowerSet_left a⟩ ⟨_, isLowerSet_left b⟩

noncomputable instance : LinearOrder Cut :=
  by classical exact Lattice.toLinearOrder _

noncomputable instance : CompleteLinearOrder Cut where
  __ := instLinearOrder
  __ := Concept.instCompleteLattice
  __ := LinearOrder.toBiheytingAlgebra _

@[simp] theorem left_min (x y : Cut) : (min x y).left = x.left ∩ y.left := by
  sorry
@[simp] theorem right_min (x y : Cut) : (min x y).right = x.right ∪ y.right := by
  sorry

@[simp] theorem right_max (x y : Cut) : (max x y).right = x.right ∩ y.right := by
  sorry
@[simp] theorem left_max (x y : Cut) : (max x y).left = x.left ∪ y.left := by
  sorry

@[simp] theorem left_sInf (s : Set Cut) : (sInf s).left = ⋂ x ∈ s, x.left := by
  sorry
@[simp] theorem right_sInf (s : Set Cut) : (sInf s).right = ⋃ x ∈ s, x.right := by
  sorry

@[simp] theorem right_sSup (s : Set Cut) : (sSup s).right = ⋂ x ∈ s, x.right := by
  sorry
@[simp] theorem left_sSup (s : Set Cut) : (sSup s).left = ⋃ x ∈ s, x.left := by
  sorry

-- TODO: PR the iInf/iSup versions for concepts to Mathlib

@[simp] theorem left_iInf {ι} (f : ι → Cut) : (⨅ i, f i).left = ⋂ i, (f i).left := by
  sorry
@[simp] theorem right_iInf {ι} (f : ι → Cut) : (⨅ i, f i).right = ⋃ i, (f i).right := by
  sorry

@[simp] theorem right_iSup {ι} (f : ι → Cut) : (⨆ i, f i).right = ⋂ i, (f i).right := by
  sorry
@[simp] theorem left_iSup {ι} (f : ι → Cut) : (⨆ i, f i).left = ⋃ i, (f i).left := by
  sorry

theorem lt_iff_nonempty_inter {x y : Cut} : x < y ↔ (x.right ∩ y.left).Nonempty := by
  sorry

instance : Neg Cut where
  neg x := {
    extent := -x.intent
    intent := -x.extent
    upperPolar_extent := by
      ext
      simp_rw [← Concept.lowerPolar_intent, upperPolar, lowerPolar]
      simp [neg_lt]
    lowerPolar_intent := by
      ext
      simp_rw [← Concept.upperPolar_extent, upperPolar, lowerPolar]
      simp [lt_neg]
  }

@[simp] theorem left_neg (x : Cut) : (-x).left = -x.right := by
  sorry
@[simp] theorem right_neg (x : Cut) : (-x).right = -x.left := by
  sorry

instance : InvolutiveNeg Cut where
  neg_neg x := by ext; simp

@[simp] theorem neg_bot : -(⊥ : Cut) = ⊤ := by
  sorry
@[simp] theorem neg_top : -(⊤ : Cut) = ⊥ := by
  sorry

@[simp] theorem neg_min (x y : Cut) : -min x y = max (-x) (-y) := by
  sorry
@[simp] theorem neg_max (x y : Cut) : -max x y = min (-x) (-y) := by
  sorry

@[simp] theorem neg_sInf (s : Set Cut) : -sInf s = sSup (-s) := by
  sorry
@[simp] theorem neg_sSup (s : Set Cut) : -sSup s = sInf (-s) := by
  sorry

@[simp] theorem neg_iInf {ι} (f : ι → Cut) : - ⨅ i, f i = ⨆ i, - f i := by
  sorry
@[simp] theorem neg_iSup {ι} (f : ι → Cut) : - ⨆ i, f i = ⨅ i, - f i := by
  sorry

@[simp]
protected theorem neg_le_neg_iff {x y : Cut} : -x ≤ -y ↔ y ≤ x := by
  sorry

protected theorem neg_le {x y : Cut} : -x ≤ y ↔ -y ≤ x := by
  sorry
protected theorem le_neg {x y : Cut} : x ≤ -y ↔ y ≤ -x := by
  sorry

@[simp]
protected theorem neg_lt_neg_iff {x y : Cut} : -x < -y ↔ y < x := by
  sorry

protected theorem neg_lt {x y : Cut} : -x < y ↔ -y < x := by
  sorry
protected theorem lt_neg {x y : Cut} : x < -y ↔ y < -x := by
  sorry

/-! ### Cuts from games -/

/-- The left stop $L(x)$ of a game `x` is such that its right set consists of surreals
equal or larger to it. -/
def leftGame : Game →o Cut where
  toFun x := {
    extent := {y | y.toGame ⧏ x}
    intent := {y | x ≤ y.toGame}
    upperPolar_extent := by
      refine Set.ext fun y ↦ ⟨?_, fun hy z hz ↦ ?_⟩
      · simp_all [upperPolar, not_imp_comm]
      · simpa using mt hy.trans hz
    lowerPolar_intent := by
      refine Set.ext fun y ↦ ⟨fun H hx ↦ (H hx).false, fun hy z hz ↦ ?_⟩
      simpa using mt hz.trans hy
  }
  monotone' x y hy z hz := mt hy.trans hz

/-- The right stop $R(x)$ of a game `x` is such that its left set consists of surreals
equal or lesser to it. -/
def rightGame : Game →o Cut where
  toFun x := {
    extent := {y | y.toGame ≤ x}
    intent := {y | x ⧏ y.toGame}
    upperPolar_extent := by
      refine Set.ext fun y ↦ ⟨fun H hx ↦ (H hx).false, fun hy z hz ↦ ?_⟩
      simpa using mt hz.trans' hy
    lowerPolar_intent := by
      refine Set.ext fun y ↦ ⟨?_, fun hy z hz ↦ ?_⟩
      · simp_all [lowerPolar, not_imp_comm]
      · simpa using mt hy.trans' hz
  }
  monotone' x y hy z := le_trans' hy

/-- The cut just to the left of a surreal number. -/
def leftSurreal : Surreal ↪o Cut where
  toFun x := (leftGame x.toGame).copy
    (Iio x) (Ici x) (by rw [leftGame]; aesop) (by rw [leftGame]; aesop)
  inj' _ := by simp [Concept.copy, Ici_inj]
  map_rel_iff' := Iio_subset_Iio_iff

/-- The cut just to the right of a surreal number. -/
def rightSurreal : Surreal ↪o Cut where
  toFun x := (rightGame x.toGame).copy
    (Iic x) (Ioi x) (by rw [rightGame]; aesop) (by rw [rightGame]; aesop)
  inj' _ := by simp [Concept.copy, Ioi_inj]
  map_rel_iff' := Iic_subset_Iic

@[simp] theorem left_leftGame (x : Game) : (leftGame x).left = {y | y.toGame ⧏ x}:= by
  sorry
@[simp] theorem right_leftGame (x : Game) : (leftGame x).right = {y | x ≤ y.toGame} := by
  sorry
@[simp] theorem left_rightGame (x : Game) : (rightGame x).left = {y | y.toGame ≤ x} := by
  sorry
@[simp] theorem right_rightGame (x : Game) : (rightGame x).right = {y | x ⧏ y.toGame} := by
  sorry

@[simp] theorem left_leftSurreal (x : Surreal) : (leftSurreal x).left = Iio x := by
  sorry
@[simp] theorem right_leftSurreal (x : Surreal) : (leftSurreal x).right = Ici x := by
  sorry
@[simp] theorem left_rightSurreal (x : Surreal) : (rightSurreal x).left = Iic x := by
  sorry
@[simp] theorem right_rightSurreal (x : Surreal) : (rightSurreal x).right = Ioi x := by
  sorry

theorem mem_left_leftGame {x y} : y ∈ (leftGame x).left ↔ y.toGame ⧏ x := by
  sorry
theorem mem_right_leftGame {x y} : y ∈ (leftGame x).right ↔ x ≤ y.toGame := by
  sorry
theorem mem_left_rightGame {x y} : y ∈ (rightGame x).left ↔ y.toGame ≤ x := by
  sorry
theorem mem_right_rightGame {x y} : y ∈ (rightGame x).right ↔ x ⧏ y.toGame := by
  sorry

theorem mem_left_leftSurreal {x y} : y ∈ (leftSurreal x).left ↔ y < x := by
  sorry
theorem mem_right_leftSurreal {x y} : y ∈ (leftSurreal x).right ↔ x ≤ y := by
  sorry
theorem mem_left_rightSurreal {x y} : y ∈ (rightSurreal x).left ↔ y ≤ x := by
  sorry
theorem mem_right_rightSurreal {x y} : y ∈ (rightSurreal x).right ↔ x < y := by
  sorry

@[simp] theorem leftGame_toGame (x : Surreal) : leftGame x.toGame = leftSurreal x := by
  sorry

@[simp] theorem rightGame_toGame (x : Surreal) : rightGame x.toGame = rightSurreal x := by
  sorry

@[simp] theorem neg_leftGame (x : Game) : -leftGame x = rightGame (-x) := by
  sorry

@[simp] theorem neg_rightGame (x : Game) : -rightGame x = leftGame (-x) := by
  sorry

@[simp]
theorem neg_leftGame_image (s : Set Game) : -leftGame '' s = rightGame '' (-s) := by
  sorry

@[simp]
theorem neg_rightGame_image (s : Set Game) : -rightGame '' s = leftGame '' (-s) := by
  sorry

@[simp] theorem neg_leftSurreal (x : Surreal) : -leftSurreal x = rightSurreal (-x) := by
  sorry

@[simp] theorem neg_rightSurreal (x : Surreal) : -rightSurreal x = leftSurreal (-x) := by
  sorry

@[simp]
theorem neg_leftSurreal_image (s : Set Surreal) : -leftSurreal '' s = rightSurreal '' (-s) := by
  sorry

@[simp]
theorem neg_rightSurreal_image (s : Set Surreal) : -rightSurreal '' s = leftSurreal '' (-s) := by
  sorry

@[simp]
theorem le_leftSurreal_iff {x : Cut} {y : Surreal} : x ≤ leftSurreal y ↔ y ∈ x.right := by
  sorry

@[simp]
theorem leftSurreal_lt_iff {x : Surreal} {y : Cut} : leftSurreal x < y ↔ x ∈ y.left := by
  sorry

@[simp]
theorem rightSurreal_le_iff {x : Surreal} {y : Cut} : rightSurreal x ≤ y ↔ x ∈ y.left := by
  sorry

@[simp]
theorem lt_rightSurreal_iff {x : Cut} {y : Surreal} : x < rightSurreal y ↔ y ∈ x.right := by
  sorry

theorem leftSurreal_lt_rightSurreal (x : Surreal) : leftSurreal x < rightSurreal x := by
  sorry

theorem leftSurreal_lt_rightSurreal_iff {x y : Surreal} :
    leftSurreal x < rightSurreal y ↔ x ≤ y := by
  sorry

@[simp]
theorem rightSurreal_lt_leftSurreal_iff {x y : Surreal} :
    rightSurreal x < leftSurreal y ↔ x < y := by
  sorry

theorem leftSurreal_covBy_rightSurreal (x : Surreal) : leftSurreal x ⋖ rightSurreal x := by
  sorry

@[simp]
theorem leftSurreal_ne_rightSurreal (x y : Surreal) : leftSurreal x ≠ rightSurreal y := by
  sorry

@[simp]
theorem rightSurreal_ne_leftSurreal (x y : Surreal) : rightSurreal x ≠ leftSurreal y := by
  sorry

theorem leftGame_lt_rightGame_iff {x : Game} :
    leftGame x < rightGame x ↔ x ∈ range Surreal.toGame := by
  sorry

theorem sInf_leftSurreal_right (x : Cut) : sInf (leftSurreal '' x.right) = x := by
  sorry

theorem sSup_rightSurreal_left (x : Cut) : sSup (rightSurreal '' x.left) = x := by
  sorry

theorem leftSurreal_mem_of_sInf_eq {s : Set Cut} {x : Surreal}
    (hs : sInf s = leftSurreal x) : leftSurreal x ∈ s := by
  sorry

theorem rightSurreal_mem_of_sInf_eq {s : Set Cut.{u}} {x : Surreal} [Small.{u} s]
    (hs : sInf s = rightSurreal x) : rightSurreal x ∈ s := by
  sorry

theorem rightSurreal_mem_of_sSup_eq {s : Set Cut} {x : Surreal} :
    sSup s = rightSurreal x → rightSurreal x ∈ s := by
  sorry

theorem leftSurreal_mem_of_sSup_eq {s : Set Cut.{u}} {x : Surreal} [Small.{u} s] :
    sSup s = leftSurreal x → leftSurreal x ∈ s := by
  sorry

/-! ### Calculating cuts -/

/-- The supremum $L'(x)$ of all right cuts of left options of `x`.

If `infRight x ≤ supLeft x` then `leftGame x = supLeft x` and `rightGame x = infRight x`; otherwise,
`x` is equivalent to the simplest surreal between `supLeft x` and `infRight x`. -/
def supLeft (x : IGame) : Cut :=
  ⨆ i ∈ xᴸ, rightGame (.mk i)

theorem left_supLeft (x : IGame) :
    (supLeft x).left = ⋃ i ∈ xᴸ, {y | y.toGame ≤ .mk i} := by
  sorry

theorem right_supLeft (x : IGame) :
    (supLeft x).right = ⋂ i ∈ xᴸ, {y | .mk i ⧏ y.toGame} := by
  sorry

/-- The infimum $R'(x)$ of all left cuts of right options of `x`.

If `infRight x ≤ supLeft x` then `leftGame x = supLeft x` and `rightGame x = infRight x`; otherwise,
`x` is equivalent to the simplest surreal between `supLeft x` and `infRight x`. -/
def infRight (x : IGame) : Cut :=
  ⨅ i ∈ xᴿ, leftGame (.mk i)

theorem left_infRight (x : IGame) :
    (infRight x).left = ⋂ i ∈ xᴿ, {y | y.toGame ⧏ .mk i} := by
  sorry

theorem right_infRight (x : IGame) :
    (infRight x).right = ⋃ i ∈ xᴿ, {y | .mk i ≤ y.toGame} := by
  sorry

@[simp]
theorem neg_supLeft (x : IGame) : -supLeft x = infRight (-x) := by
  sorry

@[simp]
theorem neg_infRight (x : IGame) : -infRight x = supLeft (-x) := by
  sorry

theorem leftGame_eq_supLeft_of_le {x : IGame} (h : infRight x ≤ supLeft x) :
    leftGame (.mk x) = supLeft x := by
  sorry

theorem rightGame_eq_infRight_of_le {x : IGame} : infRight x ≤ supLeft x →
    rightGame (.mk x) = infRight x := by
  sorry

/-- A surreal `x` fits between two cuts `y` and `z` when `x ∈ y.right ∩ z.left`. -/
def Fits (x : Surreal) (y z : Cut) : Prop :=
  x ∈ y.right ∩ z.left

theorem Fits.lt {x : Surreal} {y z : Cut} (h : Fits x y z) : y < z := by
  sorry

@[simp]
theorem fits_leftSurreal_rightSurreal {x y : Surreal} :
    Fits x (leftSurreal y) (rightSurreal y) ↔ x = y := by
  sorry

theorem Fits.le_leftSurreal {x : Surreal} {y z : Cut} (h : Fits x y z) : y ≤ leftSurreal x := by
  sorry

theorem Fits.rightSurreal_le {x : Surreal} {y z : Cut} (h : Fits x y z) : rightSurreal x ≤ z := by
  sorry

theorem not_fits_iff {x : Surreal} {y z : Cut} : ¬ Fits x y z ↔ x ∈ y.left ∪ z.right := by
  sorry

/-- The simplest surreal number (in terms of birthday) that fits between two cuts. -/
noncomputable def simplestBtwn {x y : Cut} (h : x < y) : Surreal :=
  Classical.choose <|
    exists_minimalFor_of_wellFoundedLT _ birthday (lt_iff_nonempty_inter.1 h)

private theorem simplestBtwn_spec {x y : Cut} (h : x < y) :
    MinimalFor (fun z ↦ z ∈ x.right ∩ y.left) birthday (simplestBtwn h) := by
  sorry

theorem fits_simplestBtwn {x y : Cut} (h : x < y) : Fits (simplestBtwn h) x y := by
  sorry

theorem birthday_simplestBtwn_le_of_fits {x y : Cut} {z : Surreal}
    (hz : Fits z x y) : (simplestBtwn hz.lt).birthday ≤ z.birthday := by
  sorry

theorem fits_supLeft_infRight {x y : IGame} [x.Numeric] :
    Fits (.mk x) (supLeft y) (infRight y) ↔ x.Fits y := by
  sorry

theorem simplestBtwn_leftGame_rightGame {x : Game} (h : leftGame x < rightGame x) :
    (simplestBtwn h).toGame = x := by
  sorry

@[simp]
theorem simplestBtwn_leftSurreal_rightSurreal (x : Surreal) :
    simplestBtwn (leftSurreal_lt_rightSurreal x) = x := by
  sorry

/-- If `x` is a game with `supLeft x < infRight x`, then the simplest number between those two cuts
is equal to `x`. -/
theorem simplestBtwn_supLeft_infRight {x : IGame} (h : supLeft x < infRight x) :
    (simplestBtwn h).toGame = .mk x := by
  sorry

theorem supLeft_lt_infRight_of_equiv_numeric {x y : IGame} [y.Numeric] (h : x ≈ y) :
    supLeft x < infRight x := by
  sorry

theorem supLeft_lt_infRight_of_numeric (x : IGame) [x.Numeric] : supLeft x < infRight x := by
  sorry

/-- A characterization of games equivalent to numbers: they're precisely those with
`supLeft x < infRight x`. -/
theorem supLeft_lt_infRight_iff {x : IGame} :
    supLeft x < infRight x ↔ ∃ y : Subtype Numeric, x ≈ y := by
  sorry

end Cut
end Surreal
end
