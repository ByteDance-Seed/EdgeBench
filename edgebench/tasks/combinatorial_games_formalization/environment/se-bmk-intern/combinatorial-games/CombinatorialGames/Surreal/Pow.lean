/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Surreal.Ordinal
public import CombinatorialGames.Surreal.Real
public import CombinatorialGames.NatOrdinal.Pow
public import Mathlib.Algebra.Order.Ring.Archimedean
public import Mathlib.RingTheory.Valuation.ValuativeRel.Basic

/-!
# Surreal exponentiation

We define here the ω-map on games and on surreal numbers, representing exponentials with base `ω`.

Among other things, we prove that every non-zero surreal number is commensurate to some unique
`ω^ x`. We express this using `ArchimedeanClass`. There's two important things to note:

- The definition of `ArchimedeanClass` involves absolute values, such that e.g.
  `-ω` is commensurate to `ω`.
- The order in `ArchimedeanClass` is defined so that the equivalence class of `0` is the **largest**
  equivalence class, rather than the smallest.

## Todo

- Define the normal form of a surreal number.
-/

universe u

open Set

public section

/-! ## For Mathlib -/

-- TODO: upstream
theorem Set.image2_eq_range {α β γ : Type*} (f : α → β → γ) (s : Set α) (t : Set β) :
    Set.image2 f s t = Set.range (fun x : s × t ↦ f x.1 x.2) := by
  sorry

namespace ArchimedeanClass

theorem mk_le_mk_iff_dyadic {x y : Surreal} :
    mk x ≤ mk y ↔ ∃ q : Dyadic, 0 < q ∧ q * |y| ≤ |x| := by
  sorry

end ArchimedeanClass

/-! ### ω-map on `IGame` -/

noncomputable section
namespace IGame

/-- The ω-map on games, which is defined so that `ω^ !{s | t} = {0, r * ω^ a | r * ω^ b}` for
`a ∈ s`, `b ∈ t`, and `r` ranging over positive dyadic rationals.

The standard definition in the literature instead has `r` ranging over positive reals,
but this makes no difference as to the equivalence class of the games. -/
private def wpow (x : IGame.{u}) : IGame.{u} :=
  !{insert 0 (range (fun y : Ioi (0 : Dyadic) × xᴸ ↦ y.1 * wpow y.2)) |
    range (fun y : Ioi (0 : Dyadic) × xᴿ ↦ y.1 * wpow y.2)}
termination_by x
decreasing_by igame_wf

#adaptation_note /-- noncomputable is now needed -/ in
@[no_expose]
noncomputable instance : Wpow IGame where
  wpow := wpow

theorem wpow_def (x : IGame.{u}) : ω^ x =
    !{insert 0 (image2 (fun r y ↦ ↑r * ω^ (y : IGame)) (Ioi (0 : Dyadic)) xᴸ) |
      image2 (fun r y ↦ ↑r * ω^ y) (Ioi (0 : Dyadic)) xᴿ} := by
  sorry

theorem leftMoves_wpow (x : IGame) : (ω^ x)ᴸ =
    insert 0 (image2 (fun r y ↦ ↑r * ω^ (y : IGame)) (Ioi (0 : Dyadic)) xᴸ) := by
  sorry

theorem rightMoves_wpow (x : IGame) : (ω^ x)ᴿ =
    image2 (fun r y ↦ ↑r * ω^ (y : IGame)) (Ioi (0 : Dyadic)) xᴿ := by
  sorry

@[simp]
theorem forall_leftMoves_wpow {x : IGame} {P : IGame → Prop} : (∀ y ∈ (ω^ x)ᴸ, P y) ↔
    P 0 ∧ ∀ r : Dyadic, 0 < r → ∀ y ∈ xᴸ, P (r * ω^ y) := by
  sorry

@[simp]
theorem forall_rightMoves_wpow {x : IGame} {P : IGame → Prop} : (∀ y ∈ (ω^ x)ᴿ, P y) ↔
    ∀ r : Dyadic, 0 < r → ∀ y ∈ xᴿ, P (r * ω^ y) := by
  sorry

