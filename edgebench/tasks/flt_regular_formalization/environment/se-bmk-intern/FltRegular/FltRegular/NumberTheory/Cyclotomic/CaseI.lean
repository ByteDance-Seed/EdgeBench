module

public import FltRegular.NumberTheory.Cyclotomic.UnitLemmas
import FltRegular.NumberTheory.Cyclotomic.CyclRat
import Mathlib.NumberTheory.NumberField.Cyclotomic.Basic

@[expose] public section

open scoped NumberField nonZeroDivisors

variable {p : ℕ} [NeZero p] {K : Type*} [Field K] [NumberField K] [IsCyclotomicExtension {p} ℚ K]

variable {ζ : K} (hζ : IsPrimitiveRoot ζ p)

open FractionalIdeal NumberField IsCMField

variable (i : ℤ)

namespace FltRegular.CaseI

theorem pow_sub_intGalConj_mem (α : 𝓞 K) [Fact (p.Prime)] (hp : 2 < p) :
    haveI := IsCyclotomicExtension.IsCMField K hp
    (α ^ p - ringOfIntegersComplexConj K (α ^ p)) ∈ Ideal.span ({(p : 𝓞 K)} : Set (𝓞 K)) := by
  obtain ⟨a, ha⟩ := exists_int_sub_pow_prime_dvd p α
  rw [Ideal.mem_span_singleton] at ha ⊢
  obtain ⟨γ, hγ⟩ := ha
  rw [sub_eq_iff_eq_add] at hγ
  rw [hγ, _root_.map_add, _root_.map_mul, map_natCast, map_intCast, add_sub_add_right_eq_sub,
    ← mul_sub]
  exact dvd_mul_right _ _

theorem exists_int_sum_eq_zero'_aux (x y i : ℤ) [Fact (p.Prime)] (hp : 2 < p) :
    haveI := IsCyclotomicExtension.IsCMField K hp
    ringOfIntegersComplexConj K (x + y * ↑(hζ.unit' ^ i) : 𝓞 K) =
      x + y * (hζ.unit' ^ (-i) : (𝓞 K)ˣ) := by
  haveI := IsCyclotomicExtension.IsCMField K hp
  ext1
  simp only [map_add, map_intCast, map_mul, coe_ringOfIntegersComplexConj, zpow_neg, map_units_inv,
    add_right_inj, mul_eq_mul_left_iff, Int.cast_eq_zero]
  simp_rw [NumberField.Units.coe_zpow]
  left
  simp only [map_zpow₀]
  rw [← inv_zpow]
  congr
  suffices hζ.unit' ∈ Units.torsion K by
    have H := RingOfIntegers.ext_iff.1 <|
        Units.ext_iff.1 <| unitsComplexConj_torsion K ⟨hζ.unit', ‹_›⟩
    have : ↑↑hζ.unit' = ζ := rfl
    simp only [Units.coe_mapEquiv, AlgEquiv.toRingEquiv_eq_coe, RingEquiv.coe_toMulEquiv,
      RingOfIntegers.mapRingEquiv_apply, this, AlgEquiv.coe_ringEquiv, InvMemClass.coe_inv,
      map_units_inv] at H
    have h : (algebraMap (𝓞 K) K) ↑hζ.unit' = ζ := rfl
    simp [h, H]
  refine (CommGroup.mem_torsion _ _).2 (isOfFinOrder_iff_pow_eq_one.2 ⟨p, by lia, ?_⟩)
  ext
  exact hζ.pow_eq_one

theorem exists_int_sum_eq_zero' (x y i : ℤ) {u : (𝓞 K)ˣ} {α : 𝓞 K}
    (h : (x : 𝓞 K) + y * (hζ.unit' ^ i : (𝓞 K)ˣ) = u * α ^ p) [Fact (p.Prime)] (hp : 2 < p) :
      ∃ k : ℕ, (x : 𝓞 K) + y * (hζ.unit' ^ i : (𝓞 K)ˣ) - ((hζ.unit' ^ k) ^ 2 : (𝓞 K)ˣ) *
    (x + y * (hζ.unit' ^ (-i) : (𝓞 K)ˣ)) ∈
    Ideal.span ({(p : 𝓞 K)} : Set (𝓞 K)) := by
  letI : NumberField K := IsCyclotomicExtension.numberField { p } ℚ _
  obtain ⟨k, H⟩ := unit_inv_conj_is_root_of_unity hζ u hp
  refine ⟨k, ?_⟩
  rw [← exists_int_sum_eq_zero'_aux _ _ _ _ hp, h, ← H, Units.val_mul, mul_assoc, ← mul_sub]
  convert Ideal.mul_mem_left _ ↑u (pow_sub_intGalConj_mem α hp) using 3
  ext
  simp

theorem exists_int_sum_eq_zero (x y i : ℤ) {u : (𝓞 K)ˣ} {α : 𝓞 K}
      (h : (x : 𝓞 K) + y * (hζ.unit' ^ i : (𝓞 K)ˣ) = u * α ^ p) [Fact (p.Prime)] (hp : 2 < p) :
    ∃ k : ℤ, (x : 𝓞 K) + y * (hζ.unit' ^ i : (𝓞 K)ˣ) - (hζ.unit' ^ (2 * k) : (𝓞 K)ˣ) *
    (x + y * (hζ.unit' ^ (-i) : (𝓞 K)ˣ)) ∈
    Ideal.span ({(p : 𝓞 K)} : Set (𝓞 K)) := by
  obtain ⟨k, hk⟩ := exists_int_sum_eq_zero' hζ x y i h hp
  use k
  convert hk
  rw [mul_comm, zpow_mul, zpow_ofNat, zpow_natCast]

end FltRegular.CaseI
