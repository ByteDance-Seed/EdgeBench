module

public import FltRegular.NumberTheory.Cyclotomic.UnitLemmas
public import Mathlib.RingTheory.ClassGroup
import FltRegular.NumberTheory.Cyclotomic.MoreLemmas
import FltRegular.NumberTheory.Hilbert92
import FltRegular.NumberTheory.Hilbert94
import FltRegular.NumberTheory.KummersLemma.Field
import Mathlib.FieldTheory.KummerExtension

@[expose] public section

open Polynomial
open scoped NumberField

variable {K : Type} {p : ℕ} [hpri : Fact p.Prime] [Field K] [NumberField K]
  [IsCyclotomicExtension {p} ℚ K] (hp : p ≠ 2) [Fintype (ClassGroup (𝓞 K))]
  (hreg : p.Coprime <| Fintype.card <| ClassGroup (𝓞 K))
  {ζ : K} (hζ : IsPrimitiveRoot ζ p)

include hp hreg

-- Let 𝑝 be a regular prime (i.e. an odd prime which does not divide the class number off
-- the 𝑝-th cyclotomic field) and 𝜉 a primitive 𝑝-th root of unity;
-- if a unit 𝑢∈𝐐(𝜉) is congruent to an integer modulo 𝑝, then 𝑢 is a 𝑝-th power in 𝐐(𝜉).
theorem eq_pow_prime_of_unit_of_congruent (u : (𝓞 K)ˣ)
    (hcong : ∃ n : ℤ, (p : 𝓞 K) ∣ (u - n : 𝓞 K)) :
    ∃ v, u = v ^ p := by
  sorry
