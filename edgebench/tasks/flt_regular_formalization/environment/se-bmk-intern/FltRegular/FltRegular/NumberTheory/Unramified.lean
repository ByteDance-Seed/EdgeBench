module

public import Mathlib.NumberTheory.RamificationInertia.Basic
public import Mathlib.RingTheory.IntegralClosure.IntegralRestrict
import Mathlib.NumberTheory.RamificationInertia.Galois
import Mathlib.Order.CompletePartialOrder
import Mathlib.RingTheory.DedekindDomain.Different

/-!
# Unramified extensions

## Main definition
- `IsUnramifiedAt`:
  `IsUnramifiedAt S p` states that every prime in `S` over `p` has ramification index `1`.
- `IsUnramified`:
  An extension is unramified if it is unramified at every (finite) primes.

## Main results
- `comap_map_eq_of_isUnramified`: If `K/L` is galois, `S/R` is unramified, then any
  ideal `I` fixed by `Gal(L/K) satisfies `(I ∩ R)S = I`.
- `isUnramifiedAt_of_Separable_minpoly`: If `L = K[α]` with `α` integral over `R`, and `f'(α) mod p`
  is separable for some ideal `p` of `R` (with `f` being the minpoly of `α` over `R`), then `S/R` is
  unramified at `p`.
-/

@[expose] public section
open UniqueFactorizationMonoid Ideal

attribute [local instance] FractionRing.liftAlgebra

variable (R K L S : Type*) [CommRing R] [CommRing S] [Algebra R S] [Field K] [Field L]
    [IsDedekindDomain R] [Algebra R K] [IsFractionRing R K] [Algebra S L]
    [Algebra K L] [Algebra R L] [IsScalarTower R S L] [IsScalarTower R K L]
    [IsIntegralClosure S R L] [FiniteDimensional K L]

def IsUnramifiedAt {R} (S : Type*) [CommRing R] [CommRing S] [Algebra R S] (p : Ideal R) : Prop :=
  ∀ P ∈ primesOver p S, Ideal.ramificationIdx Algebra.algebraMap p P = 1

/-- TODO: Link this to `FormallyUnramified`. -/
-- Should we name this `IsUnramifiedAtFinitePrimes`?
class IsUnramified (R S : Type*) [CommRing R] [CommRing S] [Algebra R S] : Prop where
  isUnramifiedAt : ∀ (p : Ideal R) [p.IsPrime] (_ : p ≠ ⊥), IsUnramifiedAt S p

variable {R} {S}

section port

open Classical in
noncomputable abbrev IsDedekindDomain.primesOverFinset {A : Type*} [CommRing A]
    (p : Ideal A) (B : Type*) [CommRing B] [IsDedekindDomain B] [Algebra A B] :
    Finset (Ideal B) :=
  (UniqueFactorizationMonoid.factors (Ideal.map (algebraMap A B) p)).toFinset

theorem IsDedekindDomain.coe_primesOverFinset {A : Type*} [CommRing A] {p : Ideal A}
    (hpb : p ≠ ⊥) [hpm : p.IsMaximal] (B : Type*) [CommRing B] [IsDedekindDomain B]
    [Algebra A B] [IsDomain A] [Module.IsTorsionFree A B] :
    ↑(primesOverFinset p B) = p.primesOver B := by
  ext
  simpa using (Ideal.mem_primesOver_iff_mem_normalizedFactors _ hpb).symm

open Classical in
theorem IsDedekindDomain.primesOverFinset_eq {A : Type*} [CommRing A] {p : Ideal A}
    (B : Type*) [CommRing B] [IsDedekindDomain B]
    [Algebra A B] [IsDomain A] [Module.IsTorsionFree A B] :
    (primesOverFinset p B) =
      (UniqueFactorizationMonoid.factors (Ideal.map (algebraMap A B) p)).toFinset := rfl

end port

