import Mathlib.Tactic
import Analysis.Misc.UnitsSystem

open UnitsSystem
variable [UnitsSystem]

/-! Many algebraic identities involving `Scalar` can be established by first using {syntax tactic}`simp [←toFormal_inj]`  to coerce to `Formal` and  push coercions inside, then appealing to {tactic}`ring`.  We give some examples below.

Alternatively, one can "work in coordinates" by using {syntax tactic}`simp [←val_inj]` in place of {syntax tactic}`simp [←toFormal_inj]`.
-/

/-- {given -show (type := "Dimensions")}`d₁, d₂, d₃` A `Scalar.cast` is needed here because
  {lean}`(d₁+d₂)+d₃` is not definitionally equal to {lean}`d₁+(d₂+d₃)`. -/
theorem UnitsSystem.Scalar.hMul_assoc {d₁ d₂ d₃:Dimensions} (a:Scalar d₁) (b:Scalar d₂) (c:Scalar d₃):
  a * (b * c) = ((a * b) * c).cast := by
  sorry

theorem UnitsSystem.Scalar.left_distrib {d₁ d₂:Dimensions} (a:Scalar d₁) (b c:Scalar d₂) :
  a * (b + c) = (a * b) + (a * c) := by
  sorry

theorem UnitsSystem.Scalar.right_distrib {d₁ d₂:Dimensions} (a b:Scalar d₁) (c:Scalar d₂) :
  (a + b) * c = (a * c) + (b * c) := by
  sorry

/-- A `Scalar.cast` is needed here because {lean}`2 • d` is not definitionally equal to {lean}`d+d`. -/
theorem UnitsSystem.Scalar.sq_add {d:Dimensions} (a b:Scalar d) : (a+b)**2 = a**2 + (2 • a * b).cast + b**2 := by
  sorry

/-- An alternate proof based on working in coordinates-/
theorem UnitsSystem.Scalar.sq_add' {d:Dimensions} (a b:Scalar d) : (a+b)**2 = a**2 + (2 • a * b).cast + b**2 := by
  sorry