@[simp]
theorem exists_leftMoves_wpow {x : IGame} {P : IGame → Prop} : (∃ y ∈ (ω^ x)ᴸ, P y) ↔
    P 0 ∨ ∃ r : Dyadic, 0 < r ∧ ∃ y ∈ xᴸ, P (r * ω^ y) := by
  sorry

@[simp]
theorem exists_rightMoves_wpow {x : IGame} {P : IGame → Prop} : (∃ y ∈ (ω^ x)ᴿ, P y) ↔
    ∃ r : Dyadic, 0 < r ∧ ∃ y ∈ xᴿ, P (r * ω^ y) := by
  sorry

@[simp]
theorem zero_mem_leftMoves_wpow (x : IGame) : 0 ∈ (ω^ x)ᴸ := by
  sorry

theorem mul_wpow_mem_leftMoves_wpow {x y : IGame} {r : Dyadic} (hr : 0 ≤ r)
    (hy : y ∈ xᴸ) : r * ω^ y ∈ (ω^ x)ᴸ := by
  sorry

theorem mul_wpow_mem_rightMoves_wpow {x y : IGame} {r : Dyadic} (hr : 0 < r)
    (hy : y ∈ xᴿ) : r * ω^ y ∈ (ω^ x)ᴿ := by
  sorry

theorem natCast_mul_wpow_mem_leftMoves_wpow {x y : IGame} (n : ℕ) (hy : y ∈ xᴸ) :
    n * ω^ y ∈ (ω^ x)ᴸ := by
  sorry

theorem natCast_mul_wpow_mem_rightMoves_wpow {x y : IGame} {n : ℕ} (hn : 0 < n)
    (hy : y ∈ xᴿ) : n * ω^ y ∈ (ω^ x)ᴿ := by
  sorry

theorem wpow_mem_leftMoves_wpow {x y : IGame} (hy : y ∈ xᴸ) :
    ω^ y ∈ (ω^ x)ᴸ := by
  sorry

theorem wpow_mem_rightMoves_wpow {x y : IGame} (hy : y ∈ xᴿ) :
    ω^ y ∈ (ω^ x)ᴿ := by
  sorry

theorem zero_lf_wpow (x : IGame) : 0 ⧏ ω^ x := by
  sorry

private theorem wpow_pos' (x : IGame) [Numeric (ω^ x)] : 0 < ω^ x := by
  sorry

@[simp]
theorem wpow_zero : ω^ (0 : IGame) = 1 := by
  sorry

namespace Numeric

variable {x y z w : IGame} [Numeric x] [Numeric y] [Numeric z] [Numeric w]

private theorem wpow_strictMono_aux {x y : IGame} [Numeric x] [Numeric y]
    [Numeric (ω^ x)] [Numeric (ω^ y)] :
    (x < y → ∀ {r : ℝ}, 0 < r → r * ω^ x < ω^ y) ∧ (x ≤ y → ω^ x ≤ ω^ y) := by
  sorry

protected instance wpow (x : IGame) [Numeric x] : Numeric (ω^ x) := by
  sorry

@[simp] theorem wpow_pos (x : IGame) [Numeric x] : 0 < ω^ x := by
  sorry
@[simp] theorem wpow_nonneg (x : IGame) [Numeric x] : 0 ≤ ω^ x := by
  sorry

theorem mul_wpow_lt_wpow (r : ℝ) (h : x < y) : r * ω^ x < ω^ y := by
  sorry

/-- A version of `mul_wpow_lt_wpow` stated using dyadic rationals. -/
theorem mul_wpow_lt_wpow' (r : Dyadic) (h : x < y) : r * ω^ x < ω^ y := by
  sorry

theorem wpow_lt_mul_wpow {r : ℝ} (hr : 0 < r) (h : x < y) : ω^ x < r * ω^ y := by
  sorry

/-- A version of `wpow_lt_mul_wpow` stated using dyadic rationals. -/
theorem wpow_lt_mul_wpow' {r : Dyadic} (hr : 0 < r) (h : x < y) : ω^ x < r * ω^ y := by
  sorry

theorem mul_wpow_lt_mul_wpow (r : ℝ) {s : ℝ} (hs : 0 < s) (h : x < y) : r * ω^ x < s * ω^ y := by
  sorry

