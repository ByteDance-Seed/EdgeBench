/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import Mathlib.Algebra.Order.Field.Basic
public import Mathlib.Algebra.Order.Ring.Defs
public import Mathlib.Analysis.Normed.Field.Lemmas
public import Mathlib.Data.Nat.Log

/-!
# Dyadic numbers

A dyadic (rational) number is a rational number whose denominator is a power of two. We provide
the `CommRing` structure, as well as proving some auxiliary theorems on them.
-/

@[expose] public section

/-! ### For Mathlib -/

theorem le_of_le_of_lt_of_lt {α β : Type*} [PartialOrder α] [Preorder β] {x y : α}
    {f : α → β} (h : x < y → f x < f y) (hxy : x ≤ y) : f x ≤ f y := by
  sorry

theorem Nat.pow_log_eq_self_iff {b n : ℕ} (hb : b ≠ 0) :
    b ^ Nat.log b n = n ↔ n ∈ Set.range (b ^ ·) := by
  sorry

theorem pos_of_mem_powers {n : ℕ} (h : n ∈ Submonoid.powers 2) : 0 < n := by
  sorry

theorem ne_zero_of_mem_powers {n : ℕ} (h : n ∈ Submonoid.powers 2) : n ≠ 0 := by
  sorry

theorem dvd_iff_le_of_mem_powers {m n : ℕ}
    (hm : m ∈ Submonoid.powers 2) (hn : n ∈ Submonoid.powers 2) : m ∣ n ↔ m ≤ n := by
  sorry

namespace Dyadic

attribute [coe] toRat

instance : Coe Dyadic Rat where
  coe := toRat

@[norm_cast] alias coe_le_coe := toRat_le_toRat_iff
@[norm_cast] alias coe_lt_coe := toRat_lt_toRat_iff
@[norm_cast] alias coe_inj := toRat_inj

/-- Numerator of a dyadic number. -/
abbrev num (x : Dyadic) : ℤ := x.toRat.num
/-- Denominator of a dyadic number. -/
abbrev den (x : Dyadic) : ℕ := x.toRat.den

theorem den_ne_zero (x : Dyadic) : x.den ≠ 0 := by
  sorry
theorem den_pos (x : Dyadic) : 0 < x.den := by
  sorry
theorem one_le_den (x : Dyadic) : 1 ≤ x.den := by
  sorry
theorem den_mem_powers (x : Dyadic) : x.den ∈ Submonoid.powers 2 := by
  sorry -- dyadic rational

@[simp]
theorem den_le_one_iff_eq_one {x : Dyadic} : x.den ≤ 1 ↔ x.den = 1 := by
  sorry

@[simp]
theorem one_lt_den_iff_ne_one {x : Dyadic} : 1 < x.den ↔ x.den ≠ 1 := by
  sorry

theorem den_ne_one_of_den_lt {x y : Dyadic} (h : x.den < y.den) : y.den ≠ 1 := by
  sorry

@[ext] theorem ext {x y : Dyadic} (h : (x : ℚ) = y) : x = y := by
  sorry

@[norm_cast] alias coe_natCast := toRat_natCast
@[simp, norm_cast] theorem num_natCast (n : ℕ) : (n : Dyadic).num = n := by
  sorry
@[simp, norm_cast] theorem den_natCast (n : ℕ) : (n : Dyadic).den = 1 := by
  sorry

@[simp] theorem coe_ofNat (n : ℕ) : (ofNat(n) : Dyadic).toRat = n := by
  sorry
@[simp] theorem num_ofNat (n : ℕ) : (ofNat(n) : Dyadic).num = n := by
  sorry
@[simp] theorem den_ofNat (n : ℕ) : (ofNat(n) : Dyadic).den = 1 := by
  sorry

@[simp] theorem natCast_lt_coe {x : ℕ} {y : Dyadic} : x < y.toRat ↔ x < y := by
  sorry
@[simp] theorem natCast_le_coe {x : ℕ} {y : Dyadic} : x ≤ y.toRat ↔ x ≤ y := by
  sorry
