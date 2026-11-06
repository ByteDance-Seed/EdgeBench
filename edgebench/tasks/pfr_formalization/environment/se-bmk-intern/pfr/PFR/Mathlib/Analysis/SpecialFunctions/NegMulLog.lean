module

public import Mathlib.Algebra.BigOperators.Field
public import Mathlib.Analysis.Convex.Jensen
public import Mathlib.Analysis.SpecialFunctions.Log.NegMulLog

/-!
# Entropy function

The purpose of this file is to record basic analytic properties of the function
$$h(x) = - x * \log x$$ on the unit interval, for use in the theory of Shannon entropy.

## Main results

* `sum_negMulLog_le`: a Jensen inequality for `negMulLog`
* `sum_negMulLog_eq`: the equality case of this inequality

-/

public section

open scoped ENNReal NNReal Topology

namespace Real
variable {ι : Type*} {s : Finset ι} {w : ι → ℝ} {p : ι → ℝ}

end Real