/-- A version of `mul_wpow_lt_mul_wpow` stated using dyadic rationals. -/
theorem mul_wpow_lt_mul_wpow' (r : Dyadic) {s : Dyadic} (hs : 0 < s) (h : x < y) :
    r * ω^ x < s * ω^ y := by
  sorry

theorem mul_wpow_add_mul_wpow_lt_mul_wpow (r s : ℝ) {t : ℝ} (ht : 0 < t)
     (hx : x < z) (hy : y < z) : r * ω^ x + s * ω^ y < t * ω^ z := by
  sorry

/-- A version of `mul_wpow_add_mul_wpow_lt_mul_wpow` stated using dyadic rationals. -/
theorem mul_wpow_add_mul_wpow_lt_mul_wpow' (r s : Dyadic) {t : Dyadic} (ht : 0 < t)
    (hx : x < z) (hy : y < z) : r * ω^ x + s * ω^ y < t * ω^ z := by
  sorry

theorem mul_wpow_lt_mul_wpow_add_mul_wpow (r : ℝ) {s t : ℝ} (hs : 0 < s) (ht : 0 < t)
    (hx : x < y) (hy : x < z) : r * ω^ x < s * ω^ y + t * ω^ z := by
  sorry

/-- A version of `mul_wpow_lt_mul_wpow_add_mul_wpow` stated using dyadic rationals. -/
theorem mul_wpow_lt_mul_wpow_add_mul_wpow' (r : Dyadic) {s t : Dyadic} (hs : 0 < s) (ht : 0 < t)
    (hx : x < y) (hy : x < z) : r * ω^ x < s * ω^ y + t * ω^ z := by
  sorry

@[simp]
theorem wpow_lt_wpow : ω^ x < ω^ y ↔ x < y := by
  sorry

@[simp]
theorem wpow_le_wpow : ω^ x ≤ ω^ y ↔ x ≤ y := by
  sorry

theorem wpow_congr (h : x ≈ y) : ω^ x ≈ ω^ y := by
  sorry

private theorem mulOption_lt_wpow {r s : Dyadic} (hr : 0 < r) (hs : 0 < s)
    (h₁ : x < z) (h₂ : y < w) (IH₁ : ω^ (x + w) ≈ ω^ x * ω^ w)
    (IH₂ : ω^ (z + y) ≈ ω^ z * ω^ y) (IH₃ : ω^ (z + w) ≈ ω^ z * ω^ w) :
    mulOption (ω^ x) (ω^ y) (r * ω^ z) (s * ω^ w) < ω^ (x + y) := by
  sorry

private theorem mulOption_lt_wpow' {r s : Dyadic} (hr : 0 < r) (hs : 0 < s)
    (h₁ : z < x) (h₂ : w < y) (IH₁ : ω^ (x + w) ≈ ω^ x * ω^ w)
    (IH₂ : ω^ (z + y) ≈ ω^ z * ω^ y) (IH₃ : ω^ (z + w) ≈ ω^ z * ω^ w) :
    mulOption (ω^ x) (ω^ y) (r * ω^ z) (s * ω^ w) < ω^ (x + y) := by
  sorry

private theorem wpow_lt_mulOption {r s : Dyadic} (hr : 0 < r) (hs : 0 < s)
    (h₁ : x < z) (h₂ : w < y) (IH₁ : ω^ (z + y) ≈ ω^ z * ω^ y) (IH₂ : ω^ (z + w) ≈ ω^ z * ω^ w) :
    ω^(x + y) < mulOption (ω^ x) (ω^ y) (r * ω^ z) (s * ω^ w) := by
  sorry

theorem wpow_add_equiv (x y : IGame) [Numeric x] [Numeric y] : ω^ (x + y) ≈ ω^ x * ω^ y := by
  sorry

theorem wpow_neg_equiv (x : IGame) [Numeric x] : ω^ -x ≈ (ω^ x)⁻¹ := by
  sorry

theorem wpow_sub_equiv (x y : IGame) [Numeric x] [Numeric y] : ω^ (x - y) ≈ ω^ x / ω^ y := by
  sorry

end Numeric

open NatOrdinal in
theorem toIGame_wpow_equiv (x : NatOrdinal) : (ω^ x).toIGame ≈ ω^ x.toIGame := by
  sorry

end IGame