@[simp] theorem coe_lt_natCast {x : Dyadic} {y : ℕ} : x.toRat < y ↔ x < y := by
  sorry
@[simp] theorem coe_le_natCast {x : Dyadic} {y : ℕ} : x.toRat ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast] theorem coe_eq_natCast {x : Dyadic} {y : ℕ} : x.toRat = y ↔ x = y := by
  sorry
@[simp, norm_cast] theorem natCast_eq_coe {x : ℕ} {y : Dyadic} : x = y.toRat ↔ x = y := by
  sorry

@[norm_cast] alias coe_intCast := toRat_intCast
@[simp, norm_cast] theorem num_intCast (n : ℤ) : (n : Dyadic).num = n := by
  sorry
@[simp, norm_cast] theorem den_intCast (n : ℤ) : (n : Dyadic).den = 1 := by
  sorry

@[simp] theorem intCast_lt_coe {x : ℤ} {y : Dyadic} : x < y.toRat ↔ x < y := by
  sorry
@[simp] theorem intCast_le_coe {x : ℤ} {y : Dyadic} : x ≤ y.toRat ↔ x ≤ y := by
  sorry
@[simp] theorem coe_lt_intCast {x : Dyadic} {y : ℤ} : x.toRat < y ↔ x < y := by
  sorry
@[simp] theorem coe_le_intCast {x : Dyadic} {y : ℤ} : x.toRat ≤ y ↔ x ≤ y := by
  sorry
@[simp] theorem coe_eq_intCast {x : Dyadic} {y : ℤ} : x.toRat = y ↔ x = y := by
  sorry
@[simp] theorem intCast_eq_coe {x : ℤ} {y : Dyadic} : x = y.toRat ↔ x = y := by
  sorry

instance : Inhabited Dyadic := ⟨0⟩

@[simp, norm_cast] theorem coe_zero : (0 : Dyadic).toRat = 0 := by
  sorry
@[simp] theorem num_zero : (0 : Dyadic).num = 0 := by
  sorry
@[simp] theorem den_zero : (0 : Dyadic).den = 1 := by
  sorry

@[simp] theorem zero_lt_coe {x : Dyadic} : 0 < x.toRat ↔ 0 < x := by
  sorry
@[simp] theorem zero_le_coe {x : Dyadic} : 0 ≤ x.toRat ↔ 0 ≤ x := by
  sorry
@[simp] theorem coe_lt_zero {x : Dyadic} : x.toRat < 0 ↔ x < 0 := by
  sorry
@[simp] theorem coe_le_zero {x : Dyadic} : x.toRat ≤ 0 ↔ x ≤ 0 := by
  sorry
alias coe_eq_zero := toRat_eq_zero_iff
@[simp] theorem zero_eq_coe {x : Dyadic} : 0 = x.toRat ↔ 0 = x := by
  sorry

@[simp, norm_cast] theorem coe_one : (1 : Dyadic).toRat = 1 := by
  sorry
@[simp] theorem num_one : (1 : Dyadic).num = 1 := by
  sorry
@[simp] theorem den_one : (1 : Dyadic).den = 1 := by
  sorry

@[simp] theorem one_lt_coe {x : Dyadic} : 1 < x.toRat ↔ 1 < x := by
  sorry
@[simp] theorem one_le_coe {x : Dyadic} : 1 ≤ x.toRat ↔ 1 ≤ x := by
  sorry
@[simp] theorem coe_lt_one {x : Dyadic} : x.toRat < 1 ↔ x < 1 := by
  sorry
@[simp] theorem coe_le_one {x : Dyadic} : x.toRat ≤ 1 ↔ x ≤ 1 := by
  sorry
@[simp] theorem coe_eq_one {x : Dyadic} : x.toRat = 1 ↔ x = 1 := by
  sorry
@[simp] theorem one_eq_coe {x : Dyadic} : 1 = x.toRat ↔ 1 = x := by
  sorry

instance : Nontrivial Dyadic where
  exists_pair_ne := ⟨0, 1, by decide⟩

@[simp] theorem num_neg (x : Dyadic) : (-x).num = -x.num := by
  sorry
