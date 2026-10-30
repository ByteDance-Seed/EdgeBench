module

public import Mathlib.NumberTheory.NumberField.CMField
import Mathlib.NumberTheory.NumberField.Cyclotomic.Basic

@[expose] public section

variable {p : ℕ} [NeZero p] {K : Type*} [Field K]

variable {ζ : K} (hζ : IsPrimitiveRoot ζ p)

open scoped nonZeroDivisors NumberField

open IsCyclotomicExtension NumberField Polynomial IsCMField

noncomputable section

/-- zeta now as a unit in the ring of integers. This way there are no coe issues. -/
def IsPrimitiveRoot.unit' {p : ℕ} [NeZero p] {K : Type*} [Field K] {ζ : K}
    (hζ : IsPrimitiveRoot ζ p) : (𝓞 K)ˣ where
  val := (⟨ζ, hζ.isIntegral (NeZero.pos p)⟩ : 𝓞 K)
  inv := (⟨ζ⁻¹, hζ.inv.isIntegral (NeZero.pos p)⟩ : 𝓞 K)
  val_inv := Subtype.ext <| mul_inv_cancel₀ <| hζ.ne_zero (NeZero.ne p)
  inv_val := Subtype.ext <| inv_mul_cancel₀ <| hζ.ne_zero (NeZero.ne p)