/-! ### ω-pow on `Surreal` -/

namespace Surreal
open IGame

variable {x y : Surreal}

instance : Wpow Surreal where
  wpow := Quotient.lift (fun x ↦ mk (ω^ x)) fun _ _ h ↦ mk_eq (Numeric.wpow_congr h)

@[simp]
theorem mk_wpow (x : IGame) [Numeric x] : mk (ω^ x) = ω^ (mk x) := by
  sorry

@[simp]
theorem wpow_zero : ω^ (0 : Surreal) = 1 := by
  sorry

@[simp]
theorem wpow_pos : ∀ x : Surreal, 0 < ω^ x := by
  sorry

@[simp]
theorem wpow_nonneg (x : Surreal) : 0 ≤ ω^ x := by
  sorry

@[simp]
theorem wpow_ne_zero (x : Surreal) : ω^ x ≠ 0 := by
  sorry

@[simp]
theorem wpow_abs (x : Surreal) : |ω^ x| = ω^ x := by
  sorry

theorem strictMono_wpow : StrictMono (ω^ · : Surreal → _) := by
  sorry

@[simp]
theorem wpow_lt_wpow : ω^ x < ω^ y ↔ x < y := by
  sorry

@[simp]
theorem wpow_le_wpow : ω^ x ≤ ω^ y ↔ x ≤ y := by
  sorry

@[simp]
theorem wpow_inj : ω^ x = ω^ y ↔ x = y := by
  sorry

@[simp]
theorem wpow_add : ∀ x y : Surreal, ω^ (x + y) = ω^ x * ω^ y := by
  sorry

@[simp]
theorem wpow_neg : ∀ x : Surreal, ω^ -x = (ω^ x)⁻¹ := by
  sorry

@[simp]
theorem wpow_sub : ∀ x y : Surreal, ω^ (x - y) = ω^ x / ω^ y := by
  sorry

theorem mul_wpow_lt_wpow (r : ℝ) (h : x < y) : r * ω^ x < ω^ y := by
  sorry

theorem wpow_lt_mul_wpow {r : ℝ} (hr : 0 < r) (h : x < y) : ω^ x < r * ω^ y := by
  sorry

theorem mul_wpow_lt_mul_wpow (r : ℝ) {s : ℝ} (hs : 0 < s) (h : x < y) : r * ω^ x < s * ω^ y := by
  sorry

/-! ### Archimedean classes -/

open ArchimedeanClass

@[simp]
theorem mk_realCast {r : ℝ} (hr : r ≠ 0) : ArchimedeanClass.mk (r : Surreal) = 0 := by
  sorry

/-- We define a `ValuativeRel` instance on `Surreal` which is compatible with
`ArchimedeanClass.addValuation`. In particular, you can write `x =ᵥ y` to mean that `x` is
commensurate with `y`. -/
instance : ValuativeRel Surreal :=
  .ofValuation (ArchimedeanClass.addValuation _)

instance : (ArchimedeanClass.addValuation Surreal).Compatible where
  vle_iff_le _ _ := .rfl

theorem vle_def {x y : Surreal} : x ≤ᵥ y ↔ ArchimedeanClass.mk y ≤ .mk x := by
  sorry

theorem vlt_def {x y : Surreal} : x <ᵥ y ↔ ArchimedeanClass.mk y < .mk x := by
  sorry

theorem veq_def {x y : Surreal} : x =ᵥ y ↔ ArchimedeanClass.mk x = .mk y := by
  sorry

@[simp] theorem neg_veq {x y : Surreal} : -x =ᵥ y ↔ x =ᵥ y := by
  sorry
@[simp] theorem veq_neg {x y : Surreal} : x =ᵥ -y ↔ x =ᵥ y := by
  sorry
@[simp] theorem vle_neg {x y : Surreal} : x ≤ᵥ -y ↔ x ≤ᵥ y := by
  sorry
@[simp] theorem neg_vle {x y : Surreal} : -x ≤ᵥ y ↔ x ≤ᵥ y := by
  sorry
@[simp] theorem vlt_neg {x y : Surreal} : x <ᵥ -y ↔ x <ᵥ y := by
  sorry
@[simp] theorem neg_vlt {x y : Surreal} : -x <ᵥ y ↔ x <ᵥ y := by
  sorry

