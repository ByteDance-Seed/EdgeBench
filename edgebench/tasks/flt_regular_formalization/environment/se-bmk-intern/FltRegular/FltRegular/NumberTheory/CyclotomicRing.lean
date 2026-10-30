module

public import Mathlib.NumberTheory.NumberField.Cyclotomic.Basic
import FltRegular.NumberTheory.Cyclotomic.CyclRat
import FltRegular.NumberTheory.Cyclotomic.MoreLemmas

@[expose] public section

noncomputable section

open Polynomial NumberField

variable (p : ℕ) [hpri : Fact p.Prime]

def CyclotomicIntegers : Type := AdjoinRoot (cyclotomic p ℤ)

instance : CommRing (CyclotomicIntegers p) := by delta CyclotomicIntegers; infer_instance

open Polynomial in
lemma IsPrimitiveRoot.cyclotomic_eq_minpoly
    (x : 𝓞 (CyclotomicField p ℚ)) (hx : IsPrimitiveRoot x.1 p) :
      minpoly ℤ x = cyclotomic p ℤ := by
  apply Polynomial.map_injective (algebraMap ℤ ℚ) (RingHom.injective_int (algebraMap ℤ ℚ))
  rw [← minpoly.isIntegrallyClosed_eq_field_fractions ℚ (CyclotomicField p ℚ),
    ← cyclotomic_eq_minpoly_rat (n := p), map_cyclotomic]
  · exact hx
  · exact hpri.out.pos
  · exact IsIntegralClosure.isIntegral _ (CyclotomicField p ℚ) _

lemma AdjoinRoot.aeval_root {R} [CommRing R] (P : R[X]) : aeval (root P) P = 0 := by simp

def AdjoinRoot.equivOfMinpolyEq {R S} [CommRing R] [CommRing S] [Algebra R S]
    (P : R[X]) (pb : PowerBasis R S) (hpb : minpoly R pb.gen = P) :
    AdjoinRoot P ≃ₐ[R] S := AdjoinRoot.equiv' P pb (hpb ▸ aeval_root _) (hpb ▸ minpoly.aeval _ _)

namespace CyclotomicIntegers

@[simps! -isSimp]
def equiv :
    CyclotomicIntegers p ≃+* 𝓞 (CyclotomicField p ℚ) := by
  have H := IsCyclotomicExtension.zeta_spec p ℚ (CyclotomicField p ℚ)
  exact (AdjoinRoot.equivOfMinpolyEq (cyclotomic p ℤ) H.integralPowerBasis
    (H.integralPowerBasis_gen ▸ IsPrimitiveRoot.cyclotomic_eq_minpoly p H.toInteger H)).toRingEquiv

instance : IsDomain (CyclotomicIntegers p) :=
  AdjoinRoot.isDomain_of_prime (UniqueFactorizationMonoid.irreducible_iff_prime.mp
    (cyclotomic.irreducible hpri.out.pos))

def zeta : CyclotomicIntegers p := AdjoinRoot.root _

lemma equiv_zeta : equiv p (zeta p) = (IsCyclotomicExtension.zeta_spec
    p ℚ (CyclotomicField p ℚ)).toInteger := by
  simp [equiv_apply, zeta]

lemma prime_one_sub_zeta :
    Prime (1 - zeta p) := by
  rw [← prime_units_mul (a := -1), Units.val_neg, Units.val_one, neg_mul, one_mul, neg_sub]
  apply (MulEquiv.prime_iff (equiv p)).1
  simp only [(equiv p).map_sub, (equiv p).map_one, equiv_zeta]
  have H := IsCyclotomicExtension.zeta_spec p ℚ (CyclotomicField p ℚ)
  exact H.zeta_sub_one_prime'

lemma one_sub_zeta_mem_nonZeroDivisors :
    1 - zeta p ∈ nonZeroDivisors (CyclotomicIntegers p) := by
  rw [mem_nonZeroDivisors_iff_ne_zero]
  exact (prime_one_sub_zeta p).1

lemma not_isUnit_one_sub_zeta :
    ¬ IsUnit (1 - zeta p) := (prime_one_sub_zeta p).irreducible.1

lemma one_sub_zeta_dvd_int_iff (n : ℤ) : 1 - zeta p ∣ n ↔ ↑p ∣ n := by
  have H := IsCyclotomicExtension.zeta_spec p ℚ (CyclotomicField p ℚ)
  rw [← map_dvd_iff (equiv p), map_sub, map_one, equiv_zeta, map_intCast,
    ← neg_dvd, neg_sub]
  exact zeta_sub_one_dvd_Int_iff H

lemma one_sub_zeta_dvd : 1 - zeta p ∣ p :=
  (one_sub_zeta_dvd_int_iff _ _).2 dvd_rfl

lemma isCoprime_one_sub_zeta (n : ℤ) (hn : ¬ (p : ℤ) ∣ n) : IsCoprime (1 - zeta p) n := by
  apply (((Nat.prime_iff_prime_int.mp hpri.out).coprime_iff_not_dvd.mpr hn).map
    (algebraMap ℤ <| CyclotomicIntegers p)).of_isCoprime_of_dvd_left
  exact one_sub_zeta_dvd p

lemma exists_dvd_int (n : CyclotomicIntegers p) (hn : n ≠ 0) : ∃ m : ℤ, m ≠ 0 ∧ n ∣ m := by
  refine ⟨Algebra.norm ℤ ((equiv p) n), by simpa, ?_⟩
  rw [← map_dvd_iff (equiv p), map_intCast]
  convert RingOfIntegers.dvd_norm ℚ (equiv p n) using 1
  ext1
  exact DFunLike.congr_arg (algebraMap ℚ _) (Algebra.coe_norm_int (equiv p n))

def powerBasis : PowerBasis ℤ (CyclotomicIntegers p) :=
   AdjoinRoot.powerBasis' (cyclotomic.monic _ _)

lemma powerBasis_dim : (powerBasis p).dim = p - 1 := by
  simp [powerBasis, Nat.totient_prime hpri.out, natDegree_cyclotomic]

instance : Module.Free ℤ (CyclotomicIntegers p) := ⟨_, (powerBasis p).basis⟩

lemma nontrivial {p} (hp : p ≠ 0) : Nontrivial (CyclotomicIntegers p) := by
  apply Ideal.Quotient.nontrivial_iff.mpr
  simp only [ne_eq, Ideal.span_singleton_eq_top]
  intro h
  have := natDegree_eq_zero_of_isUnit h
  rw [natDegree_cyclotomic] at this
  exact this.not_gt (Nat.totient_pos.2 <| Nat.zero_lt_of_ne_zero hp)

lemma charZero {p} (hp : p ≠ 0) : CharZero (CyclotomicIntegers p) :=
  have := nontrivial hp
  ⟨(FaithfulSMul.algebraMap_injective _ _).comp (algebraMap ℕ ℤ).injective_nat⟩

instance : CharZero (CyclotomicIntegers p) := charZero hpri.out.ne_zero

end CyclotomicIntegers
end
