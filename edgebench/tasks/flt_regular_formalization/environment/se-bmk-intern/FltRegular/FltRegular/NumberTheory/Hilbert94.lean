module

public import FltRegular.NumberTheory.Unramified
public import Mathlib.Algebra.Lie.OfAssociative
public import Mathlib.NumberTheory.NumberField.ClassNumber
import FltRegular.NumberTheory.Hilbert92
import FltRegular.NumberTheory.RegularPrimes
import Mathlib.RepresentationTheory.Homological.GroupCohomology.Hilbert90

@[expose] public section

open scoped NumberField

variable {K : Type} {p : ℕ} [hpri : Fact p.Prime] [Field K]

open Polynomial Module

variable {L : Type} [Field L] [Algebra K L] [FiniteDimensional K L]
  (σ : L ≃ₐ[K] L) (hσ : ∀ x, x ∈ Subgroup.zpowers σ) (hKL : finrank K L = p)

variable {A B : Type*} [CommRing A] [CommRing B] [Algebra A B] [Algebra A L] [Algebra A K]
    [Algebra B L] [IsScalarTower A B L] [IsScalarTower A K L] [IsFractionRing A K]
    [IsIntegralClosure B A L]

instance : Algebra.IsAlgebraic K L := Algebra.IsAlgebraic.of_finite K L

include hσ in
lemma comap_span_galRestrict_eq_of_cyclic (β : B) (η : Bˣ) (hβ : η * (galRestrict A K L B σ) β = β)
    (σ' : L ≃ₐ[K] L) :
    (Ideal.span {β}).comap (galRestrict A K L B σ') = Ideal.span {β} := by
  suffices (Ideal.span {β}).map
      (galRestrict A K L B σ'⁻¹).toRingEquiv.toRingHom = Ideal.span {β} by
    rwa [RingEquiv.toRingHom_eq_coe, Ideal.map_comap_of_equiv, map_inv] at this
  apply_fun (Ideal.span {·}) at hβ
  rw [← Ideal.span_singleton_mul_span_singleton, Ideal.span_singleton_eq_top.mpr η.isUnit,
    ← Ideal.one_eq_top, one_mul, ← Set.image_singleton, ← Ideal.map_span] at hβ
  change Ideal.map (galRestrict A K L B σ : B →+* B) _ = _ at hβ
  generalize σ'⁻¹ = σ'
  obtain ⟨n, rfl : σ ^ n = σ'⟩ := mem_powers_iff_mem_zpowers.mpr (hσ σ')
  rw [map_pow]
  induction n with
  | zero =>
    simp only [pow_zero, RingEquiv.toRingHom_eq_coe]
    exact Ideal.map_id _
  | succ n IH =>
    simp only [RingEquiv.toRingHom_eq_coe, pow_succ] at IH ⊢
    conv_lhs at IH => rw [← hβ, Ideal.map_map]
    exact IH

variable [IsGalois K L]


/-- This is the first part of **Hilbert Theorem 94**, which states that if `L/K` is an unramified
  cyclic finite extension of number fields of odd prime degree,
  then there is an ideal that capitulates in `K`. -/
theorem exists_not_isPrincipal_and_isPrincipal_map (K L : Type)
    [Field K] [Field L] [NumberField K] [NumberField L] [Algebra K L]
    [FiniteDimensional K L] [IsGalois K L] [IsUnramified (𝓞 K) (𝓞 L)] [h : IsCyclic (L ≃ₐ[K] L)]
    (hKL : Nat.Prime (finrank K L))
    (hKL' : finrank K L ≠ 2) :
    ∃ I : Ideal (𝓞 K), ¬I.IsPrincipal ∧ (I.map (algebraMap (𝓞 K) (𝓞 L))).IsPrincipal := by
  sorry

/-- This is the second part of **Hilbert Theorem 94**, which states that if `L/K` is an unramified
  cyclic finite extension of number fields of odd prime degree,
  then the degree divides the class number of `K`. -/
theorem dvd_card_classGroup_of_isUnramified_isCyclic {K L : Type}
    [Field K] [Field L] [NumberField K] [NumberField L] [Algebra K L]
    [FiniteDimensional K L] [IsGalois K L] [IsUnramified (𝓞 K) (𝓞 L)] [IsCyclic (L ≃ₐ[K] L)]
    (hKL : Nat.Prime (finrank K L))
    (hKL' : finrank K L ≠ 2) :
    finrank K L ∣ Fintype.card (ClassGroup (𝓞 K)) := by
  sorry