theorem archimedeanClassMk_wpow_strictAnti :
    StrictAnti fun x : Surreal ↦ ArchimedeanClass.mk (ω^ x) := by
  sorry

@[simp]
theorem wpow_vlt_wpow_iff : ω^ x <ᵥ ω^ y ↔ x < y := by
  sorry

@[simp]
theorem wpow_vle_wpow_iff : ω^ x ≤ᵥ ω^ y ↔ x ≤ y := by
  sorry

/-- `ω^ x` and `ω^ y` are commensurate iff `x = y`. -/
@[simp]
theorem wpow_veq_wpow_iff : ω^ x =ᵥ ω^ y ↔ x = y := by
  sorry

private theorem mk_lt_mk_of_ne {x : IGame} [Numeric x] (h : 0 < x)
    (Hl : ∀ y (h : y ∈ xᴸ), 0 < y → have := Numeric.of_mem_moves h;
      ArchimedeanClass.mk (mk y) ≠ .mk (mk x)) :
    ∀ y (h : y ∈ xᴸ), 0 < y → have := Numeric.of_mem_moves h;
      ArchimedeanClass.mk (mk x) < .mk (mk y) := by
  sorry

private theorem mk_lt_mk_of_ne' {x : IGame} [Numeric x] (h : 0 < x)
    (Hr : ∀ y (h : y ∈ xᴿ), have := Numeric.of_mem_moves h;
      ArchimedeanClass.mk (mk y) ≠ .mk (mk x)) :
    ∀ y (h : y ∈ xᴿ), have := Numeric.of_mem_moves h;
      ArchimedeanClass.mk (mk y) < .mk (mk x) := by
  sorry

local instance (x : IGame) [Numeric x] (y : (xᴸ ∩ Ioi 0 :)) : Numeric y :=
  .of_mem_moves y.2.1

private theorem numeric_of_forall_mk_ne_mk' {x : IGame} [Numeric x] (h : 0 < x)
    {f : (xᴸ ∩ Ioi 0 :) → Subtype Numeric.{u}} {g : xᴿ → Subtype Numeric.{u}}
    (hf : ∀ y, ArchimedeanClass.mk (ω^ (mk (f y).1)) = .mk (mk y.1))
    (hg : ∀ y, ArchimedeanClass.mk (ω^ (mk (g y).1)) = .mk (mk y.1))
    (Hl : ∀ y (h : y ∈ xᴸ), 0 < y → have := Numeric.of_mem_moves h;
      ArchimedeanClass.mk (mk y) ≠ .mk (mk x))
    (Hr : ∀ y (h : y ∈ xᴿ), have := Numeric.of_mem_moves h;
      ArchimedeanClass.mk (mk y) ≠ .mk (mk x)) :
    Numeric !{range (Subtype.val ∘ f) | range (Subtype.val ∘ g)} := by
  sorry

private theorem wpow_equiv_of_forall_mk_ne_mk' {x : IGame.{u}} [Numeric x] (h : 0 < x)
    {f : (xᴸ ∩ Ioi 0 :) → Subtype Numeric.{u}} {g : xᴿ → Subtype Numeric.{u}}
    (hf : ∀ y, ArchimedeanClass.mk (ω^ (mk (f y).1)) = .mk (mk y.1))
    (hg : ∀ y, ArchimedeanClass.mk (ω^ (mk (g y).1)) = .mk (mk y.1))
    (Hl : ∀ y (h : y ∈ xᴸ), 0 < y → have := Numeric.of_mem_moves h;
      ArchimedeanClass.mk (mk y) ≠ .mk (mk x))
    (Hr : ∀ y (h : y ∈ xᴿ), have := Numeric.of_mem_moves h;
      ArchimedeanClass.mk (mk y) ≠ .mk (mk x)) :
    ω^ !{range (Subtype.val ∘ f) | range (Subtype.val ∘ g)} ≈ x := by
  sorry

private theorem exists_mk_wpow_eq {x : IGame.{u}} [Numeric x] (h : 0 < x) :
    ∃ y : Subtype Numeric, ArchimedeanClass.mk (ω^ mk y) = .mk (mk x) := by
  sorry