lemma prod_primesOverFinset_of_isUnramified [IsUnramified R S] [IsDedekindDomain S]
    [Module.IsTorsionFree R S] (p : Ideal R) [p.IsPrime] (hp : p ≠ ⊥) :
    ∏ P ∈ IsDedekindDomain.primesOverFinset p S, P = p.map (algebraMap R S) := by
  classical
  have hpbot' : p.map (algebraMap R S) ≠ ⊥ := (Ideal.map_eq_bot_iff_of_injective
      (Module.isTorsionFree_iff_algebraMap_injective.mp inferInstance)).not.mpr hp
  rw [← associated_iff_eq.mp (factors_pow_count_prod hpbot')]
  apply Finset.prod_congr rfl
  intros P hP
  convert (pow_one _).symm
  have : p.IsMaximal := Ring.DimensionLEOne.maximalOfPrime hp ‹_›
  rw [← Finset.mem_coe, IsDedekindDomain.coe_primesOverFinset hp] at hP
  rw [← Ideal.IsDedekindDomain.ramificationIdx_eq_factors_count hpbot' hP.1
    (ne_bot_of_mem_primesOver hp hP)]
  exact IsUnramified.isUnramifiedAt _ hp _ hP

lemma comap_map_eq_of_isUnramified [IsGalois K L] [IsUnramified R S] (I : Ideal S)
    (hI : ∀ σ : L ≃ₐ[K] L, I.comap (galRestrict R K L S σ) = I) :
    (I.comap (algebraMap R S)).map (algebraMap R S) = I := by
  classical
  have : IsDomain S :=
    (IsIntegralClosure.equiv R S L (integralClosure R L)).toMulEquiv.isDomain (integralClosure R L)
  have := IsIntegralClosure.isDedekindDomain R K L S
  have hRS : Function.Injective (algebraMap R S) := by
    refine Function.Injective.of_comp (f := algebraMap S L) ?_
    rw [← RingHom.coe_comp, ← IsScalarTower.algebraMap_eq, IsScalarTower.algebraMap_eq R K L]
    exact (algebraMap K L).injective.comp (IsFractionRing.injective _ _)
  have := Module.isTorsionFree_iff_algebraMap_injective.mpr hRS
  by_cases hIbot : I = ⊥
  · rw [hIbot, Ideal.comap_bot_of_injective _ hRS, Ideal.map_bot]
  have h1 : Algebra.IsIntegral R S := IsIntegralClosure.isIntegral_algebra R L
  have hIbot' : I.comap (algebraMap R S) ≠ ⊥ := mt Ideal.eq_bot_of_comap_eq_bot hIbot
  have : ∀ p, (p.IsPrime ∧ I.comap (algebraMap R S) ≤ p) → ∃ P ≥ I, P ∈ primesOver p S := by
    intro p ⟨hp₁, hp₂⟩
    obtain ⟨P, hP1, hP2, hP3⟩ := Ideal.exists_ideal_over_prime_of_isIntegral _ _ hp₂
    exact ⟨P, hP1, hP2, ⟨hP3.symm⟩⟩
  choose 𝔓 h𝔓 h𝔓' using this
  suffices I = ∏ p ∈ (factors (I.comap <| algebraMap R S)).toFinset,
    (p.map (algebraMap R S)) ^ (if h : _ then (factors I).count (𝔓 p h) else 0) by
    simp_rw [← Ideal.mapHom_apply, ← map_pow, ← map_prod, Ideal.mapHom_apply] at this
    rw [this, Ideal.map_comap_map]
  conv_lhs => rw [← associated_iff_eq.mp (factors_pow_count_prod hIbot)]
  rw [← Finset.prod_fiberwise_of_maps_to (g := (Ideal.comap (algebraMap R S) : Ideal S → Ideal R))
    (t := (factors (I.comap (algebraMap R S))).toFinset)]
  · apply Finset.prod_congr rfl
    intros p hp
    simp only [factors_eq_normalizedFactors, Multiset.mem_toFinset,
      Ideal.mem_normalizedFactors_iff hIbot'] at hp
    have hpbot : p ≠ ⊥ := fun hp' ↦ hIbot' (eq_bot_iff.mpr (hp.2.trans_eq hp'))
    have hpbot' : p.map (algebraMap R S) ≠ ⊥ := (Ideal.map_eq_bot_iff_of_injective hRS).not.mpr
      hpbot
    have := hp.1
    rw [← prod_primesOverFinset_of_isUnramified p hpbot, ← Finset.prod_pow]
    have : p.IsMaximal := Ring.DimensionLEOne.maximalOfPrime hpbot this
    apply Finset.prod_congr
    · ext P
      rw [factors_eq_normalizedFactors, Finset.mem_filter, Multiset.mem_toFinset,
        Ideal.mem_normalizedFactors_iff hIbot, ← Finset.mem_coe,
          IsDedekindDomain.coe_primesOverFinset hpbot S]
      refine ⟨fun H ↦ ⟨H.1.1, ⟨H.2.symm⟩⟩, fun H ↦ ⟨⟨H.1, ?_⟩, ?_⟩⟩
      · have ⟨σ, hσ⟩ := exists_comap_galRestrict_eq R K L S (h𝔓' _ hp) H
        rw [← hσ, ← hI σ]
        exact Ideal.comap_mono (h𝔓 _ hp)
      · have := H.2.1
        rw [Ideal.under_def] at this
        exact this.symm
    · intro P hP
      rw [← Finset.mem_coe, IsDedekindDomain.coe_primesOverFinset hpbot S] at hP
      congr
      rw [dif_pos hp, ← Nat.cast_inj (R := ENat), ← normalize_eq P, factors_eq_normalizedFactors,
        ← emultiplicity_eq_count_normalizedFactors
          (prime_of_mem_primesOver hpbot hP).irreducible hIbot,
        ← normalize_eq (𝔓 p hp), ← emultiplicity_eq_count_normalizedFactors
          (prime_of_mem_primesOver hpbot <| h𝔓' p hp).irreducible hIbot,
          emultiplicity_eq_emultiplicity_iff]
      intro n
      have ⟨σ, hσ⟩ := exists_comap_galRestrict_eq R K L S (h𝔓' _ hp) hP
      rw [Ideal.dvd_iff_le, Ideal.dvd_iff_le]
      conv_lhs => rw [← hI σ, ← hσ,
        Ideal.comap_le_iff_le_map _ (AlgEquiv.bijective _), Ideal.map_pow,
        Ideal.map_comap_of_surjective _ (AlgEquiv.surjective _)]
  · intro P hP
    simp only [factors_eq_normalizedFactors, Multiset.mem_toFinset,
      Ideal.mem_normalizedFactors_iff hIbot] at hP
    simp only [factors_eq_normalizedFactors, Multiset.mem_toFinset,
      Ideal.mem_normalizedFactors_iff hIbot']
    exact ⟨hP.1.comap _, Ideal.comap_mono hP.2⟩

section KummerDedekind

end KummerDedekind

open nonZeroDivisors Polynomial

attribute [local instance] Ideal.Quotient.field in
lemma isUnramifiedAt_of_Separable_minpoly' [Algebra.IsSeparable K L]
    (p : Ideal R) [hp : p.IsPrime] (hpbot : p ≠ ⊥) (x : S)
    (hx' : Algebra.adjoin K {algebraMap S L x} = ⊤)
    (h : Polynomial.Separable ((minpoly R x).map (Ideal.Quotient.mk p))) :
    IsUnramifiedAt S p := by
  classical
  have : IsDomain S :=
    (IsIntegralClosure.equiv R S L (integralClosure R L)).toMulEquiv.isDomain (integralClosure R L)
  have hRS : Function.Injective (algebraMap R S) := by
    refine Function.Injective.of_comp (f := algebraMap S L) ?_
    rw [← RingHom.coe_comp, ← IsScalarTower.algebraMap_eq, IsScalarTower.algebraMap_eq R K L]
    exact (algebraMap K L).injective.comp (IsFractionRing.injective _ _)
  have := Module.isTorsionFree_iff_algebraMap_injective.mpr hRS
  have := IsIntegralClosure.isNoetherian R K L S
  have := IsIntegralClosure.isDedekindDomain R K L S
  have := IsIntegralClosure.isFractionRing_of_finite_extension R K L S
  have := aeval_derivative_mem_differentIdeal R K L x hx'
  have H : RingHom.comp (algebraMap (FractionRing R) (FractionRing S))
    (FractionRing.algEquiv R K).symm.toRingEquiv =
      RingHom.comp (FractionRing.algEquiv S L).symm.toRingEquiv (algebraMap K L) := by
    apply IsLocalization.ringHom_ext R⁰
    ext r
    simp only [RingHom.coe_comp, RingHom.coe_coe, Function.comp_apply,
      ← IsScalarTower.algebraMap_apply]
    change (algebraMap (FractionRing R) (FractionRing S))
      ((FractionRing.algEquiv R K).symm ((algebraMap R K) r)) =
      (FractionRing.algEquiv S L).symm ((algebraMap R L) r)
    rw [IsScalarTower.algebraMap_apply R S L, AlgEquiv.commutes,
      ← IsScalarTower.algebraMap_apply, AlgEquiv.commutes]
    rfl
  have : Algebra.IsSeparable (FractionRing R) (FractionRing S) :=
    Algebra.IsSeparable.of_equiv_equiv _ _ H
  have := hp.isMaximal hpbot
  intro P hP
  letI : IsScalarTower S (S ⧸ P) (S ⧸ P) := IsScalarTower.right
  have := primesOver.isMaximal ⟨P, hP⟩
  apply le_antisymm
  · rw [← tsub_eq_zero_iff_le]
    by_contra H
    have hxP : aeval x (derivative (minpoly R x)) ∈ P := by
      have : differentIdeal R S ≤ P := by
        rw [← Ideal.dvd_iff_le]
        exact (dvd_pow_self _ H).trans (pow_sub_one_dvd_differentIdeal R P _ hpbot <|
          Ideal.dvd_iff_le.mpr <| Ideal.le_pow_ramificationIdx)
      exact this (aeval_derivative_mem_differentIdeal R K L _ hx')
    rw [← Ideal.Quotient.eq_zero_iff_mem, ← Ideal.Quotient.algebraMap_eq] at hxP
    have := hP.2.1
    rw [Ideal.under_def] at this
    have := (separable_map (Ideal.quotientMap P (algebraMap R S) this.symm.ge)).mpr h
    rw [Polynomial.map_map, Ideal.quotientMap_comp_mk] at this
    obtain ⟨a, b, e⟩ := this
    apply_fun (aeval (Ideal.Quotient.mk P x)) at e
    simp_rw [← Ideal.Quotient.algebraMap_eq, ← Polynomial.map_map, derivative_map, map_add,
      _root_.map_mul, aeval_map_algebraMap, aeval_algebraMap_apply, minpoly.aeval, hxP, map_zero,
      mul_zero, zero_add, map_one, zero_ne_one] at e
  · rw [Ideal.IsDedekindDomain.ramificationIdx_eq_factors_count _
      (primesOver.isMaximal ⟨P, hP⟩).isPrime (ne_bot_of_mem_primesOver hpbot hP),
      Multiset.one_le_count_iff_mem, ← Multiset.mem_toFinset]
    · change _ ∈ (factors (Ideal.map (algebraMap R S) p)).toFinset
      rwa [← IsDedekindDomain.primesOverFinset_eq,
        ← Finset.mem_coe, IsDedekindDomain.coe_primesOverFinset hpbot]
    change Ideal.map (algebraMap R S) p ≠ ⊥
    rwa [ne_eq, Ideal.map_eq_bot_iff_of_injective hRS]

lemma isUnramifiedAt_of_Separable_minpoly [Algebra.IsSeparable K L]
    (p : Ideal R) [hp : p.IsPrime] (hpbot : p ≠ ⊥) (x : L) (hx : IsIntegral R x)
    (hx' : Algebra.adjoin K {x} = ⊤)
    (h : Polynomial.Separable ((minpoly R x).map (Ideal.Quotient.mk p))) :
    IsUnramifiedAt S p := by
  rw [← IsIntegralClosure.algebraMap_mk' S x hx, minpoly.algebraMap_eq
    (IsIntegralClosure.algebraMap_injective S R L)] at h
  exact isUnramifiedAt_of_Separable_minpoly' K L p hpbot (IsIntegralClosure.mk' S x hx)
    (by rwa [IsIntegralClosure.algebraMap_mk']) h
