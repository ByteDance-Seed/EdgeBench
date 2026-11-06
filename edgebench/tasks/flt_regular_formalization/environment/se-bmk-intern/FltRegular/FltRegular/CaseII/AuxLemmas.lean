module

public import Mathlib.RingTheory.ClassGroup
import Mathlib.RingTheory.DedekindDomain.Ideal.Lemmas

@[expose] public section

variable {K : Type*} {p : ℕ} [Field K] [CharZero K] {ζ : K}

open scoped nonZeroDivisors
open Polynomial

theorem isPrincipal_of_isPrincipal_pow_of_Coprime'
    {A K : Type*} [CommRing A] [IsDedekindDomain A] [Fintype (ClassGroup A)]
    [Field K] [Algebra A K] [IsFractionRing A K] (p : ℕ)
    (H : p.Coprime <| Fintype.card <| ClassGroup A) (I : FractionalIdeal A⁰ K)
    (hI : (↑(I ^ p) : Submodule A K).IsPrincipal) : (I : Submodule A K).IsPrincipal := by
  by_cases Izero : I = 0
  · rw [Izero, FractionalIdeal.coe_zero]
    exact bot_isPrincipal
  rw [← Ne, ← isUnit_iff_ne_zero] at Izero
  change Submodule.IsPrincipal ((Izero.unit' : FractionalIdeal A⁰ K) : Submodule A K)
  rw [← ClassGroup.mk_eq_one_iff, ← orderOf_eq_one_iff, ← Nat.dvd_one, ← H, Nat.dvd_gcd_iff]
  refine ⟨?_, orderOf_dvd_card⟩
  rw [orderOf_dvd_iff_pow_eq_one, ← map_pow, ClassGroup.mk_eq_one_iff]
  simp only [Units.val_pow_eq_pow_val, IsUnit.val_unit', hI]