/-- Every non-zero surreal is commensurate to some `ω^ x`. -/
theorem exists_wpow_veq (h : x ≠ 0) : ∃ y, ω^ y =ᵥ x := by
  sorry

/-! ### ω-logarithm -/

/-- The ω-logarithm of a positive surreal `x` is the unique surreal `y` such that `x` is
commensurate with `ω^ y`.

As with `Real.log`, we set junk values `wlog 0 = 0` and `wlog (-x) = wlog x`. -/
def wlog (x : Surreal) : Surreal :=
  if h : x = 0 then 0 else Classical.choose (exists_wpow_veq h)

/-- Returns an arbitrary representative for `Surreal.wlog`. -/
def _root_.IGame.wlog (x : IGame) : IGame := by
  classical exact if _ : Numeric x then (Surreal.mk x).wlog.out else 0

instance _root_.IGame.Numeric.wlog (x : IGame) : Numeric x.wlog := by
  rw [IGame.wlog]
  split_ifs <;> infer_instance

@[simp]
theorem mk_wlog (x : IGame) [h : Numeric x] : mk x.wlog = (mk x).wlog := by
  sorry

@[simp]
theorem wlog_zero : wlog 0 = 0 := by
  sorry

theorem wpow_wlog_veq (h : x ≠ 0) : ω^ wlog x =ᵥ x := by
  sorry

@[simp]
theorem archimedeanClassMk_wpow_wlog (h : x ≠ 0) : ArchimedeanClass.mk (ω^ x.wlog) = .mk x := by
  sorry

theorem wlog_eq_of_wpow_veq (h : ω^ y =ᵥ x) : wlog x = y := by
  sorry

@[simp]
theorem wlog_eq_iff (h : x ≠ 0) : wlog x = y ↔ ω^ y =ᵥ x := by
  sorry

theorem wlog_congr (h : x =ᵥ y) : wlog x = wlog y := by
  sorry

@[simp]
theorem wlog_wpow (x : Surreal) : wlog (ω^ x) = x := by
  sorry

@[simp]
theorem wlog_neg (x : Surreal) : wlog (-x) = wlog x := by
  sorry

@[simp]
theorem wlog_abs (x : Surreal) : wlog |x| = wlog x := by
  sorry

theorem wlog_surjective : Function.Surjective wlog := by
  sorry

theorem wlog_monotoneOn : MonotoneOn wlog (Ioi 0) := by
  sorry

theorem wlog_antitoneOn : AntitoneOn wlog (Iio 0) := by
  sorry

theorem wlog_add_eq_left {x y : Surreal} (h : y <ᵥ x) : wlog (x + y) = wlog x := by
  sorry

theorem wlog_add_eq_right {x y : Surreal} (h : y <ᵥ x) : wlog (y + x) = wlog x := by
  sorry

theorem wlog_sub_eq_left {x y : Surreal} : y <ᵥ x → wlog (x - y) = wlog x := by
  sorry

theorem wlog_sub_eq_right {x y : Surreal} : y <ᵥ x → wlog (y - x) = wlog x := by
  sorry

theorem wlog_le_wlog_iff (hx : x ≠ 0) (hy : y ≠ 0) : wlog x ≤ wlog y ↔ x ≤ᵥ y := by
  sorry

theorem wlog_le_wlog_of_vle (hx : x ≠ 0) (h : x ≤ᵥ y) : wlog x ≤ wlog y := by
  sorry

theorem wlog_lt_wlog_iff (hx : x ≠ 0) (hy : y ≠ 0) : wlog x < wlog y ↔ x <ᵥ y := by
  sorry

theorem wlog_lt_wlog_of_vlt (hx : x ≠ 0) (h : x <ᵥ y) : wlog x < wlog y := by
  sorry

@[simp]
theorem wlog_mul {x y : Surreal} (hx : x ≠ 0) (hy : y ≠ 0) : wlog (x * y) = wlog x + wlog y := by
  sorry

@[simp]
theorem wlog_realCast (r : ℝ) : wlog r = 0 := by
  sorry

@[simp] theorem wlog_ratCast (q : ℚ) : wlog q = 0 := by
  sorry
@[simp] theorem wlog_intCast (n : ℤ) : wlog n = 0 := by
  sorry