@[simp] theorem den_neg (x : Dyadic) : (-x).den = x.den := by
  sorry

@[norm_cast] alias coe_neg := toRat_neg
@[norm_cast] alias coe_add := toRat_add
@[norm_cast] alias coe_sub := toRat_sub
@[norm_cast] alias coe_mul := toRat_mul
@[norm_cast] alias coe_pow := toRat_pow

instance : SMul Nat Dyadic where
  smul x y := x * y

@[norm_cast] theorem coe_nsmul (x : ℕ) (y : Dyadic) : (x • y).toRat = x • y.toRat := by
  sorry

instance : SMul Int Dyadic where
  smul x y := x * y

@[norm_cast] theorem coe_zsmul (x : ℤ) (y : Dyadic) : (x • y).toRat = x • y.toRat := by
  sorry

/-- The dyadic number ½. -/
def half : Dyadic := (1 : Dyadic) >>> 1

@[simp, norm_cast] theorem coe_half : half.toRat = 2⁻¹ := by
  sorry
@[simp] theorem num_half : half.num = 1 := by
  sorry
@[simp] theorem num_den : half.den = 2 := by
  sorry

/-- Constructor for the fraction `m / n`. -/
protected def mkRat (m : ℤ) {n : ℕ} (h : n ∈ Submonoid.powers 2) : Dyadic :=
  ofIntWithPrec m (Submonoid.log ⟨n, h⟩)

@[simp, norm_cast]
theorem coe_mkRat (m : ℤ) {n : ℕ} (h : n ∈ Submonoid.powers 2) :
    (Dyadic.mkRat m h).toRat = mkRat m n := by
  sorry

@[simp] theorem mkRat_self (x : Dyadic) : Dyadic.mkRat x.num x.den_mem_powers = x := by
  sorry

@[simp]
theorem mkRat_one (m : ℤ) (h : 1 ∈ Submonoid.powers 2) : Dyadic.mkRat m h = m := by
  sorry

@[simp]
theorem mkRat_lt_mkRat {m n : ℤ} {k : ℕ} (h₁ h₂ : k ∈ Submonoid.powers 2) :
    Dyadic.mkRat m h₁ < Dyadic.mkRat n h₂ ↔ m < n := by
  sorry

instance : LinearOrder Dyadic where
  le_refl := Dyadic.le_refl
  le_trans := @Dyadic.le_trans
  le_antisymm := @Dyadic.le_antisymm
  le_total := Dyadic.le_total
  lt_iff_le_not_ge := Std.LawfulOrderLT.lt_iff
  toDecidableLE := Dyadic.instDecidableLE
  toDecidableLT := Dyadic.instDecidableLT
  toDecidableEq := instDecidableEqDyadic

@[simp]
theorem mkRat_le_mkRat {m n : ℤ} {k : ℕ} (h₁ h₂ : k ∈ Submonoid.powers 2) :
    Dyadic.mkRat m h₁ ≤ Dyadic.mkRat n h₂ ↔ m ≤ n := by
  sorry

theorem mkRat_add_mkRat_self {m n : ℤ} {k : ℕ} (h₁ h₂ : k ∈ Submonoid.powers 2) :
    Dyadic.mkRat m h₁ + Dyadic.mkRat n h₂ = .mkRat (m + n) h₁ := by
  sorry

