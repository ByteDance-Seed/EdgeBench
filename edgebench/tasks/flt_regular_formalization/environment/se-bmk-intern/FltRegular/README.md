# Fermat's Last Theorem for regular primes
The goal of this project is to prove Fermat's Last Theorem for [regular primes](https://en.wikipedia.org/wiki/Regular_prime)
in [Lean](https://leanprover-community.github.io/).

Requirement: After completing all problems, the entire project must be sorry-free.
Any auxiliary lemmas you add must not contain full proofs and must not leave sorry.

## FLT elementary part (easy, 5 points)
### Some elementary simplification steps.

Complete the proofs of the three theorems in FltRegular / MayAssume / Lemmas.lean.
(the three theorems coprime, p_dvd_c_of_ab_of_anegc, and a_not_cong_b)

Complete the proofs of may_assume and ab_coprime in FltRegular / CaseI / Statement.lean.

## FLT case I (very hard, 30 points)
### Provide a complete proof of Fermat's Last Theorem case I.

Complete the proofs of
is_principal, ex_fin_div, caseI_easier, and caseI in FltRegular / CaseI / Statement.lean.
This part requires substantial work and may need additional auxiliary lemmas.

## Kummer's Lemma (hard, 20 points)
### Provide a proof of Kummer's lemma.

Complete the proof of the Hilbert92 theorem in FltRegular / NumberTheory / Hilbert92.lean.

Complete the proofs of the two Hilbert94 theorems in FltRegular / NumberTheory / Hilbert94.lean
(exists_not_isPrincipal_and_isPrincipal_map and
  dvd_card_classGroup_of_isUnramified_isCyclic）

Complete the proof of
eq_pow_prime_of_unit_of_congruent in FltRegular / NumberTheory / KummersLemma.lean.

## FLT case II (very hard, 30 points)
### Provide a complete proof of Fermat's Last Theorem case II, thereby completing the entire regular primes case.

Complete the proofs of
exists_not_dvd_spanSingleton_eq_a_div_a_zero and exists_solution in FltRegular / CaseII / InductionStep.lean.

Complete the proofs of
not_exists_Int_solution and caseII in FltRegular / CaseII / Statement.lean.

Complete the proof of the main theorem flt_regular in FltRegular / FltRegular.lean.

## p = 7 case (medium, 15 points)
### Using FLT for regular primes, prove that x^7 + y^7 = z^7 has no integer solutions.

Complete the proof of pid6 in FltRegular / SmallNumbers / Cyclotomic.lean.

Complete the proofs of M7 and Rat.seven_pid in FltRegular / SmallNumbers / Seven / Seven.lean.

Complete the proofs of
isRegularPrime_seven and fermatLastTheoremSeven in FltRegular / SmallNumbers / Seven / FLT7.lean.
