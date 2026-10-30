module

public import Mathlib.MeasureTheory.Measure.FiniteMeasurePi
public import Mathlib.MeasureTheory.Measure.Prokhorov
public import PFR.MoreRuzsaDist

/-!
# The tau functional for multidistance

Definition of the tau functional and basic facts

## Main definitions:

## Main results

-/

public section

open MeasureTheory ProbabilityTheory
universe u

/-- We will frequently be working with finite additive groups with the discrete sigma-algebra. -/
class MeasurableFinGroup (G : Type*)
extends AddCommGroup G, Fintype G,
          MeasurableSpace G, MeasurableSingletonClass G

/-
May need an instance lemma here that [MeasurableSub₂ G] [MeasurableAdd₂ G] [Countable G] follows
automatically from [MeasurableFinGroup G]
-/

/-- A structure that packages all the fixed information in the main argument. See https://leanprover.zulipchat.com/#narrow/stream/270676-lean4/topic/Problem.20when.20instances.20are.20inside.20a.20structure for more discussion of the design choices here. -/
structure multiRefPackage (G Ω₀ : Type u) [MeasurableFinGroup G] [MeasureSpace Ω₀] where
  /-- The torsion index of the group we are considering. -/
  m : ℕ
  hm : m ≥ 2
  htorsion : ∀ x : G, m • x = 0
  hprob : IsProbabilityMeasure (ℙ : Measure Ω₀)
  /-- The random variable -/
  X₀ : Ω₀ → G
  hmeas : Measurable X₀
  /-- A small constant. The argument will only work for suitably small `η`. -/
  η : ℝ
  hη : 0 < η
  hη' : η ≤ 1

