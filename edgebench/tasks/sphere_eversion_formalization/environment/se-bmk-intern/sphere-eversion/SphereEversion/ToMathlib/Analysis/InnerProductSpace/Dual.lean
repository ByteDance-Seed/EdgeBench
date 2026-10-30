import Mathlib.Analysis.InnerProductSpace.Dual
import SphereEversion.ToMathlib.Analysis.InnerProductSpace.Projection.Submodule

open scoped RealInnerProductSpace

open Submodule InnerProductSpace

open LinearMap (ker)

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [CompleteSpace E]

@[inherit_doc] local notation "Δ" => spanLine

@[inherit_doc] local notation "{." x "}ᗮ" => spanOrthogonal x

@[inherit_doc] local notation "pr[" x "]ᗮ" => projSpanOrthogonal x

