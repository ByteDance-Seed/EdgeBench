import Mathlib.Topology.Algebra.Order.Floor
import SphereEversion.ToMathlib.Topology.Misc

noncomputable section

open Set Function FiniteDimensional Prod Int

open scoped Topology unitInterval

/-- Equivariant maps from `ℝ` to itself are functions `f : ℝ → ℝ` with `f (t + 1) = f t + 1`. -/
structure EquivariantMap where
  toFun : ℝ → ℝ
  eqv' : ∀ t, toFun (t + 1) = toFun t + 1

namespace EquivariantMap

variable (φ : EquivariantMap)

instance : CoeFun EquivariantMap fun _ => ℝ → ℝ :=
  ⟨EquivariantMap.toFun⟩

theorem eqv : ∀ t, φ (t + 1) = φ t + 1 := by
  sorry

theorem coe_mk (f : ℝ → ℝ) {eqv} : ((⟨f, eqv⟩ : EquivariantMap) : ℝ → ℝ) = f := by
  sorry

end EquivariantMap

/-- continuous equivariant reparametrization that is locally constant around `0`.
  It is piecewise linear, connecting `(0, 0)`, `(1/4, 0)` and `(3/4, 1)` and `(1, 1)`,
  and extended to an equivariant function. -/
def linearReparam : EquivariantMap :=
  ⟨fun t => t + 4⁻¹ - abs (fract (t - 4⁻¹) - 2⁻¹), fun t => by
    simp only [← sub_add_eq_add_sub t, fract_add_one]; ring⟩

set_option linter.style.multiGoal false in

/-- A bijection from `ℝ` to itself that fixes `0` and is equivariant with respect to the `ℤ`
action by translations.

Morally, these are bijections of the circle `ℝ / ℤ` to itself. -/
structure EquivariantEquiv extends ℝ ≃ ℝ where
  map_zero' : toFun 0 = 0
  eqv' : ∀ t, toFun (t + 1) = toFun t + 1

namespace EquivariantEquiv

variable (φ : EquivariantEquiv)

instance : CoeFun EquivariantEquiv fun _ => ℝ → ℝ :=
  ⟨fun f => f.toFun⟩

instance hasCoeToEquiv : Coe EquivariantEquiv (ℝ ≃ ℝ) :=
  ⟨toEquiv⟩

/-- Forgetting its bijective properties, an `equivariant_equiv` can be regarded as an
`equivariant_map`. -/
@[simps]
protected def equivariantMap : EquivariantMap :=
  { φ with toFun := φ }

theorem eqv : ∀ t, φ (t + 1) = φ t + 1 := by
  sorry

@[simp]
theorem map_zero : φ 0 = 0 := by
  sorry

@[simp]
theorem map_zero'' : (⇑(φ : ℝ ≃ ℝ) : ℝ → ℝ) 0 = 0 := by
  sorry

instance {α : Type*} : HasUncurry (α → EquivariantEquiv) (α × ℝ) ℝ :=
  ⟨fun φ p => φ p.1 p.2⟩

@[simp]
theorem coe_mk (f : ℝ ≃ ℝ) (h₀ h₁) : ⇑(⟨f, h₀, h₁⟩ : EquivariantEquiv) = f := by
  sorry

-- Warning: making this a simp lemma creates a loop with `Equiv.toFun_as_coe` or
-- `Equiv.toFun_as_coe_apply`
theorem coe_toEquiv (e : EquivariantEquiv) : (⇑(e : ℝ ≃ ℝ) : ℝ → ℝ) = e := by
  sorry

/-- The inverse of an `equivariant_equiv` is an `equivariant_equiv`. -/
def symm (e : EquivariantEquiv) : EquivariantEquiv :=
  { (e : ℝ ≃ ℝ).symm with
    map_zero' := by
      rw [← (e : ℝ ≃ ℝ).apply_eq_iff_eq, Equiv.toFun_as_coe, Equiv.apply_symm_apply, coe_toEquiv,
        map_zero]
    eqv' := fun t => by
      let f := (e : ℝ ≃ ℝ)
      let g := (e : ℝ ≃ ℝ).symm
      change g (t + 1) = g t + 1
      calc
        g (t + 1) = g (f (g t) + 1) := by rw [(e : ℝ ≃ ℝ).apply_symm_apply]
        _ = g (f (g t + 1)) := by congr; exact (e.eqv (g t)).symm
        _ = g t + 1 := (e : ℝ ≃ ℝ).symm_apply_apply _ }

instance : EquivLike EquivariantEquiv ℝ ℝ where
  coe e := e.toFun
  inv e := e.invFun
  left_inv e := e.left_inv
  right_inv e := e.right_inv
  coe_injective' e₁ e₂ h₁ h₂ := by
    rcases e₁ with ⟨f₁, hf₁⟩
    rcases e₂ with ⟨f₂, hf₂⟩
    suffices f₁ = f₂ by simpa
    ext
    change (f₁ : ℝ → ℝ)  = f₂ at h₁
    rw [h₁]

@[ext]
theorem ext {e₁ e₂ : EquivariantEquiv} (h : ∀ x, e₁ x = e₂ x) : e₁ = e₂ := by
  sorry

@[simp]
theorem symm_symm (e : EquivariantEquiv) : e.symm.symm = e := by
  sorry

@[simp]
theorem symm_apply_apply (e : EquivariantEquiv) : ∀ x, e.symm (e x) = x := by
  sorry

end EquivariantEquiv
