import Mathlib.Analysis.Calculus.AddTorsor.Coord
import Mathlib.Analysis.Matrix.Normed
import Mathlib.LinearAlgebra.AffineSpace.Matrix
import Mathlib.Tactic.Cases

noncomputable section

open Set Function

open scoped Affine Matrix ContDiff

section BarycentricDet

variable (ι R k P : Type*) {M : Type*} [Ring R] [AddCommGroup M] [Module R M] [AffineSpace M P]

/-- The set of affine bases for an affine space. -/
def affineBases : Set (ι → P) :=
  {v | AffineIndependent R v ∧ affineSpan R (range v) = ⊤}

/-- If `P` is an affine space over the ring `R`, `v : ι → P` is an affine basis (for some indexing
set `ι`) and `p : P` is a point, then `eval_barycentric_coords ι R P p v` are the barycentric
coordinates of `p` with respect to the affine basis `v`.

Actually for convenience `eval_barycentric_coords` is defined even when `v` is not an affine basis.
In this case its value should be regarded as "junk". -/
def evalBarycentricCoords [DecidablePred (· ∈ affineBases ι R P)] (p : P) (v : ι → P) : ι → R :=
  if h : v ∈ affineBases ι R P then ((AffineBasis.mk v h.1 h.2).coords p : ι → R) else 0

variable {ι R P}

end BarycentricDet

namespace Matrix

variable (ι k : Type*) [Fintype ι] [DecidableEq ι] [NontriviallyNormedField k]

attribute [instance] Matrix.normedAddCommGroup Matrix.normedSpace

end Matrix

section smooth_barycentric

variable (ι 𝕜 F : Type*)

variable [Fintype ι] [NontriviallyNormedField 𝕜] [CompleteSpace 𝕜]

variable [NormedAddCommGroup F] [NormedSpace 𝕜 F]

-- An alternative approach would be to prove the affine version of `contDiffAt_map_inverse`
-- and prove that barycentric coordinates give a continuous affine equivalence to
-- `{ f : ι →₀ 𝕜 | f.sum = 1 }`.
-- This should obviate the need for the finite-dimensionality assumption.

end smooth_barycentric
