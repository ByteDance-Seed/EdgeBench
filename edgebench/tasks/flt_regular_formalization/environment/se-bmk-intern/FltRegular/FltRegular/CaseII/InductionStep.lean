module

public import FltRegular.NumberTheory.Cyclotomic.UnitLemmas
public import Mathlib.Algebra.Lie.OfAssociative
public import Mathlib.RingTheory.ClassGroup
import FltRegular.CaseII.AuxLemmas
import FltRegular.NumberTheory.Cyclotomic.CyclRat
import FltRegular.NumberTheory.Cyclotomic.MoreLemmas
import FltRegular.NumberTheory.Hilbert92
import FltRegular.NumberTheory.KummersLemma.KummersLemma
import Mathlib.Order.CompletePartialOrder
import Mathlib.RingTheory.RootsOfUnity.CyclotomicUnits

@[expose] public section

open scoped nonZeroDivisors NumberField
open Polynomial

variable {K : Type} {p : ℕ} [NeZero p] [Field K] (hp : p ≠ 2)

variable {ζ : K} (hζ : IsPrimitiveRoot ζ p) {x y z : 𝓞 K} {ε : (𝓞 K)ˣ}

local notation3 "π" => Units.val (IsPrimitiveRoot.unit' hζ) - 1
local notation3 "𝔭" => Ideal.span {π}
local notation3 "𝔦" η => Ideal.span {(x + y * η : 𝓞 K)}
local notation3 "𝔵" => Ideal.span {x}
local notation3 "𝔶" => Ideal.span {y}
local notation3 "𝔷" => Ideal.span {z}

variable {m : ℕ} (e : x ^ p + y ^ p = ε * ((hζ.unit'.1 - 1) ^ (m + 1) * z) ^ p)
variable (hy : ¬ hζ.unit'.1 - 1 ∣ y) (hz : ¬ hζ.unit'.1 - 1 ∣ z)
variable (η : nthRootsFinset p (1 : 𝓞 K))

/- We have `x,y,z` elements of `O_K` and we assume that we have $$x^p+y^p= ε * ((ζ-1)^(m+1)*z)^p$$-/

include e in
/- Let π = ζ -1, then π divides x^p+y^p. -/
lemma zeta_sub_one_dvd : π ∣ x ^ p + y ^ p := by
  rw [e, mul_pow, ← pow_mul]
  apply dvd_mul_of_dvd_right
  apply dvd_mul_of_dvd_left
  apply dvd_pow_self
  simp [NeZero.ne]

include e in
/- x^p+y^p = 𝔭^((m+1)*p) * (z)^p, here 𝔷 = (z) (the ideal gen by z)-/
lemma span_pow_add_pow_eq :
    Ideal.span {x ^ p + y ^ p} = (𝔭 ^ (m + 1) * 𝔷) ^ p := by
  simp only [e, ← Ideal.span_singleton_pow, ← Ideal.span_singleton_mul_span_singleton]
  convert one_mul _
  rw [Ideal.one_eq_top, Ideal.span_singleton_eq_top]
  exact ε.isUnit

variable [NumberField K]

local notation3 "𝔪" => gcd 𝔵 𝔶

include hy in
lemma m_ne_zero : 𝔪 ≠ 0 := by
  simp_rw [Ne, gcd_eq_zero_iff, Ideal.zero_eq_bot, Ideal.span_singleton_eq_bot]
  rintro ⟨rfl, rfl⟩
  exact hy (dvd_zero _)

variable [hpri : Fact p.Prime]

lemma coprime_c_aux (η₁ η₂ : nthRootsFinset p (1 : 𝓞 K)) (hη : η₁ ≠ η₂) :
    (𝔦 η₁) ⊔ (𝔦 η₂) ∣ 𝔪 * 𝔭 := by
  have : 𝔭 = Ideal.span (singleton <| (η₁ : 𝓞 K) - η₂) := by
    rw [Ideal.span_singleton_eq_span_singleton]
    exact hζ.unit'_coe.ntRootsFinset_pairwise_associated_sub_one_sub_of_prime hpri.out η₁.prop
      η₂.prop (Subtype.coe_injective.ne hη)
  rw [(gcd_mul_right' 𝔭 𝔵 𝔶).symm.dvd_iff_dvd_right, dvd_gcd_iff]
  simp_rw [this, Ideal.span_singleton_mul_span_singleton, Ideal.dvd_span_singleton,
    Ideal.mem_span_singleton_sup, Ideal.mem_span_singleton]
  refine ⟨⟨-η₂, _, ⟨η₁, rfl⟩, ?_⟩, ⟨1, _, ⟨-1, rfl⟩, ?_⟩⟩
  · ring
  · ring

include hp hζ e hz in
lemma x_plus_y_mul_ne_zero : x + y * η ≠ 0 := by
  intro hη
  have : x + y * η ∣ x ^ p + y ^ p := by
    rw [hζ.unit'_coe.pow_add_pow_eq_prod_add_mul _ _ <| Nat.odd_iff.2 <|
      hpri.out.eq_two_or_odd.resolve_left hp]
    simp_rw [mul_comm _ y]
    exact Finset.dvd_prod_of_mem _ η.prop
  rw [hη, zero_dvd_iff, e] at this
  simp only [mul_eq_zero, Units.ne_zero, pow_eq_zero_iff (NeZero.ne p), false_or] at this
  rw [this.resolve_left (pow_ne_zero (m + 1) (hζ.unit'_coe.sub_one_ne_zero hpri.out.one_lt))] at hz
  exact hz (dvd_zero _)

variable [IsCyclotomicExtension {p} ℚ K]

include e hp in
/- Let π = ζ -1, then π divides x+yη with η a primivite root of unity. -/
lemma one_sub_zeta_dvd_zeta_pow_sub : π ∣ x + y * η := by
  letI : Fact (Nat.Prime p) := hpri
  letI := IsCyclotomicExtension.numberField {p} ℚ K
  have h := zeta_sub_one_dvd hζ e
  replace h : ∏ _η ∈ nthRootsFinset p (1 : 𝓞 K), Ideal.Quotient.mk 𝔭 (x + y * η : 𝓞 K) = 0 := by
    rw [hζ.unit'_coe.pow_add_pow_eq_prod_add_mul _ _ <| Nat.odd_iff.2 <|
      hpri.out.eq_two_or_odd.resolve_left hp, ← Ideal.Quotient.eq_zero_iff_dvd, map_prod] at h
    convert h using 2 with η' hη'
    rw [map_add, map_add, map_mul, map_mul, IsPrimitiveRoot.eq_one_mod_one_sub' hζ.unit'_coe hη',
      IsPrimitiveRoot.eq_one_mod_one_sub' hζ.unit'_coe η.prop, one_mul, mul_one]
  rw [Finset.prod_const, ← map_pow, Ideal.Quotient.eq_zero_iff_dvd] at h
  exact hζ.zeta_sub_one_prime'.dvd_of_dvd_pow h

include hp hζ e in
/- x+yη is divisible by ζ-1 in O_k -/
lemma div_one_sub_zeta_mem : IsIntegral ℤ ((x + y * η : 𝓞 K) / (ζ - 1)) := by
  obtain ⟨⟨a, ha⟩, e⟩ := one_sub_zeta_dvd_zeta_pow_sub hp hζ e η
  rw [e, mul_comm]
  simp only [map_mul, NumberField.RingOfIntegers.map_mk, map_sub,
    map_one, show hζ.unit'.1 = ζ from rfl]
  rwa [mul_div_cancel_right₀ _ (hζ.sub_one_ne_zero hpri.out.one_lt)]

/- Make (x+yη)/(ζ-1) into an element of O_K -/
def div_zeta_sub_one : nthRootsFinset p (1 : 𝓞 K) → 𝓞 K :=
fun η ↦ ⟨(x + y * η.1) / (ζ - 1), div_one_sub_zeta_mem hp hζ e η⟩

/-Check that if you multiply by π = ζ -1 you get back the original-/
lemma div_zeta_sub_one_mul_zeta_sub_one (η) :
    div_zeta_sub_one hp hζ e η * (π) = x + y * η := by
  ext
  simp [show hζ.unit'.1 = ζ from rfl,
    div_zeta_sub_one, div_mul_cancel₀ _ (hζ.sub_one_ne_zero hpri.out.one_lt)]

/- y is associated to (x+yη₁)/(ζ-1) - (x+yη₂)/(ζ-1) for η₁ ≠ η₂. -/
lemma div_zeta_sub_one_sub (η₁ η₂) (hη : η₁ ≠ η₂) :
    Associated y (div_zeta_sub_one hp hζ e η₁ - div_zeta_sub_one hp hζ e η₂) := by
  letI := IsCyclotomicExtension.numberField {p} ℚ K
  apply Associated.of_mul_right _ (Associated.refl (π))
    (hζ.unit'_coe.sub_one_ne_zero hpri.out.one_lt)
  convert_to Associated _ (y * (η₁ - η₂))
  · rw [sub_mul, div_zeta_sub_one_mul_zeta_sub_one, div_zeta_sub_one_mul_zeta_sub_one]
    ring
  apply Associated.mul_left
  apply hζ.unit'_coe.ntRootsFinset_pairwise_associated_sub_one_sub_of_prime hpri.out η₁.prop η₂.prop
  rw [Ne, ← Subtype.ext_iff.not]
  exact hη

include hy in
/- sending η to (x+yη)/(ζ-1) mod (π) = 𝔭 is injective. -/
lemma div_zeta_sub_one_Injective :
    Function.Injective (fun η ↦ Ideal.Quotient.mk 𝔭 (div_zeta_sub_one hp hζ e η)) := by
  letI : AddGroup (𝓞 K ⧸ 𝔭) := inferInstance
  intros η₁ η₂
  contrapose
  intro e₁ e₂
  apply hy
  obtain ⟨u, e⟩ := div_zeta_sub_one_sub hp hζ e η₁ η₂ e₁
  dsimp only at e₂
  rwa [← sub_eq_zero, ← map_sub, ← e, Ideal.Quotient.eq_zero_iff_dvd, u.isUnit.dvd_mul_right] at e₂

/- quot by ideal is finite since we are in a number field.-/
instance : Finite (𝓞 K ⧸ 𝔭) := by
  letI := IsCyclotomicExtension.numberField {p} ℚ K
  rw [← Ideal.absNorm_ne_zero_iff, Ne, Ideal.absNorm_eq_zero_iff, Ideal.span_singleton_eq_bot]
  exact hζ.unit'_coe.sub_one_ne_zero hpri.out.one_lt

include hy in
/- sending η to (x+yη)/(ζ-1) mod (π) = 𝔭 is bijective. -/
lemma div_zeta_sub_one_Bijective :
    Function.Bijective (fun η ↦ Ideal.Quotient.mk 𝔭 (div_zeta_sub_one hp hζ e η)) := by
  letI := Fintype.ofFinite (𝓞 K ⧸ 𝔭)
  letI := IsCyclotomicExtension.numberField {p} ℚ K
  rw [Fintype.bijective_iff_injective_and_card]
  use div_zeta_sub_one_Injective hp hζ e hy
  simp only [Fintype.card_coe]
  rw [hζ.unit'_coe.card_nthRootsFinset, ← Nat.card_eq_fintype_card, ← Submodule.cardQuot_apply,
    ← Ideal.absNorm_apply, Ideal.absNorm_span_singleton]
  simp [show Algebra.norm ℤ π = _ from hζ.norm_toInteger_sub_one_of_prime_ne_two' hp]

include hy in
/- the gcd of x y called 𝔪 is coprime to 𝔭-/
lemma gcd_zeta_sub_one_eq_one : gcd 𝔪 𝔭 = 1 := by
  rw [gcd_assoc]
  convert gcd_one_right 𝔵 using 2
  rwa [gcd_comm, Irreducible.gcd_eq_one_iff, Ideal.dvd_span_singleton, Ideal.mem_span_singleton]
  · rw [irreducible_iff_prime]
    exact hζ.prime_span_sub_one

include hy in
/- the ideal (x+yη)/(ζ -1) is divisible by 𝔪 -/
lemma gcd_div_div_zeta_sub_one (η) : 𝔪 ∣ Ideal.span {div_zeta_sub_one hp hζ e η} := by
  rw [← mul_one (Ideal.span {div_zeta_sub_one hp hζ e η}),
    ← gcd_zeta_sub_one_eq_one hζ hy (x := x) (y := y)]
  apply dvd_mul_gcd_of_dvd_mul
  rw [Ideal.span_singleton_mul_span_singleton, div_zeta_sub_one_mul_zeta_sub_one,
  Ideal.dvd_span_singleton, Ideal.gcd_eq_sup]
  refine add_mem
    (Ideal.mem_sup_left (Ideal.subset_span (s := {x}) rfl))
    (Ideal.mem_sup_right (Ideal.mul_mem_right _ _ (Ideal.subset_span (s := {y}) rfl)))

/- Give a name to ((x+yη)/(ζ -1))/𝔪, call it 𝔠 η -/
noncomputable
def div_zeta_sub_one_dvd_gcd : Ideal (𝓞 K) :=
(gcd_div_div_zeta_sub_one hp hζ e hy η).choose

local notation "𝔠" => fun η ↦ div_zeta_sub_one_dvd_gcd hp hζ e hy η

lemma div_zeta_sub_one_dvd_gcd_spec :
    𝔪 * 𝔠 η = (Ideal.span <| singleton <| div_zeta_sub_one hp hζ e η) :=
(gcd_div_div_zeta_sub_one hp hζ e hy η).choose_spec.symm

lemma m_mul_c_mul_p : 𝔪 * 𝔠 η * 𝔭 = 𝔦 η := by
  rw [div_zeta_sub_one_dvd_gcd_spec, Ideal.span_singleton_mul_span_singleton,
    div_zeta_sub_one_mul_zeta_sub_one]

lemma p_ne_zero : 𝔭 ≠ 0 := by
  letI := IsCyclotomicExtension.numberField {p} ℚ K
  rw [Ne, Ideal.zero_eq_bot, Ideal.span_singleton_eq_bot]
  exact hζ.unit'_coe.sub_one_ne_zero hpri.out.one_lt

lemma coprime_c (η₁ η₂ : nthRootsFinset p (1 : 𝓞 K)) (hη : η₁ ≠ η₂) : IsCoprime (𝔠 η₁) (𝔠 η₂) := by
  rw [Ideal.isCoprime_iff_codisjoint, codisjoint_iff_le_sup, ← Ideal.dvd_iff_le]
  rw [← mul_dvd_mul_iff_left (m_ne_zero hζ hy), ← mul_dvd_mul_iff_right (p_ne_zero hζ)]
  rw [Ideal.mul_sup, Ideal.sup_mul, m_mul_c_mul_p, m_mul_c_mul_p, Ideal.mul_top]
  exact coprime_c_aux hζ η₁ η₂ hη

include hy in
lemma gcd_m_p_pow_eq_one : gcd 𝔪 (𝔭 ^ (m + 1)) = 1 := by
  rw [← Ideal.isCoprime_iff_gcd, IsCoprime.pow_right_iff, Ideal.isCoprime_iff_gcd,
    gcd_zeta_sub_one_eq_one hζ hy]
  simp only [add_pos_iff, or_true, one_pos]

section port

theorem UniqueFactorizationMonoid.dvd_iff_emultiplicity_le {R : Type*}
    [CommMonoidWithZero R] [UniqueFactorizationMonoid R] {a b : R} (ha : a ≠ 0) :
    a ∣ b ↔ ∀ (p : R), Prime p → emultiplicity p a ≤ emultiplicity p b := by
  classical
  refine ⟨fun h _ _ ↦ emultiplicity_le_emultiplicity_of_dvd_right h, fun h ↦ ?_⟩
  by_cases hb : b = 0
  · simp_all
  letI : NormalizationMonoid R := UniqueFactorizationMonoid.normalizationMonoid
  rw [dvd_iff_normalizedFactors_le_normalizedFactors ha hb, Multiset.le_iff_count]
  intro q
  by_cases hq : q ∈ normalizedFactors a
  · have hqprime : Prime q := prime_of_normalized_factor q hq
    have h1 := emultiplicity_eq_count_normalizedFactors hqprime.irreducible ha
    have h2 := emultiplicity_eq_count_normalizedFactors hqprime.irreducible hb
    rw [normalize_normalized_factor q hq] at h1 h2
    simpa [h1, h2] using h q hqprime
  · simp [Multiset.count_eq_zero_of_notMem hq]

theorem UniqueFactorizationMonoid.pow_dvd_pow_iff_dvd {R : Type*}
    [CommMonoidWithZero R] [UniqueFactorizationMonoid R] {a b : R}
    {n : ℕ} (hn : n ≠ 0) :
    a ^ n ∣ b ^ n ↔ a ∣ b := by
  by_cases ha : a = 0
  · simp [ha, hn]
  refine ⟨?_, fun h ↦ pow_dvd_pow_of_dvd h n⟩
  rw [dvd_iff_emultiplicity_le (pow_ne_zero n ha), dvd_iff_emultiplicity_le ha]
  intro H p hp
  have := H p hp
  rwa [emultiplicity_pow hp, emultiplicity_pow hp,
    ENat.mul_le_mul_left_iff (by exact_mod_cast hn) (ENat.coe_ne_top _)] at this

theorem Prime.dvd_finsetProd_iff {M₀ M : Type*} [CommMonoidWithZero M]
    {S : Finset M₀} {p : M} (pp : Prime p) (g : M₀ → M) :
    p ∣ S.prod g ↔ ∃ a ∈ S, p ∣ g a :=
  ⟨pp.exists_mem_finset_dvd, fun ⟨_, ha1, ha2⟩ => dvd_trans ha2 (Finset.dvd_prod_of_mem g ha1)⟩

theorem Finset.prod_eq_mul_prod_diff_singleton_of_mem {ι M : Type*} [CommMonoid M]
    [DecidableEq ι] {s : Finset ι} {i : ι} (h : i ∈ s) (f : ι → M) :
    ∏ x ∈ s, f x = f i * ∏ x ∈ s \ {i}, f x :=
  prod_eq_mul_prod_diff_singleton (by simp_all) _

end port

include hζ m hy e in
lemma m_dvd_z : 𝔪 ∣ 𝔷 := by
  rw [← one_mul 𝔷, ← gcd_m_p_pow_eq_one hζ hy (x := x) (m := m)]
  apply dvd_gcd_mul_of_dvd_mul
  rw [← UniqueFactorizationMonoid.pow_dvd_pow_iff_dvd hpri.out.ne_zero, ← span_pow_add_pow_eq hζ e,
    Ideal.dvd_span_singleton]
  apply add_mem
  · exact Ideal.pow_mem_pow (Ideal.mem_sup_left (Ideal.mem_span_singleton_self x)) p
  · exact Ideal.pow_mem_pow (Ideal.mem_sup_right (Ideal.mem_span_singleton_self y)) p

noncomputable
def z_div_m : Ideal (𝓞 K) :=
(m_dvd_z hζ e hy).choose

local notation "𝔷'" => z_div_m hζ e hy

lemma z_div_m_spec : 𝔷 = 𝔪 * 𝔷' :=
  (m_dvd_z hζ e hy).choose_spec

lemma exists_ideal_pow_eq_c_aux :
    𝔪 ^ p * (𝔷' * 𝔭 ^ m) ^ p * 𝔭 ^ p = (𝔭 ^ (m + 1) * 𝔷) ^ p := by
  rw [mul_comm _ 𝔷, mul_pow, z_div_m_spec hζ e hy, mul_pow, mul_pow, ← pow_mul, ← pow_mul,
    add_mul, one_mul, pow_add, mul_assoc, mul_assoc, mul_assoc]

/- The ∏_η,  𝔠 η = (𝔷' 𝔭^m)^p with 𝔷 = 𝔪 𝔷' -/
lemma prod_c : ∏ η ∈ Finset.attach (nthRootsFinset p (1 : 𝓞 K)), 𝔠 η = (𝔷' * 𝔭 ^ m) ^ p := by
  have e' := span_pow_add_pow_eq hζ e
  rw [hζ.unit'_coe.pow_add_pow_eq_prod_add_mul _ _ <| Nat.odd_iff.2 <|
    hpri.out.eq_two_or_odd.resolve_left hp] at e'
  rw [← Ideal.prod_span_singleton, ← Finset.prod_attach] at e'
  simp_rw [mul_comm _ y, ← m_mul_c_mul_p hp hζ e hy,
    Finset.prod_mul_distrib, Finset.prod_const, Finset.card_attach,
    hζ.unit'_coe.card_nthRootsFinset] at e'
  rw [← mul_right_inj'
    ((pow_ne_zero_iff hpri.out.ne_zero).mpr (m_ne_zero hζ hy) : _),
    ← mul_left_inj' ((pow_ne_zero_iff hpri.out.ne_zero).mpr (p_ne_zero hζ) : _), e',
    exists_ideal_pow_eq_c_aux]

/-each 𝔠 η is a pth power, which will be denoted by 𝔞 η below. -/
lemma exists_ideal_pow_eq_c : ∃ I : Ideal (𝓞 K), (𝔠 η) = I ^ p :=
  Finset.exists_eq_pow_of_mul_eq_pow_of_coprime
    (fun η₁ _ η₂ _ hη ↦ coprime_c hp hζ e hy η₁ η₂ hη)
    (prod_c hp hζ e hy) η (Finset.mem_attach _ _)

noncomputable
def root_div_zeta_sub_one_dvd_gcd : Ideal (𝓞 K) :=
  (exists_ideal_pow_eq_c hp hζ e hy η).choose

local notation "𝔞" => root_div_zeta_sub_one_dvd_gcd hp hζ e hy

lemma root_div_zeta_sub_one_dvd_gcd_spec : (𝔞 η) ^ p = 𝔠 η :=
(exists_ideal_pow_eq_c hp hζ e hy η).choose_spec.symm

/-x+yη₁ / (x+yη₂) = 𝔠 η₁/ 𝔠 η₂ -/
lemma c_div_principal_aux (η₁ η₂ : nthRootsFinset p (1 : 𝓞 K)) :
    ((𝔦 η₁) / (𝔦 η₂) : FractionalIdeal (𝓞 K)⁰ K) = 𝔠 η₁ / 𝔠 η₂ := by
  simp_rw [← m_mul_c_mul_p hp hζ e hy, FractionalIdeal.coeIdeal_mul]
  rw [mul_div_mul_right, mul_div_mul_left]
  · rw [← FractionalIdeal.coeIdeal_bot, (FractionalIdeal.coeIdeal_injective' le_rfl).ne_iff]
    exact m_ne_zero hζ hy
  · rw [← FractionalIdeal.coeIdeal_bot, (FractionalIdeal.coeIdeal_injective' le_rfl).ne_iff]
    exact p_ne_zero hζ

lemma c_div_principal (η₁ η₂ : nthRootsFinset p (1 : 𝓞 K)) :
    Submodule.IsPrincipal ((𝔠 η₁ / 𝔠 η₂ : FractionalIdeal (𝓞 K)⁰ K) : Submodule (𝓞 K) K) := by
  rw [← c_div_principal_aux, FractionalIdeal.coeIdeal_span_singleton,
    FractionalIdeal.coeIdeal_span_singleton, FractionalIdeal.spanSingleton_div_spanSingleton,
    FractionalIdeal.coe_spanSingleton]
  exact ⟨⟨_, rfl⟩⟩

noncomputable
def zeta_sub_one_dvd_root : nthRootsFinset p (1 : 𝓞 K) :=
(Equiv.ofBijective _ (div_zeta_sub_one_Bijective hp hζ e hy)).symm 0

/- This is the η₀ such that (x+yη₀)/(ζ-1) is zero mod 𝔭. which is unique-/
local notation "η₀" => zeta_sub_one_dvd_root hp hζ e hy

lemma zeta_sub_one_dvd_root_spec : Ideal.Quotient.mk 𝔭 (div_zeta_sub_one hp hζ e η₀) = 0 :=
Equiv.ofBijective_apply_symm_apply _ (div_zeta_sub_one_Bijective hp hζ e hy) 0

lemma p_dvd_c_iff : 𝔭 ∣ (𝔠 η) ↔ η = η₀ := by
  rw [← (div_zeta_sub_one_Injective hp hζ e hy).eq_iff, zeta_sub_one_dvd_root_spec,
    Ideal.Quotient.eq_zero_iff_dvd, ← Ideal.mem_span_singleton (α := 𝓞 K),
    ← Ideal.dvd_span_singleton, ← div_zeta_sub_one_dvd_gcd_spec (hy := hy),
    ← dvd_gcd_mul_iff_dvd_mul, gcd_comm, gcd_zeta_sub_one_eq_one hζ hy, one_mul]

/- All the others 𝔠 η are coprime to 𝔭...basically-/
lemma p_pow_dvd_c_eta_zero_aux [DecidableEq (𝓞 K)] :
  gcd (𝔭 ^ (m * p)) (∏ η ∈ Finset.attach (nthRootsFinset p (1 : 𝓞 K)) \ {η₀}, 𝔠 η) = 1 := by
    rw [← Ideal.isCoprime_iff_gcd]
    apply IsCoprime.pow_left
    rw [Ideal.isCoprime_iff_gcd, hζ.prime_span_sub_one.irreducible.gcd_eq_one_iff,
      hζ.prime_span_sub_one.dvd_finsetProd_iff]
    rintro ⟨η, hη, h⟩
    rw [p_dvd_c_iff] at h
    simp only [Finset.mem_sdiff, Finset.mem_singleton] at hη
    exact hη.2 h

lemma p_dvd_a_iff : 𝔭 ∣ 𝔞 η ↔ η = η₀ := by
  rw [← p_dvd_c_iff hp hζ e hy, ← root_div_zeta_sub_one_dvd_gcd_spec,
    hζ.prime_span_sub_one.dvd_pow_iff_dvd hpri.out.ne_zero]

/- all the powers of 𝔭 have to be in 𝔠 η₀-/
lemma p_pow_dvd_c_eta_zero : 𝔭 ^ (m * p) ∣ 𝔠 η₀ := by
  classical
  rw [← one_mul (𝔠 η₀), ← p_pow_dvd_c_eta_zero_aux hp hζ e hy, dvd_gcd_mul_iff_dvd_mul,
    mul_comm _ (𝔠 η₀)]
  rw [← Finset.prod_eq_mul_prod_diff_singleton_of_mem (Finset.mem_attach _ η₀) 𝔠,prod_c, mul_pow]
  apply dvd_mul_of_dvd_right
  rw [pow_mul]

/- since the is only one 𝔞 η which is divisble by 𝔭 it has to be the η₀ one and it has to divide
to 𝔭^m power.-/
lemma p_pow_dvd_a_eta_zero : 𝔭 ^ m ∣ 𝔞 η₀ := by
  rw [← UniqueFactorizationMonoid.pow_dvd_pow_iff_dvd hpri.out.ne_zero,
    root_div_zeta_sub_one_dvd_gcd_spec, ← pow_mul]
  exact p_pow_dvd_c_eta_zero hp hζ e hy

noncomputable
def a_eta_zero_dvd_p_pow : Ideal (𝓞 K) :=
  (p_pow_dvd_a_eta_zero hp hζ e hy).choose

/-𝔞₀ is the coprime to 𝔭 bit of 𝔞 η₀-/
local notation "𝔞₀" => a_eta_zero_dvd_p_pow hp hζ e hy

lemma a_eta_zero_dvd_p_pow_spec : 𝔭 ^ m * 𝔞₀ = 𝔞 η₀ :=
  (p_pow_dvd_a_eta_zero hp hζ e hy).choose_spec.symm

include hz in
lemma not_p_div_a_zero : ¬ 𝔭 ∣ 𝔞₀ := by
  intro h
  have := pow_dvd_pow_of_dvd (mul_dvd_mul (dvd_refl (𝔭 ^ m)) h) p
  rw [a_eta_zero_dvd_p_pow_spec, root_div_zeta_sub_one_dvd_gcd_spec] at this
  have := this.trans (Finset.dvd_prod_of_mem 𝔠 (Finset.mem_attach _ η₀))
  rw [prod_c, mul_pow, mul_pow, mul_comm, mul_dvd_mul_iff_right,
    UniqueFactorizationMonoid.pow_dvd_pow_iff_dvd hpri.out.ne_zero] at this
  · apply hz
    rw [← Ideal.mem_span_singleton, ← Ideal.dvd_span_singleton, z_div_m_spec hζ e hy]
    exact this.trans (dvd_mul_left _ _)
  · apply mt eq_zero_of_pow_eq_zero
    apply mt eq_zero_of_pow_eq_zero
    rw [Ideal.zero_eq_bot, Ideal.span_singleton_eq_bot]
    exact hζ.unit'_coe.sub_one_ne_zero hpri.out.one_lt

include hp hζ e hy hz in
lemma one_le_m : 1 ≤ m := by
  have ha := not_p_div_a_zero hp hζ e hy hz
  rw [← hζ.prime_span_sub_one.irreducible.gcd_eq_one_iff] at ha
  have := (p_dvd_a_iff hp hζ e hy η₀).mpr rfl
  rw [← a_eta_zero_dvd_p_pow_spec, mul_comm, ← dvd_gcd_mul_iff_dvd_mul, ha, one_mul] at this
  nth_rw 1 [← pow_one 𝔭] at this
  rwa [← pow_dvd_pow_iff (p_ne_zero hζ) hζ.prime_span_sub_one.not_unit]

include hp in
lemma exists_solution'_aux {ε₁ ε₂ : (𝓞 K)ˣ} (hx : ¬ π ∣ x)
    (h : (p : 𝓞 K) ∣ ε₁ * x ^ p + ε₂ * y ^ p) :
    ∃ a : 𝓞 K, ↑p ∣ ↑(ε₁ / ε₂) - a ^ p := by
  obtain ⟨a, b, e⟩ : IsCoprime ↑p x := isCoprime_of_not_zeta_sub_one_dvd hζ hx
  have : (p : 𝓞 K) ∣ b * x - 1 := by use -a; rw [← e]; ring
  have := (this.trans (sub_one_dvd_pow_sub_one _ p)).trans (dvd_mul_left _ ↑(ε₁ / ε₂))
  use - y * b
  replace h := (h.trans (dvd_mul_right _ (b ^ p))).trans (dvd_mul_left _ ↑(ε₂⁻¹))
  rw [add_mul, mul_assoc, mul_assoc, ← mul_pow, ← mul_pow, mul_add] at h
  simp_rw [← mul_assoc, ← Units.val_mul] at h
  rw [← mul_comm ε₁, ← div_eq_mul_inv, inv_mul_cancel, Units.val_one, one_mul] at h
  convert dvd_sub h this using 1
  rw [neg_mul, (Nat.Prime.odd_of_ne_two hpri.out hp).neg_pow, sub_neg_eq_add, mul_sub, mul_one,
    mul_comm x b, add_sub_sub_cancel, add_comm]

variable [Fintype (ClassGroup (𝓞 K))] (hreg : p.Coprime <| Fintype.card <| ClassGroup (𝓞 K))

include hreg in
lemma a_div_principal (η₁ η₂ : nthRootsFinset p (1 : 𝓞 K)) :
    Submodule.IsPrincipal ((𝔞 η₁ / 𝔞 η₂ : FractionalIdeal (𝓞 K)⁰ K) : Submodule (𝓞 K) K) := by
  apply isPrincipal_of_isPrincipal_pow_of_Coprime' _ hreg
  /- the line above is where we use the p is regular.-/
  rw [div_pow, ← FractionalIdeal.coeIdeal_pow, ← FractionalIdeal.coeIdeal_pow,
    root_div_zeta_sub_one_dvd_gcd_spec, root_div_zeta_sub_one_dvd_gcd_spec]
  exact c_div_principal hp hζ e hy η₁ η₂

include hreg in
lemma isPrincipal_a_div_a_zero :
    Submodule.IsPrincipal ((𝔞 η / 𝔞₀ : FractionalIdeal (𝓞 K)⁰ K) : Submodule (𝓞 K) K) := by
  have := a_div_principal hp hζ e hy hreg η η₀
  rw [← a_eta_zero_dvd_p_pow_spec, mul_comm, FractionalIdeal.coeIdeal_mul, ← div_div,
   FractionalIdeal.isPrincipal_iff] at this
  obtain ⟨a, ha⟩ := this
  rw [div_eq_iff, Ideal.span_singleton_pow, FractionalIdeal.coeIdeal_span_singleton,
    FractionalIdeal.spanSingleton_mul_spanSingleton] at ha
  · rw [FractionalIdeal.isPrincipal_iff]
    exact ⟨_, ha⟩
  · rw [← FractionalIdeal.coeIdeal_bot,
      (FractionalIdeal.coeIdeal_injective' (le_rfl : (𝓞 K)⁰ ≤ (𝓞 K)⁰)).ne_iff]
    apply mt eq_zero_of_pow_eq_zero
    rw [Ideal.zero_eq_bot, Ideal.span_singleton_eq_bot]
    exact hζ.unit'_coe.sub_one_ne_zero hpri.out.one_lt

include hz hreg in
lemma exists_not_dvd_spanSingleton_eq_a_div_a_zero (hη : η ≠ η₀) :
    ∃ a b : 𝓞 K, ¬ π ∣ a ∧ ¬ π ∣ b ∧
      FractionalIdeal.spanSingleton (𝓞 K)⁰ (a / b : K) = 𝔞 η / 𝔞₀ := by
  sorry


include hreg e hy hz hp in
lemma exists_solution :
    ∃ (x' y' z' : 𝓞 K) (ε₁ ε₂ ε₃ : (𝓞 K)ˣ), ¬ π ∣ x' ∧ ¬ π ∣ y' ∧ ¬ π ∣ z' ∧
      ε₁ * x' ^ p + ε₂ * y' ^ p = ε₃ * (π ^ m * z') ^ p := by
  sorry