instance : CommRing Dyadic where
  add_assoc := add_assoc
  zero_add := Dyadic.zero_add
  add_zero := Dyadic.add_zero
  add_comm := add_comm
  mul_comm := mul_comm
  left_distrib := mul_add
  right_distrib := add_mul
  zero_mul := Dyadic.zero_mul
  mul_zero := Dyadic.mul_zero
  mul_assoc := mul_assoc
  one_mul := one_mul
  mul_one := mul_one
  neg_add_cancel := neg_add_cancel
  sub_eq_add_neg _ _ := rfl
  natCast_succ _ := by
    rw [← coe_inj, coe_natCast, Rat.natCast_add, coe_add, coe_natCast]
    rfl
  intCast_negSucc _ := by
    rw [← coe_inj, coe_intCast, coe_neg, coe_natCast, ← Int.cast_natCast,
      ← Rat.intCast_neg, Int.neg_ofNat_succ]
  nsmul n x := n • x
  nsmul_zero x := by ext; simp [coe_nsmul]
  nsmul_succ n x := by ext; simp [add_one_mul, coe_nsmul]
  zsmul n x := n • x
  zsmul_zero' x := by ext; simp [coe_zsmul]
  zsmul_succ' n x := by ext; simp [add_one_mul, coe_zsmul]
  zsmul_neg' n x := by
    change _ * _ = -(_ * _)
    rw [← neg_mul, ← coe_inj, coe_mul, coe_mul, coe_intCast, coe_neg, coe_intCast,
      ← Rat.intCast_neg, Int.neg_ofNat_succ]
  npow n x := x ^ n
  npow_zero x := by ext; simp
  npow_succ n x := by ext; simp [pow_succ]

instance : IsStrictOrderedRing Dyadic where
  add_le_add_left := by simp [← toRat_le_toRat_iff]
  le_of_add_le_add_left := by simp [← toRat_le_toRat_iff]
  mul_lt_mul_of_pos_left x hx y z h := by
    rw [← coe_lt_coe] at hx h ⊢
    rw [coe_mul, coe_mul]
    rw [coe_zero] at hx
    exact mul_lt_mul_of_pos_left h hx
  mul_lt_mul_of_pos_right x hx y z h := by
    rw [← coe_lt_coe] at hx h ⊢
    rw [coe_mul, coe_mul]
    rw [coe_zero] at hx
    exact mul_lt_mul_of_pos_right h hx
  zero_le_one := by decide

instance : DenselyOrdered Dyadic where
  dense x y h := by
    use half * (x + y)
    simp_rw [← coe_lt_coe] at *
    constructor
    · simpa [inv_mul_eq_div] using left_lt_add_div_two.2 h
    · simpa [inv_mul_eq_div] using add_div_two_lt_right.2 h

instance : Archimedean Dyadic where
  arch x y h := by
    rw [← coe_lt_coe, coe_zero] at h
    obtain ⟨n, hn⟩ := exists_lt_nsmul h x.toRat
    refine ⟨n, ?_⟩
    rw [← coe_le_coe, nsmul_eq_mul, coe_mul, coe_natCast, ← nsmul_eq_mul]
    exact hn.le

theorem even_den {x : Dyadic} (hx : x.den ≠ 1) : Even x.den := by
  sorry

theorem odd_num {x : Dyadic} (hx : x.den ≠ 1) : Odd x.num := by
  sorry

theorem intCast_num_eq_self_of_den_eq_one {x : Dyadic} (hx : x.den = 1) : x.num = x := by
  sorry

theorem den_mkRat_le (x : ℤ) {n : ℕ} (hn : n ≠ 0) : (mkRat x n).den ≤ n := by
  sorry

theorem den_mkRat_lt {x : Dyadic} {n : ℤ} (hn : 2 ∣ n) (hd : x.den ≠ 1) :
    (mkRat n x.den).den < x.den := by
  sorry

theorem den_add_self_lt {x : Dyadic} (hx : x.den ≠ 1) : (x + x).den < x.den := by
  sorry

theorem eq_mkRat_of_den_le {x : Dyadic} {n : ℕ} (h : x.den ≤ n) (hn : n ∈ Submonoid.powers 2) :
    ∃ m, x = .mkRat m hn := by
  sorry

instance : CanLift Dyadic Int Int.cast (·.den = 1) where
  prf x hx := ⟨x.num, Dyadic.ext (coe_intCast x.num ▸ x.toRat.den_eq_one_iff.mp hx)⟩

theorem den_add_le_den_right {x y : Dyadic} (h : x.den ≤ y.den) : (x + y).den ≤ y.den := by
  sorry

/-- Coercion as a `RingHom`. -/
@[simps]
def coeRingHom : Dyadic →+* ℚ where
  toFun := Dyadic.toRat
  map_zero' := rfl
  map_one' := rfl
  map_add' := coe_add
  map_mul' := coe_mul

end Dyadic
end
