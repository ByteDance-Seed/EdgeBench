module

public import FltRegular.NumberTheory.Cyclotomic.CyclRat
public import Mathlib.NumberTheory.NumberField.ClassNumber
import Mathlib.NumberTheory.NumberField.Cyclotomic.PID

/-!
# Regular primes

## Main definitions

* `IsRegularNumber`: a natural number `n` is regular if `n` is coprime with the cardinal of the
  class group.

-/

@[expose] public section

noncomputable section

open Nat Polynomial NumberField

open scoped NumberField

variable (n p : ℕ) [hp : Fact p.Prime]

/-- A natural number `n` is regular if `n` is coprime with the cardinal of the class group -/
def IsRegularNumber [_inst : NeZero n] : Prop :=
  n.Coprime <| Fintype.card <| ClassGroup (𝓞 <| CyclotomicField n ℚ)

/-- The definition of regular primes. -/
def IsRegularPrime : Prop :=
  IsRegularNumber p

section TwoRegular

variable (A K : Type*) [CommRing A] [IsDomain A] [Field K] [Algebra A K] [IsFractionRing A K]

variable (L : Type*) [Field L] [Algebra K L]

/-- The second cyclotomic field is equivalent to the base field. -/
def cyclotomicFieldTwoEquiv [IsCyclotomicExtension {2} K L] : L ≃ₐ[K] K := by
  suffices IsSplittingField K K (cyclotomic 2 K) by
    have : IsSplittingField K L (cyclotomic 2 K) :=
      IsCyclotomicExtension.splitting_field_cyclotomic 2 K L
    exact
      (IsSplittingField.algEquiv L (cyclotomic 2 K)).trans
        (IsSplittingField.algEquiv K <| cyclotomic 2 K).symm
  exact ⟨by simpa using Splits.X_sub_C (-1 : K),
    by simp [eq_iff_true_of_subsingleton]⟩

instance IsPrincipalIdealRing_of_IsCyclotomicExtension_two
  (L : Type*) [Field L] [CharZero L] [IsCyclotomicExtension {2} ℚ L] :
    IsPrincipalIdealRing (𝓞 L) := by
  haveI : IsIntegralClosure ℤ ℤ L :=
    { algebraMap_injective := (algebraMap ℤ L).injective_int
      isIntegral_iff := fun {x} => by
        let f := cyclotomicFieldTwoEquiv ℚ L
        refine
          ⟨fun hx => ⟨IsIntegralClosure.mk' ℤ (f x) (map_isIntegral_int f hx), f.injective ?_⟩, ?_⟩
        · convert IsIntegralClosure.algebraMap_mk' ℤ (f x) (map_isIntegral_int f hx)
          simp
        · rintro ⟨y, hy⟩
          simpa [← hy] using isIntegral_algebraMap }
  let F : 𝓞 L ≃+* ℤ := NumberField.RingOfIntegers.equiv _
  exact IsPrincipalIdealRing.of_surjective F.symm.toRingHom F.symm.surjective

instance : IsCyclotomicExtension {2} ℚ (CyclotomicField 2 ℚ) :=
CyclotomicField.isCyclotomicExtension 2 ℚ

instance : IsPrincipalIdealRing (𝓞 (CyclotomicField 2 ℚ)) :=
IsPrincipalIdealRing_of_IsCyclotomicExtension_two _

theorem isRegularPrime_two : IsRegularPrime 2 := by
  rw [IsRegularPrime, IsRegularNumber]
  convert coprime_one_right _
  dsimp
  apply (card_classGroup_eq_one_iff (R := 𝓞 (CyclotomicField 2 ℚ))).2
  infer_instance

theorem isRegularPrime_three :
    haveI : Fact (Nat.Prime 3) := ⟨Nat.prime_three⟩
    IsRegularPrime 3 := by
  rw [IsRegularPrime, IsRegularNumber]
  convert coprime_one_right _
  exact classNumber_eq_one_iff.2
    (IsCyclotomicExtension.Rat.three_pid (CyclotomicField _ ℚ))

end TwoRegular

theorem isPrincipal_of_isPrincipal_pow_of_coprime
    {A : Type*} [CommRing A] [IsDedekindDomain A] [Fintype (ClassGroup A)]
    {p : ℕ}
    (H : p.Coprime <| Fintype.card <| ClassGroup A) {I : Ideal A}
    (hI : (I ^ p).IsPrincipal) : I.IsPrincipal := by
  by_cases Izero : I = 0
  · rw [Izero]
    exact bot_isPrincipal
  rw [← ClassGroup.mk0_eq_one_iff (mem_nonZeroDivisors_of_ne_zero _)] at hI ⊢
  swap
  · exact Izero
  swap
  · exact pow_ne_zero p Izero
  · rw [← orderOf_eq_one_iff, ← Nat.dvd_one, ← H, Nat.dvd_gcd_iff]
    refine ⟨?_, orderOf_dvd_card⟩
    rwa [orderOf_dvd_iff_pow_eq_one, ← map_pow, SubmonoidClass.mk_pow]