set_option quotPrecheck false
local notation "I" => (Ideal.span ({(hζ.unit' - 1 : 𝓞 K)} : Set (𝓞 K)) : Ideal (𝓞 K))

theorem IsPrimitiveRoot.unit'_pow : hζ.unit' ^ p = 1 := by
  ext; simpa using hζ.pow_eq_one

theorem zeta_runity_pow_even (hpo : Odd p) (n : ℕ) :
    ∃ m : ℕ, hζ.unit' ^ n = hζ.unit' ^ (2 * m) := by
  rcases eq_or_ne n 0 with (rfl | _)
  · use 0
  obtain ⟨r, hr⟩ := hpo
  have he : 2 * (r + 1) * n = p * n + n := by rw [hr]; ring
  use (r + 1) * n
  rw [← mul_assoc, he, pow_add]
  convert (one_mul (M := (𝓞 K)ˣ) _).symm
  rw [pow_mul, hζ.unit'_pow, one_pow]

variable [NumberField K]

theorem IsPrimitiveRoot.unit'_coe : IsPrimitiveRoot hζ.unit'.1 p := by
  have z1 := hζ
  have : (algebraMap (𝓞 K) K) (hζ.unit' : 𝓞 K) = ζ := rfl
  rw [← this] at z1
  exact z1.of_map_of_injective (IsFractionRing.injective _ _)

theorem eq_one_mod_one_sub {A : Type*} [CommRing A] {t : A} :
    algebraMap A (A ⧸ Ideal.span ({t - 1} : Set A)) t = 1 :=
  by
  rw [← map_one <| algebraMap A <| A ⧸ Ideal.span ({t - 1} : Set A), ← sub_eq_zero, ← map_sub,
    Ideal.Quotient.algebraMap_eq, Ideal.Quotient.eq_zero_iff_mem]
  apply Ideal.subset_span
  exact Set.mem_singleton _

theorem IsPrimitiveRoot.eq_one_mod_sub_of_pow {A : Type*} [CommRing A] [IsDomain A] {ζ : A}
    (hζ : IsPrimitiveRoot ζ p) {μ : A} (hμ : μ ^ p = 1) :
    (@DFunLike.coe _ A (fun _ => A ⧸ Ideal.span {ζ - 1}) _
      (algebraMap A (A ⧸ Ideal.span {ζ - 1})) μ) = 1 := by
  obtain ⟨k, -, rfl⟩ := hζ.eq_pow_of_pow_eq_one hμ
  rw [map_pow, eq_one_mod_one_sub, one_pow]

theorem aux {t} {l : 𝓞 K} {f : Fin t → ℤ} {μ : K} (hμ : IsPrimitiveRoot μ p)
    (h : ∑ x : Fin t, f x • (⟨μ, hμ.isIntegral (NeZero.pos p)⟩ : 𝓞 K) ^ (x : ℕ) = l) :
    algebraMap (𝓞 K) (𝓞 K ⧸ I) l = ∑ x : Fin t, (f x : 𝓞 K ⧸ I) := by
  apply_fun algebraMap (𝓞 K) (𝓞 K ⧸ I) at h
  simp only [map_sum, map_zsmul] at h
  convert h.symm using 1
  congr
  funext x
  have : (⟨μ, hμ.isIntegral (NeZero.pos p)⟩ : 𝓞 K) ^ p = 1 := by
    ext
    push_cast
    exact hμ.pow_eq_one
  have := hζ.unit'_coe.eq_one_mod_sub_of_pow this
  simp only [map_pow (algebraMap (𝓞 K) (𝓞 K ⧸ I)), this, one_pow, zsmul_one]

theorem IsPrimitiveRoot.p_mem_one_sub_zeta [hp : Fact p.Prime] : (p : 𝓞 K) ∈ I := by
  classical
  have key : _ = (p : 𝓞 K) := @Polynomial.eval_one_cyclotomic_prime _ _ _ hp
  rw [cyclotomic_eq_prod_X_sub_primitiveRoots hζ.unit'_coe, eval_prod] at key
  simp only [eval_sub, eval_X, eval_C] at key
  have : {↑hζ.unit'} ⊆ primitiveRoots p (𝓞 K) := by simpa [NeZero.pos p] using hζ.unit'_coe
  rw [← Finset.prod_sdiff this, Finset.prod_singleton] at key
  rw [← key]
  have := (Ideal.neg_mem_iff I).mpr (Ideal.subset_span (Set.mem_singleton (hζ.unit' - 1 : 𝓞 K)))
  rw [neg_sub] at this
  exact Ideal.mul_mem_left _ _ this

variable [IsCyclotomicExtension {p} ℚ K]

theorem roots_of_unity_in_cyclo_aux {x : K} {l : ℕ} (hl : l ≠ 0) (hx : IsIntegral ℤ x)
    (hhl : (cyclotomic l (𝓞 K)).IsRoot ⟨x, hx⟩) {ζ : K} (hζ : IsPrimitiveRoot ζ p) : l ∣ 2 * p := by
  by_contra h
  have hpl' : IsPrimitiveRoot (⟨x, hx⟩ : 𝓞 K) l := by
    have nezero : NeZero (l : 𝓞 K) := by
      refine ⟨fun hzero ↦ ?_⟩
      simp only [Nat.cast_eq_zero, hl] at hzero
    rw [isRoot_cyclotomic_iff.symm]
    apply hhl
  have hpl : IsPrimitiveRoot x l := by
    have : (algebraMap (𝓞 K) K) ⟨x, hx⟩ = x := by rfl
    have h4 := IsPrimitiveRoot.map_of_injective hpl' (f := algebraMap (𝓞 K) K); rw [← this]
    apply h4
    apply IsFractionRing.injective
  have hirr : Irreducible (cyclotomic p ℚ) := cyclotomic.irreducible_rat (NeZero.pos p)
  have KEY := IsPrimitiveRoot.lcm_totient_le_finrank hpl hζ <|
    cyclotomic.irreducible_rat <| Nat.lcm_pos (Nat.zero_lt_of_ne_zero hl) (NeZero.pos p)
  have hrank := IsCyclotomicExtension.finrank K hirr
  rw [hrank] at KEY
  have pdivlcm : p ∣ lcm l p := dvd_lcm_right l p
  rcases pdivlcm with ⟨pdivlcm_w, pdivlcm_h⟩
  have ineq1 := Nat.totient_super_multiplicative p pdivlcm_w
  rw [← pdivlcm_h] at ineq1
  have KEY3 := (mul_le_iff_le_one_right (Nat.totient_pos.2 (NeZero.pos p))).mp (le_trans ineq1 KEY)
  have pdiv_ne_zero : 0 < pdivlcm_w := by
    by_contra h
    simp only [not_lt, le_zero_iff] at h
    rw [h] at pdivlcm_h
    simp only [MulZeroClass.mul_zero, lcm_eq_zero_iff] at pdivlcm_h
    aesop
  have K5 := (Nat.dvd_prime Nat.prime_two).1 (Nat.dvd_two_of_totient_le_one pdiv_ne_zero KEY3)
  rcases K5 with K5 | K5
  · rw [K5] at pdivlcm_h
    simp only [mul_one] at pdivlcm_h
    rw [lcm_eq_right_iff] at pdivlcm_h
    · have K6 : p ∣ 2 * p := dvd_mul_left p 2
      apply absurd (dvd_trans pdivlcm_h K6) h
    simp only [normalize_eq]
  · rw [K5] at pdivlcm_h
    rw [mul_comm] at pdivlcm_h
    have := dvd_lcm_left l p
    simp_rw [pdivlcm_h] at this
    apply absurd this h

theorem roots_of_unity_in_cyclo (hpo : Odd p) (x : K)
    (h : ∃ (n : ℕ) (_ : 0 < n), x ^ n = 1) :
    ∃ (m k : ℕ), x = (-1) ^ k * (hζ.unit'.1 : K) ^ m :=  by
  obtain ⟨n, hn0, hn⟩ := h
  have hx : IsIntegral ℤ x := by
    refine ⟨X ^ n - 1, ⟨?_, ?_⟩⟩
    · exact monic_X_pow_sub_C 1 (ne_of_lt hn0).symm
    · simp only [hn, eval₂_one, eval₂_X_pow, eval₂_sub, sub_self]
  have hxu : (⟨x, hx⟩ : 𝓞 K) ^ n = 1 := by ext; simp [hn]
  have H : ∃ (m k : ℕ), (⟨x, hx⟩ : 𝓞 K) = (-1) ^ k * (hζ.unit'.1 : K) ^ m := by
    obtain ⟨l, hl, hhl⟩ := (_root_.isRoot_of_unity_iff hn0 _).1 hxu
    replace hl : l ≠ 0 := fun H ↦ by simp [H] at hl
    have hlp := roots_of_unity_in_cyclo_aux hl hx hhl hζ
    have isPrimRoot : IsPrimitiveRoot (hζ.unit' : 𝓞 K) p := hζ.unit'_coe
    have hxl : (⟨x, hx⟩ : 𝓞 K) ^ l = 1 :=  by
      apply isRoot_of_unity_of_root_cyclotomic _ hhl
      simp only [Nat.mem_divisors, dvd_refl, Ne, true_and]
      apply pos_iff_ne_zero.1 (Nat.pos_of_ne_zero hl)
    have hxp' : (⟨x, hx⟩ : 𝓞 K) ^ (2 * p) = 1 := by
      rcases hlp with ⟨hlp_w, hlp_h⟩
      rw [hlp_h, pow_mul, hxl]; simp only [one_pow]
    have hxp'' : (⟨x, hx⟩ : 𝓞 K) ^ p = 1 ∨ (⟨x, hx⟩ : 𝓞 K) ^ p = -1 := by
      rw [mul_comm] at hxp'; rw [pow_mul] at hxp'
      suffices (⟨x, hx⟩ : 𝓞 K) ^ p = 1 ∨ (⟨x, hx⟩ : 𝓞 K) ^ p = -1 by
        · rcases this with h1 | h2
          · left; simp only [h1]
          · right; simp only [h2]
      apply eq_or_eq_neg_of_sq_eq_sq
      simp only [one_pow]
      apply hxp'
    rcases hxp'' with hxp'' | hxp''
    · obtain ⟨i, _, Hi⟩ := IsPrimitiveRoot.eq_pow_of_pow_eq_one isPrimRoot hxp''
      refine ⟨i, 2, ?_⟩
      rw [← Subtype.val_inj] at Hi
      simp only at Hi
      simp only [even_two, Even.neg_pow, one_pow, one_mul]
      rw [← Hi]
      rfl
    · have hone : (-1 : 𝓞 K) ^ p = (-1 : 𝓞 K) := by apply Odd.neg_one_pow hpo
      have hxp3 : (-1 * ⟨x, hx⟩ : 𝓞 K) ^ p = 1 := by
        rw [mul_pow, hone, hxp'']
        ring
      obtain ⟨i, _, Hi⟩ := IsPrimitiveRoot.eq_pow_of_pow_eq_one isPrimRoot hxp3
      refine ⟨i, 1, ?_⟩
      simp only [pow_one, neg_mul, one_mul]
      rw [← Subtype.val_inj] at Hi
      simp only [neg_mul, one_mul] at Hi
      exact Iff.mp neg_eq_iff_eq_neg (id (Eq.symm (by simpa using Hi)))
  obtain ⟨m, k, hmk⟩ := H
  refine ⟨m, k, ?_⟩
  have eq : ((⟨x, hx⟩ : 𝓞 K) : K) = x := rfl
  rw [← eq, hmk]

theorem IsPrimitiveRoot.isPrime_one_sub_zeta [hp : Fact p.Prime] :
    (I : Ideal (𝓞 K)).IsPrime := by
  rw [Ideal.span_singleton_prime]
  · exact hζ.zeta_sub_one_prime'
  apply_fun (fun x : 𝓞 K => (x : K))
  push_cast
  intro h
  refine hp.1.ne_one (hζ.unique ?_)
  simp only [one_right_iff]
  simp only [sub_eq_zero] at h
  exact h

theorem IsPrimitiveRoot.two_not_mem_one_sub_zeta [hp : Fact p.Prime] (h : 2 < p) :
    (2 : 𝓞 K) ∉ I := by
  have hpm := hζ.p_mem_one_sub_zeta
  obtain ⟨k, hk⟩ := hp.1.odd_of_ne_two h.ne'
  apply_fun (fun n : ℕ => (n : 𝓞 K)) at hk
  rw [Nat.cast_add, Nat.cast_mul, Nat.cast_two, Nat.cast_one, add_comm] at hk
  intro h2m
  have := Ideal.sub_mem I hpm (Ideal.mul_mem_right (↑k) I h2m)
  rw [sub_eq_of_eq_add hk] at this
  exact hζ.isPrime_one_sub_zeta.ne_top (Ideal.eq_top_of_isUnit_mem I this isUnit_one)

lemma neg_one_eq_one_iff_two_eq_zero {M : Type*} [AddGroupWithOne M] :
    (-1 : M) = 1 ↔ (2 : M) = 0 := by rw [neg_eq_iff_add_eq_zero, one_add_one_eq_two]

lemma Units.coe_map_inv' {M N F : Type*} [Monoid M] [Monoid N] [FunLike F M N]
    [MonoidHomClass F M N] (f : F) (m : Mˣ) :
    ↑((Units.map (f : M →* N) m)⁻¹) = f ↑(m⁻¹ : Mˣ) :=
  m.coe_map_inv (f : M →* N)

variable (K) in
theorem IsCyclotomicExtension.IsCMField (hp : 2 < p) :
    IsCMField K :=
  haveI := IsCyclotomicExtension.isAbelianGalois {p} ℚ K
  haveI := nrRealPlaces_eq_zero_iff.1 (Rat.nrRealPlaces_eq_zero K hp)
  ⟨⟩

lemma unit_inv_conj_not_neg_zeta_runity_aux (u : (𝓞 K)ˣ) [Fact (p.Prime)] (hp : 2 < p) :
    haveI := IsCyclotomicExtension.IsCMField K hp
    algebraMap (𝓞 K) (𝓞 K ⧸ I) (unitsMulComplexConjInv K u).1 = 1 := by
  haveI := IsCyclotomicExtension.IsCMField K hp
  have := Units.coe_map_inv' (N := 𝓞 K ⧸ I) (algebraMap (𝓞 K) (𝓞 K ⧸ I)) (unitsComplexConj K u)
  rw [unitsMulComplexConjInv_apply, Units.val_mul, map_mul, ← this, Units.mul_inv_eq_one,
    Units.coe_map , MonoidHom.coe_coe]
  haveI := Fact.mk hp
  have hu := hζ.integralPowerBasis.basis.sum_repr u
  let a := hζ.integralPowerBasis.basis.repr
  let φn := hζ.integralPowerBasis.dim
  simp_rw [PowerBasis.basis_eq_pow, IsPrimitiveRoot.integralPowerBasis_gen] at hu
  have hu' := congr_arg (ringOfIntegersComplexConj K) hu
  replace hu' : ∑ x : Fin φn, (a u) x • (ringOfIntegersComplexConj K)
      (⟨ζ, hζ.isIntegral (NeZero.pos p)⟩ ^ (x : ℕ)) = unitsComplexConj K u := by
    refine Eq.trans ?_ hu'
    rw [map_sum]
    congr 1
    ext x
    congr 1
    rw [map_zsmul]
  have : ∀ x : Fin φn, ringOfIntegersComplexConj K (⟨ζ, hζ.isIntegral (NeZero.pos p)⟩ ^ (x : ℕ)) =
      ⟨ζ⁻¹, hζ.inv.isIntegral (NeZero.pos p)⟩ ^ (x : ℕ) := by
    intro x
    ext
    simp only [map_pow, coe_ringOfIntegersComplexConj, RingOfIntegers.map_mk, inv_pow]
    suffices hζ.unit' ∈ Units.torsion K by
      have H := RingOfIntegers.ext_iff.1 <|
        Units.ext_iff.1 <| unitsComplexConj_torsion K ⟨hζ.unit', ‹_›⟩
      have : ↑↑hζ.unit' = ζ := rfl
      simp only [Units.coe_mapEquiv, AlgEquiv.toRingEquiv_eq_coe, RingEquiv.coe_toMulEquiv,
        RingOfIntegers.mapRingEquiv_apply, this, AlgEquiv.coe_ringEquiv, InvMemClass.coe_inv,
        map_units_inv] at H
      simp [H]
    refine (CommGroup.mem_torsion _ _).2 (isOfFinOrder_iff_pow_eq_one.2 ⟨p, by lia, ?_⟩)
    ext
    exact hζ.pow_eq_one
  conv_lhs at hu' =>
    congr
    congr
    ext a
    rw [this a]
  exact (aux hζ hζ hu).trans (aux hζ hζ.inv hu').symm

theorem unit_inv_conj_not_neg_zeta_runity (u : (𝓞 K)ˣ) (n : ℕ) [Fact (p.Prime)] (hp : 2 < p) :
    haveI := IsCyclotomicExtension.IsCMField K hp
    u * (unitsComplexConj K u)⁻¹ ≠ -hζ.unit' ^ n := by
  by_contra H
  have hμ : algebraMap (𝓞 K) (𝓞 K ⧸ I) ((IsPrimitiveRoot.unit' hζ : 𝓞 K) ^ n) = 1 := by
    apply hζ.unit'_coe.eq_one_mod_sub_of_pow
    rw [← pow_mul, mul_comm, pow_mul, hζ.unit'_coe.pow_eq_one, one_pow]
  have hμ' : algebraMap (𝓞 K) (𝓞 K ⧸ I) ((IsPrimitiveRoot.unit' hζ : 𝓞 K) ^ n) = -1 := by
    rw [← neg_eq_iff_eq_neg, ← map_neg, ← Units.val_pow_eq_pow_val, ← Units.val_neg, ← H]
    apply unit_inv_conj_not_neg_zeta_runity_aux hζ u hp
  haveI := Fact.mk hp
  apply hζ.two_not_mem_one_sub_zeta hp
  rw [← Ideal.Quotient.eq_zero_iff_mem, map_ofNat, ← neg_one_eq_one_iff_two_eq_zero, ← hμ', hμ]

theorem unit_inv_conj_is_root_of_unity (u : (𝓞 K)ˣ) [H : Fact (p.Prime)] (hp : 2 < p) :
    haveI := IsCyclotomicExtension.IsCMField K hp
    ∃ m : ℕ, u * (unitsComplexConj K u)⁻¹ = (hζ.unit' ^ m) ^ 2 := by
  haveI := IsCyclotomicExtension.IsCMField K hp
  have hpo : Odd p := H.out.odd_of_ne_two hp.ne'
  haveI : NormedAlgebra ℚ ℂ := normedAlgebraRat
  have :=
    @NumberField.Embeddings.pow_eq_one_of_norm_eq_one K _ _ ℂ _ _ _
      (u * (unitsComplexConj K u)⁻¹ : K) ?_ ?_
  · have H := roots_of_unity_in_cyclo hζ hpo (u * (unitsComplexConj K u)⁻¹ : K) this
    obtain ⟨n, k, hz⟩ := H
    simp_rw [← pow_mul]
    have hk := Nat.even_or_odd k
    rcases hk with hk | hk
    · simp only [hk.neg_one_pow, one_mul] at hz
      rw [← map_mul, ← Units.val_mul, ← map_pow, ← Units.val_pow_eq_pow_val] at hz
      norm_cast at hz
      rw [hz]
      refine (exists_congr fun a => ?_).mp (zeta_runity_pow_even hζ hpo n)
      · rw [mul_comm]
    · by_contra
      simp only [hk.neg_one_pow, neg_mul, one_mul] at hz
      rw [← map_mul, ← Units.val_mul, ← map_pow, ←  Units.val_pow_eq_pow_val, ← map_neg] at hz
      norm_cast at hz
      simpa [hz] using unit_inv_conj_not_neg_zeta_runity hζ u n hp
  · apply RingHom.IsIntegralElem.mul
    · exact NumberField.RingOfIntegers.isIntegral_coe _
    · exact NumberField.RingOfIntegers.isIntegral_coe _
  · simp

lemma IsPrimitiveRoot.eq_one_mod_one_sub' {A : Type*} [CommRing A] [IsDomain A]
    {n : ℕ} [NeZero n] {ζ : A} (hζ : IsPrimitiveRoot ζ n) {η : A} (hη : η ∈ nthRootsFinset n 1) :
    Ideal.Quotient.mk (Ideal.span ({ζ - 1} : Set A)) η = 1 := by
  obtain ⟨i, ⟨_, rfl⟩⟩ := hζ.eq_pow_of_pow_eq_one ((Polynomial.mem_nthRootsFinset
    (NeZero.pos n) 1).1 hη)
  rw [map_pow, ← Ideal.Quotient.algebraMap_eq, eq_one_mod_one_sub, one_pow]
