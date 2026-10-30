import Mathlib.Data.Nat.BitIndices
import Mathlib.Combinatorics.Colex

/-!
# Additional lemmas for natural number bit operations

This file contains general-purpose lemmas about `Nat.testBit`, `Nat.bitIndices`,
and sums of powers of 2 that are used throughout the formalization.

## Main results

* {given -show}`n : ℕ, i : ℕ` `Nat.testBit_iff_mem_bitIndices`: {lean}`n.testBit i = true ↔ i ∈ n.bitIndices`
* {given -show}`j` `Nat.testBit_finset_sum_pow_two`: For a finset {given}`s` of natural numbers,
  {lean}`(∑ i ∈ s, 2^i).testBit j ↔ j ∈ s`
* {given -show}`k` `Nat.testBit_sum_pow_two_fin`: Same for {lean}`Finset (Fin k)`

These lemmas connect the bit representation of natural numbers with finset membership,
which is fundamental for binary encoding arguments.
-/

namespace Nat

end Nat
