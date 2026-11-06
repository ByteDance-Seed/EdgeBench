import Mathlib.GroupTheory.Perm.Basic
import ConNF.Base.NearLitter

/-!
# Base permutations

In this file, we define the group of *base permutations*, and their actions on atoms, litters, and
near-litters. In the paper, these are called *`-1`-allowable permutations*, but that term has a
different meaning in this formalisation.
-/

universe u

open Cardinal Equiv
open scoped Pointwise

namespace ConNF

variable [Params.{u}]

/-!
## Definitions
-/

/-- A *base permutation* consists of a permutation of atoms, a permutation of litters, and a proof
that if some set `s` is near the litter set of some litter `L`, then when we apply the permutation
of atoms pointwise to `s`, the resulting set of atoms is near the litter obtained by applying the
permutation of litters to `L`. This condition means that the pointwise image of a near-litter `N`
under the permutation of atoms is a near-litter, and that the litter it is near to is just the image
of `Nᴸ` under the permutation of litters. It is easy to see that it is not necessary to include
the litter permutation in this definition, because the image of some litter `L` under the
permutation of litters must be the unique litter near the pointwise image of `Lᴬ` under the map of
atoms; we simply include the data of this extra permutation for definitional convenience. -/
structure BasePerm where
  atoms : Perm Atom
  litters : Perm Litter
  apply_near_apply (s : Set Atom) (L : Litter) : s ~ Lᴬ → atoms '' s ~ (litters L)ᴬ

namespace BasePerm

/-- If `π` is a base permutation, we write `πᴬ` for its associated permutation of atoms. -/
instance : SuperA BasePerm (Perm Atom) where
  superA := atoms

/-- If `π` is a base permutation, we write `πᴸ` for its associated permutation of litters. -/
instance : SuperL BasePerm (Perm Litter) where
  superL := litters

/-- For a base permutation `π` and an atom `a`, we write `π • a` for `πᴬ a`.
We will later show that this is a group action. -/
instance : SMul BasePerm Atom where
  smul π a := πᴬ a

/-- For a base permutation `π` and a litter `L`, we write `π • L` for `πᴸ L`.
We will later show that this is a group action. -/
instance : SMul BasePerm Litter where
  smul π L := πᴸ L

/-- A restatement of `apply_near_apply` using the new notations. -/
theorem smul_near_smul (π : BasePerm) (s : Set Atom) (L : Litter) :
    s ~ Lᴬ → π • s ~ (π • L)ᴬ := by
  sorry

/-- For a base permutation `π` and an atom `N`, we write `π • N` for the near-litter `N'` such that
`N'ᴸ = π • Nᴸ` and `N'ᴬ = π • Nᴬ`, where the latter group action on sets of atoms is the pointwise
action. We will later show that this is a group action. -/
instance : SMul BasePerm NearLitter where
  smul π N := ⟨π • Nᴸ, π • Nᴬ, π.smul_near_smul Nᴬ Nᴸ N.atoms_near_litter⟩

/-! We establish some useful definitional equalities. -/

theorem smul_atom_def (π : BasePerm) (a : Atom) :
    π • a = πᴬ a := by
  sorry

theorem smul_litter_def (π : BasePerm) (L : Litter) :
    π • L = πᴸ L := by
  sorry

/-- An extensionality principle for base permutations: if two base permutations have the same
action on atoms, then they coincide. This is because we can recover the data of `πᴸ` from `πᴬ`,
given that `π` is a base permutation. -/
@[ext]
theorem ext {π₁ π₂ : BasePerm} (h : ∀ a : Atom, π₁ • a = π₂ • a) :
    π₁ = π₂ := by
  sorry

/-!
## Group structure
-/

/-- The identity permutation. -/
instance : One BasePerm where
  one := ⟨1, 1, λ s L h ↦ by simpa only [Perm.coe_one, id_eq, Set.image_id']⟩

@[simp]
theorem one_atom :
    (1 : BasePerm)ᴬ = 1 := by
  sorry

@[simp]
theorem one_litter :
    (1 : BasePerm)ᴸ = 1 := by
  sorry

/-- The composition of permutations. -/
instance : Mul BasePerm where
  mul π₁ π₂ := ⟨π₁ᴬ * π₂ᴬ, π₁ᴸ * π₂ᴸ, λ s L h ↦ by
    have := π₁.smul_near_smul _ _ <| π₂.smul_near_smul s L h
    simpa only [Set.smul_set_def, Set.image_image] using this⟩

@[simp]
theorem mul_atom (π₁ π₂ : BasePerm) :
    (π₁ * π₂)ᴬ = π₁ᴬ * π₂ᴬ := by
  sorry

@[simp]
theorem mul_litter (π₁ π₂ : BasePerm) :
    (π₁ * π₂)ᴸ = π₁ᴸ * π₂ᴸ := by
  sorry

/-- The relevant instance of `smul_near_smul` for the inverse of a base permutation. -/
theorem inv_smul_near_inv_smul (π : BasePerm) (s : Set Atom) (L : Litter) :
    s ~ Lᴬ → πᴬ⁻¹ • s ~ (πᴸ⁻¹ • L)ᴬ := by
  sorry

/-- The inverse of a permutation. -/
instance : Inv BasePerm where
  inv π := ⟨πᴬ⁻¹, πᴸ⁻¹, π.inv_smul_near_inv_smul⟩

@[simp]
theorem inv_atom (π : BasePerm) :
    π⁻¹ᴬ = πᴬ⁻¹ := by
  sorry

@[simp]
theorem inv_litter (π : BasePerm) :
    π⁻¹ᴸ = πᴸ⁻¹ := by
  sorry

/-- The group structure on base permutations. -/
instance : Group BasePerm where
  mul_assoc π₁ π₂ π₃ := by
    ext a
    simp only [smul_atom_def, mul_atom, mul_assoc]
  one_mul π := by
    ext a
    simp only [smul_atom_def, mul_atom, one_atom, one_mul]
  mul_one π := by
    ext a
    simp only [smul_atom_def, mul_atom, one_atom, mul_one]
  inv_mul_cancel π := by
    ext a
    simp only [smul_atom_def, mul_atom, inv_atom, inv_mul_cancel, Perm.coe_one, id_eq, one_atom]

/-- The action of base permutations on atoms is a group action. -/
instance : MulAction BasePerm Atom where
  one_smul _ := rfl
  mul_smul _ _ _ := rfl

/-- The action of base permutations on litters is a group action. -/
instance : MulAction BasePerm Litter where
  one_smul _ := rfl
  mul_smul _ _ _ := rfl

/-- The action of base permutations on near-litters is a group action. -/
instance : MulAction BasePerm NearLitter where
  one_smul N := by sorry
  mul_smul π₁ π₂ N := by sorry

end BasePerm

end ConNF