@[simp] theorem wlog_natCast (n : ℕ) : wlog n = 0 := by
  sorry
@[simp] theorem wlog_one : wlog 1 = 0 := by
  sorry

@[simp]
theorem wlog_inv (x : Surreal) : x⁻¹.wlog = -x.wlog := by
  sorry

@[simp]
theorem wlog_pow (x : Surreal) (n : ℕ) : wlog (x ^ n) = n * wlog x := by
  sorry

@[simp]
theorem wlog_zpow (x : Surreal) (n : ℤ) : wlog (x ^ n) = n * wlog x := by
  sorry

@[simp high] -- This should fire before `ArchimedeanClass.mk_div`
theorem archimedeanClassMk_div_wpow_wlog (x : Surreal) :
    ArchimedeanClass.mk (x / ω^ x.wlog) = .mk x - .mk x := by
  sorry

theorem mk_div_wpow_wlog_of_ne_zero {x : Surreal} (hx : x ≠ 0) :
    ArchimedeanClass.mk (x / ω^ x.wlog) = 0 := by
  sorry

private theorem ofSets_wlog_eq {x : IGame} [Numeric x] :
    !{IGame.wlog '' {y ∈ xᴸ | 0 < y} | IGame.wlog '' xᴿ} =
    !{range (Subtype.val ∘ fun x : (xᴸ ∩ Ioi 0 :) ↦ ⟨_, Numeric.wlog x⟩) |
      range (Subtype.val ∘ fun x : xᴿ ↦ ⟨_, Numeric.wlog x⟩)} := by
  sorry

private theorem mk_wpow_wlog_left {x : IGame} [Numeric x] :
    ∀ y : (xᴸ ∩ Ioi 0 :), ArchimedeanClass.mk (ω^ mk y.1.wlog) = .mk (mk y) := by
  sorry

private theorem mk_wpow_wlog_right {x : IGame} [Numeric x] (h : 0 < x) :
    ∀ y : xᴿ, ArchimedeanClass.mk (ω^ mk y.1.wlog) = .mk (mk y) := by
  sorry

theorem numeric_of_forall_mk_ne_mk {x : IGame} [Numeric x] (h : 0 < x)
    (Hl : ∀ y (hy : y ∈ xᴸ), 0 < y →
      ArchimedeanClass.mk (@mk y (Numeric.of_mem_moves hy)) ≠ .mk (mk x))
    (Hr : ∀ y (hy : y ∈ xᴿ),
      ArchimedeanClass.mk (@mk y (Numeric.of_mem_moves hy)) ≠ .mk (mk x)) :
    Numeric !{IGame.wlog '' {y ∈ xᴸ | 0 < y} | IGame.wlog '' xᴿ} := by
  sorry

theorem wpow_equiv_of_forall_mk_ne_mk {x : IGame} [Numeric x] (h : 0 < x)
    (Hl : ∀ y (hy : y ∈ xᴸ), 0 < y →
      ArchimedeanClass.mk (@mk y (Numeric.of_mem_moves hy)) ≠ .mk (mk x))
    (Hr : ∀ y (hy : y ∈ xᴿ),
      ArchimedeanClass.mk (@mk y (Numeric.of_mem_moves hy)) ≠ .mk (mk x)) :
    ω^ !{IGame.wlog '' {y ∈ xᴸ | 0 < y} | IGame.wlog '' xᴿ} ≈ x := by
  sorry

/-- A game not commensurate with its positive options is a power of `ω`. -/
theorem mem_range_wpow_of_forall_mk_ne_mk {x : IGame} [Numeric x] (h : 0 < x)
    (Hl : ∀ y (hy : y ∈ xᴸ), 0 < y →
      ArchimedeanClass.mk (@mk y (Numeric.of_mem_moves hy)) ≠ .mk (mk x))
    (Hr : ∀ y (hy : y ∈ xᴿ),
      ArchimedeanClass.mk (@mk y (Numeric.of_mem_moves hy)) ≠ .mk (mk x)) :
    mk x ∈ range (ω^ ·) := by
  sorry

@[simp]
theorem toSurreal_wpow (x : NatOrdinal) : (ω^ x).toSurreal = ω^ x.toSurreal := by
  sorry

end Surreal
end
