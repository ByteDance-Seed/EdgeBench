module

public import PFR.ForMathlib.Entropy.RuzsaDist

/-!
# The 100% version of entropic PFR

Here we show entropic PFR in the case of doubling constant zero.

## Main results

* `exists_isUniform_of_rdist_eq_zero` : If $d[X_1;X_2]=0$, then there exists a subgroup $H \leq G$
such that $d[X_1;U_H] = d[X_2;U_H] = 0$.
-/

public section

open MeasureTheory ProbabilityTheory Real

variable {Ω : Type*} {G : Type*} [MeasureSpace Ω] [MeasurableSpace G] [AddCommGroup G]
  [MeasurableAdd₂ G] {X : Ω → G}

/-- The symmetry group Sym of $X$: the set of all $h ∈ G$ such that $X + h$ has an identical
distribution to $X$. -/
def symmGroup (X : Ω → G) (hX : Measurable X) : AddSubgroup G where
  carrier := {x | IdentDistrib X (fun ω ↦ X ω + x)}
  add_mem' := by
    intro x y hx hy
    let f : G → G := fun g ↦ g + x
    have : IdentDistrib (f ∘ X) (fun ω ↦ f (X ω + y)) := hy.comp <| measurable_add_const _
    have Z := hx.trans this
    dsimp
    convert Z using 1
    ext ω
    simp only [f]
    abel
  zero_mem' := by simpa using IdentDistrib.refl hX.aemeasurable
  neg_mem' := by
    intro x hx
    dsimp at hx ⊢
    let f : G → G := fun g ↦ g - x
    have : IdentDistrib (f ∘ X) (fun ω ↦ f (X ω + x)) := hx.comp <| measurable_sub_const' _
    convert this.symm using 1
    · ext ω
      simp only [f]
      abel
    · ext ω
      simp only [Function.comp_apply, f]
      abel_nf

@[simp] lemma mem_symmGroup (hX : Measurable X) {x : G} :
    x ∈ symmGroup X hX ↔ IdentDistrib X (fun ω ↦ X ω + x) := by
  sorry

variable [Finite G] [MeasurableSingletonClass G] [IsProbabilityMeasure (ℙ : Measure Ω)]

/-- If $d[X ;X]=0$, and $x,y \in G$ are such that $P[X=x], P[X=y]>0$,
then $x-y \in \mathrm{Sym}[X]$. -/
lemma sub_mem_symmGroup (hX : Measurable X) (hdist : d[X # X] = 0)
    {x y : G} (hx : ℙ (X ⁻¹' {x}) ≠ 0) (hy : ℙ (X ⁻¹' {y}) ≠ 0) : x - y ∈ symmGroup X hX := by
  sorry

/-- If `d[X # X] = 0`, then `X - x₀` is the uniform distribution on the subgroup of `G`
stabilizing the distribution of `X`, for any `x₀` of positive probability. -/
lemma isUniform_sub_const_of_rdist_eq_zero (hX : Measurable X) (hdist : d[X # X] = 0) {x₀ : G}
    (hx₀ : ℙ (X ⁻¹' {x₀}) ≠ 0) : IsUniform (symmGroup X hX) (fun ω ↦ X ω - x₀) := by
  sorry

/-- If $d[X ;X]=0$, then there exists a subgroup $H \leq G$ such that $d[X ;U_H] = 0$. -/
theorem exists_isUniform_of_rdist_self_eq_zero (hX : Measurable X) (hdist : d[X # X] = 0) :
    ∃ H : AddSubgroup G, ∃ U : Ω → G, Measurable U ∧ IsUniform H U ∧ d[X # U] = 0 := by
  sorry

/-- If $d[X_1;X_2]=0$, then there exists a subgroup $H \leq G$ such that
$d[X_1;U_H] = d[X_2;U_H] = 0$. Follows from the preceding claim by the triangle inequality. -/
theorem exists_isUniform_of_rdist_eq_zero
    {Ω' : Type*} [MeasureSpace Ω'] [IsProbabilityMeasure (ℙ : Measure Ω')] {X' : Ω' → G}
    (hX : Measurable X) (hX' : Measurable X') (hdist : d[X # X'] = 0) :
    ∃ H : AddSubgroup G, ∃ U : Ω → G,
      Measurable U ∧ IsUniform H U ∧ d[X # U] = 0 ∧ d[X' # U] = 0 := by
  sorry
