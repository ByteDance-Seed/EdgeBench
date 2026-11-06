module

public import Mathlib.Algebra.Module.Projective
public import Mathlib.LinearAlgebra.Basis.VectorSpace

public section

namespace Submodule
variable {B F R : Type*} [DivisionRing R] [AddCommGroup B] [AddCommGroup F]
  [Module R B] [Module R F]

open LinearMap

end Submodule