/-- If $(X_i)_{1 \leq i \leq m}$ is a tuple, we define its $\tau$-functional
$$ \tau[ (X_i)_{1 \leq i \leq m}] := D[(X_i)_{1 \leq i \leq m}] + \eta \sum_{i=1}^m d[X_i; X^0].$$
-/
noncomputable def multiTau {G Ω₀ : Type u} [MeasurableFinGroup G] [MeasureSpace Ω₀]
    (p : multiRefPackage G Ω₀) (Ω : Fin p.m → Type*) (hΩ : ∀ i, MeasureSpace (Ω i))
    (X : ∀ i, Ω i → G) : ℝ :=
  D[X; hΩ] + p.η * ∑ i, d[ X i # p.X₀ ]

/-
I can't figure out how to make a τ notation due to the dependent types in the arguments.
But perhaps we don't need one. Also it may be better to define multiTau in terms of probability
measures on G, rather than G-valued random variables, again to avoid dependent type issues.
-/

-- had to force objects to lie in a fixed universe `u` here to avoid a compilation error
/-- A $\tau$-minimizer is a tuple $(X_i)_{1 \leq i \leq m}$ that minimizes the $\tau$-functional
among all tuples of $G$-valued random variables. -/
def multiTauMinimizes {G Ω₀ : Type u} [MeasurableFinGroup G] [MeasureSpace Ω₀]
    (p : multiRefPackage G Ω₀) (Ω : Fin p.m → Type u) (hΩ : ∀ i, MeasureSpace (Ω i))
    (X : ∀ i, Ω i → G) : Prop :=
  ∀ (Ω' : Fin p.m → Type u) (hΩ' : ∀ i, MeasureSpace (Ω' i))
    (_hP : ∀ i, IsProbabilityMeasure (volume : Measure (Ω' i)))(X' : ∀ i, Ω' i → G)
    (_hX' : ∀ i, Measurable (X' i)),
  multiTau p Ω hΩ X ≤ multiTau p Ω' hΩ' X'

/-- If $(X_i)_{1 \leq i \leq m}$ is a $\tau$-minimizer,
then $\sum_{i=1}^m d[X_i; X^0] \leq \frac{2m}{\eta} d[X^0; X^0]$. -/
lemma multiTau_min_sum_le {G Ω₀ : Type u} [hG : MeasurableFinGroup G] [hΩ₀ : MeasureSpace Ω₀]
    (p : multiRefPackage G Ω₀) (Ω : Fin p.m → Type u) (hΩ : ∀ i, MeasureSpace (Ω i))
    (hprobΩ : ∀ i, IsProbabilityMeasure (ℙ : Measure (Ω i))) (X : ∀ i, Ω i → G)
    (hX : ∀ i, Measurable (X i)) (h_min : multiTauMinimizes p Ω hΩ X) :
  ∑ i, d[X i # p.X₀] ≤ 2 * p.m * p.η⁻¹ * d[p.X₀ # p.X₀] := by
  sorry

/-- If $(X_i)_{1 \leq i \leq m}$ is a $\tau$-minimizer, and $k := D[(X_i)_{1 \leq i \leq m}]$,
then for any other tuple $(X'_i)_{1 \leq i \leq m}$, one has
  $$ k - D[(X'_i)_{1 \leq i \leq m}] \leq \eta \sum_{i=1}^m d[X_i; X'_i].$$
-/
lemma sub_multiDistance_le {G Ω₀ : Type u} [MeasurableFinGroup G] [hΩ₀ : MeasureSpace Ω₀]
    {p : multiRefPackage G Ω₀} {Ω : Fin p.m → Type u} {hΩ : ∀ i, MeasureSpace (Ω i)}
    (hΩprob : ∀ i, IsProbabilityMeasure (hΩ i).volume) {X : ∀ i, Ω i → G}
    (hmeasX : ∀ i, Measurable (X i)) (h_min : multiTauMinimizes p Ω hΩ X)
    {Ω' : Fin p.m → Type u} {hΩ' : ∀ i, MeasureSpace (Ω' i)}
    (hΩprob' : ∀ i, IsProbabilityMeasure (hΩ' i).volume)
    {X' : ∀ i, Ω' i → G} (hmeasX' : ∀ i, Measurable (X' i)) :
    D[X; hΩ] - D[X'; hΩ'] ≤ p.η * ∑ i, d[X i ; (hΩ i).volume # X' i; (hΩ' i).volume ] := by
  sorry

lemma sub_multiDistance_le' {G Ω₀ : Type u} [MeasurableFinGroup G] [MeasureSpace Ω₀]
    {p : multiRefPackage G Ω₀} {Ω : Fin p.m → Type u} {hΩ : ∀ i, MeasureSpace (Ω i)}
    (hΩprob : ∀ i, IsProbabilityMeasure (hΩ i).volume)
    {X : ∀ i, Ω i → G} (hmeasX : ∀ i, Measurable (X i)) (h_min : multiTauMinimizes p Ω hΩ X)
    {Ω' : Fin p.m → Type u} {hΩ' : ∀ i, MeasureSpace (Ω' i)}
    (hΩ'prob : ∀ i, IsProbabilityMeasure (hΩ' i).volume) {X' : ∀ i, Ω' i → G}
    (hmeasX' : ∀ i, Measurable (X' i)) (φ : Equiv.Perm (Fin p.m)) :
    D[X; hΩ] - D[X'; hΩ'] ≤
      p.η * ∑ i, d[X (φ i) ; (hΩ (φ i)).volume # X' i; (hΩ' i).volume ] := by
  sorry

/-- If $(X_i)_{1 \leq i \leq m}$ is a $\tau$-minimizer, and $k := D[(X_i)_{1 \leq i \leq m}]$,
then for any other tuples $(X'_i)_{1 \leq i \leq m}$ and $(Y_i)_{1 \leq i \leq m}$ with the $X'_i$
G$-valued, one has
$$ k - D[(X'_i)_{1 \leq i \leq m} | (Y_i)_{1 \leq i \leq m}]
  \leq \eta \sum_{i=1}^m d[X_i; X'_i|Y_i].$$ -/
lemma sub_condMultiDistance_le {G Ω₀ : Type u} [MeasurableFinGroup G] [MeasureSpace Ω₀]
    {p : multiRefPackage G Ω₀} {Ω : Fin p.m → Type u} {hΩ : ∀ i, MeasureSpace (Ω i)}
    (hΩprob : ∀ i, IsProbabilityMeasure (hΩ i).volume) {X : ∀ i, Ω i → G}
    (hmeasX : ∀ i, Measurable (X i)) (h_min : multiTauMinimizes p Ω hΩ X)
    {Ω' : Fin p.m → Type u} {hΩ' : ∀ i, MeasureSpace (Ω' i)}
    (hΩ'prob : ∀ i, IsProbabilityMeasure (hΩ' i).volume)
    {X' : ∀ i, Ω' i → G} (hmeasX' : ∀ i, Measurable (X' i))
    {S : Type u} [Fintype S] [MeasurableSpace S] [MeasurableSingletonClass S]
    {Y : ∀ i, Ω' i → S} (hY : ∀ i, Measurable (Y i)) :
    D[X; hΩ] - D[X'|Y; hΩ'] ≤ p.η * ∑ i, d[X i ; (hΩ i).volume # X' i | Y i; (hΩ' i).volume] := by
  sorry

/-- With the notation of the previous lemma, we have
  \begin{equation}\label{5.3-conv}
    k - D[ X'_{[m]} | Y_{[m]} ] \leq \eta \sum_{i=1}^m d[X_{\sigma(i)};X'_i|Y_i]
  \end{equation}
for any permutation $\sigma : \{1,\dots,m\} \rightarrow \{1,\dots,m\}$. -/
lemma sub_condMultiDistance_le' {G Ω₀ : Type u} [MeasurableFinGroup G] [MeasureSpace Ω₀]
    {p : multiRefPackage G Ω₀} {Ω : Fin p.m → Type u} {hΩ : ∀ i, MeasureSpace (Ω i)}
    (hΩprob : ∀ i, IsProbabilityMeasure (hΩ i).volume)
    {X : ∀ i, Ω i → G} (hmeasX : ∀ i, Measurable (X i)) (h_min : multiTauMinimizes p Ω hΩ X)
    {Ω' : Fin p.m → Type u} {hΩ' : ∀ i, MeasureSpace (Ω' i)}
    (hΩ'prob : ∀ i, IsProbabilityMeasure (hΩ' i).volume) {X' : ∀ i, Ω' i → G}
    (hmeasX' : ∀ i, Measurable (X' i))
    {S : Type u} [Fintype S] [MeasurableSpace S] [MeasurableSingletonClass S]
    {Y : ∀ i, Ω' i → S} (hY : ∀ i, Measurable (Y i)) (φ : Equiv.Perm (Fin p.m)) :
    D[X; hΩ] - D[X'|Y; hΩ'] ≤
      p.η * ∑ i, d[X (φ i) ; (hΩ (φ i)).volume # X' i | Y i; (hΩ' i).volume ] := by
  sorry
