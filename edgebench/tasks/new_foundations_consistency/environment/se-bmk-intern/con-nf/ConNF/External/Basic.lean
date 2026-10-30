import ConNF.Model.Result

/-!
# New file

In this file...

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal ConNF.TSet

namespace ConNF

variable [Params.{u}] {α β γ δ ε ζ : Λ} (hβ : (β : TypeIndex) < α) (hγ : (γ : TypeIndex) < β)
  (hδ : (δ : TypeIndex) < γ) (hε : (ε : TypeIndex) < δ) (hζ : (ζ : TypeIndex) < ε)

theorem inter_comm (x y : TSet α) :
    x ⊓' y = y ⊓' x := by
  sorry

def union (x y : TSet α) : TSet α :=
  (xᶜ' ⊓' yᶜ')ᶜ'

notation:68 x:68 " ⊔[" h "] " y:68 => _root_.ConNF.union h x y
notation:68 x:68 " ⊔' " y:68 => x ⊔[by assumption] y

@[simp]
theorem mem_union_iff (x y : TSet α) :
    ∀ z : TSet β, z ∈' x ⊔' y ↔ z ∈' x ∨ z ∈' y := by
  sorry

theorem union_comm (x y : TSet α) :
    x ⊔' y = y ⊔' x := by
  sorry

def symmDiff (x y : TSet α) : TSet α :=
  (x ⊓' yᶜ') ⊔' (xᶜ' ⊓' y)

notation:100 x:100 " ∆[" h "] " y:100 => _root_.ConNF.symmDiff h x y
notation:100 x:100 " ∆' " y:100 => x ∆[by assumption] y

@[simp]
theorem mem_symmDiff_iff (x y : TSet α) :
    ∀ z : TSet β, z ∈' x ∆' y ↔ (z ∈' x ↔ ¬(z ∈' y)) := by
  sorry

def diff (x y : TSet α) : TSet α :=
  x ⊓' yᶜ'

notation:70 x:70 " \\[" h "] " y:70 => _root_.ConNF.diff h x y
notation:70 x:70 " \\' " y:70 => x \[by assumption] y

@[simp]
theorem mem_diff_iff (x y : TSet α) :
    ∀ z : TSet β, z ∈' x \' y ↔ z ∈' x ∧ ¬(z ∈' y) := by
  sorry

def higherIndex (α : Λ) : Λ :=
  (exists_gt α).choose

/-- A short name is chosen because of its frequency of use. -/
theorem high {α : Λ} :
    (α : TypeIndex) < higherIndex α := by
  sorry

theorem tSet_nonempty (h : ∃ β : Λ, (β : TypeIndex) < α) : Nonempty (TSet α) := by
  sorry

def empty : TSet α :=
  (tSet_nonempty ⟨β, hβ⟩).some ⊓' (tSet_nonempty ⟨β, hβ⟩).someᶜ'

@[simp]
theorem mem_empty_iff :
    ∀ x : TSet β, ¬x ∈' empty hβ := by
  sorry

def univ : TSet α :=
  (empty hβ)ᶜ'

@[simp]
theorem mem_univ_iff :
    ∀ x : TSet β, x ∈' univ hβ := by
  sorry

/-- The set of all ordered pairs. -/
def orderedPairs : TSet α :=
  vCross hβ hγ hδ (univ hδ)

@[simp]
theorem mem_orderedPairs_iff (x : TSet β) :
    x ∈' orderedPairs hβ hγ hδ ↔ ∃ a b, x = ⟨a, b⟩' := by
  sorry

def converse (x : TSet α) : TSet α :=
  converse' hβ hγ hδ x ⊓' orderedPairs hβ hγ hδ

@[simp]
theorem op_mem_converse_iff (x : TSet α) :
    ∀ a b, ⟨a, b⟩' ∈' converse hβ hγ hδ x ↔ ⟨b, a⟩' ∈' x := by
  sorry

def cross (x y : TSet γ) : TSet α :=
  converse hβ hγ hδ (vCross hβ hγ hδ x) ⊓' vCross hβ hγ hδ y

@[simp]
theorem mem_cross_iff (x y : TSet γ) :
    ∀ a, a ∈' cross hβ hγ hδ x y ↔ ∃ b c, a = ⟨b, c⟩' ∧ b ∈' x ∧ c ∈' y := by
  sorry

def singletonImage (x : TSet β) : TSet α :=
  singletonImage' hβ hγ hδ hε x ⊓' (cross hβ hγ hδ (cardinalOne hδ hε) (cardinalOne hδ hε))

@[simp]
theorem singletonImage_spec (x : TSet β) :
    ∀ z w,
    ⟨ {z}', {w}' ⟩' ∈' singletonImage hβ hγ hδ hε x ↔ ⟨z, w⟩' ∈' x := by
  sorry

theorem exists_of_mem_singletonImage {x : TSet β} {z w : TSet δ}
    (h : ⟨z, w⟩' ∈' singletonImage hβ hγ hδ hε x) :
    ∃ a b, z = {a}' ∧ w = {b}' := by
  sorry

/-- Turn a model element encoding a relation into an actual relation. -/
def ExternalRel (r : TSet α) : Rel (TSet δ) (TSet δ) :=
  λ x y ↦ ⟨x, y⟩' ∈' r

@[simp]
theorem externalRel_converse (r : TSet α) :
    ExternalRel hβ hγ hδ (converse hβ hγ hδ r) = (ExternalRel hβ hγ hδ r).inv := by
  sorry

/-- The codomain of a relation. -/
def codom (r : TSet α) : TSet γ :=
  (typeLower high hβ hγ hδ (singletonImage high hβ hγ hδ r)ᶜ[high])ᶜ'

@[simp]
theorem mem_codom_iff (r : TSet α) (x : TSet δ) :
    x ∈' codom hβ hγ hδ r ↔ x ∈ (ExternalRel hβ hγ hδ r).codom := by
  sorry

/-- The domain of a relation. -/
def dom (r : TSet α) : TSet γ :=
  codom hβ hγ hδ (converse hβ hγ hδ r)

@[simp]
theorem mem_dom_iff (r : TSet α) (x : TSet δ) :
    x ∈' dom hβ hγ hδ r ↔ x ∈ (ExternalRel hβ hγ hδ r).dom := by
  sorry

/-- The field of a relation. -/
def field (r : TSet α) : TSet γ :=
  dom hβ hγ hδ r ⊔' codom hβ hγ hδ r

@[simp]
theorem mem_field_iff (r : TSet α) (x : TSet δ) :
    x ∈' field hβ hγ hδ r ↔ x ∈ (ExternalRel hβ hγ hδ r).field := by
  sorry

def subset : TSet α :=
  subset' hβ hγ hδ hε ⊓' orderedPairs hβ hγ hδ

@[simp]
theorem subset_spec :
    ∀ a b, ⟨a, b⟩' ∈' subset hβ hγ hδ hε ↔ a ⊆[TSet ε] b := by
  sorry

@[simp]
theorem singleton_subset_iff (a : TSet β) (b : TSet α) :
    {a}' ⊆[TSet β] b ↔ a ∈' b := by
  sorry

def membership : TSet α :=
  subset hβ hγ hδ hε ⊓' cross hβ hγ hδ (cardinalOne hδ hε) (univ hδ)

@[simp]
theorem membership_spec :
    ∀ a b, ⟨{a}', b⟩' ∈' membership hβ hγ hδ hε ↔ a ∈' b := by
  sorry

def powerset (x : TSet β) : TSet α :=
  dom high high hβ
    (subset high high hβ hγ ⊓[high]
      vCross high high hβ {x}')

@[simp]
theorem mem_powerset_iff (x y : TSet β) :
    x ∈' powerset hβ hγ y ↔ x ⊆[TSet γ] y := by
  sorry

/-- The set `ι²''x = {{{a}} | a ∈ x}`. -/
def doubleSingletons (x : TSet γ) : TSet α :=
  cross hβ hγ hδ x x ⊓' cardinalOne hβ hγ

@[simp]
theorem mem_doubleSingletons_iff (x : TSet γ) :
    ∀ y : TSet β, y ∈' doubleSingletons hβ hγ hδ x ↔
    ∃ z : TSet δ, z ∈' x ∧ y = { {z}' }' := by
  sorry

/-- The union of a set of *singletons*: `ι⁻¹''x = {a | {a} ∈ x}`.
Scott Fenton calls this the "unit union". -/
def singletonUnion (x : TSet α) : TSet β :=
  typeLower high high hβ hγ
    (vCross high high hβ x)

@[simp]
theorem mem_singletonUnion_iff (x : TSet α) :
    ∀ y : TSet γ, y ∈' singletonUnion hβ hγ x ↔ {y}' ∈' x := by
  sorry

/-- The set of singletons of a set: `ι''x = {{a} | a ∈ x}`.
Scott Fenton calls this the "unit powerset". -/
def singletons (x : TSet β) : TSet α :=
  singletonUnion high hβ (doubleSingletons high hβ hγ x)

@[simp]
theorem mem_singletons_iff (x : TSet β) :
    ∀ y : TSet β, y ∈' singletons hβ hγ x ↔ ∃ t : TSet γ, t ∈' x ∧ y = {t}' := by
  sorry

/--
The union of a set of sets.

```
⋃ x =
{a | a ∈ b ∧ b ∈ x} =
singletonUnion {{a} | a ∈ b ∧ b ∈ x} =
singletonUnion dom {⟨{a}, b⟩ | a ∈ b ∧ b ∈ x} =
singletonUnion dom ({⟨{a}, b⟩ | a ∈ b} ∩ (1 × x))
```
-/
def sUnion (x : TSet α) : TSet β :=
  singletonUnion hβ hγ <|
  dom high high hβ <|
  membership high high hβ hγ ⊓[high]
    cross high high hβ (cardinalOne hβ hγ) x

@[simp]
theorem mem_sUnion_iff (x : TSet α) :
    ∀ y : TSet γ, y ∈' sUnion hβ hγ x ↔ ∃ t : TSet β, t ∈' x ∧ y ∈' t := by
  sorry

/-- The set of all ordered triples. -/
def orderedTriples : TSet α :=
  cross hβ hγ hδ (doubleSingletons hδ hε hζ (univ hζ)) (vCross hδ hε hζ (univ hζ))

@[simp]
theorem mem_orderedTriples_iff (x : TSet β) :
    x ∈' orderedTriples hβ hγ hδ hε hζ ↔ ∃ a b c, x = ⟨ { {a}' }', ⟨b, c⟩' ⟩' := by
  sorry

def insertion2 (x : TSet γ) : TSet α :=
  insertion2' hβ hγ hδ hε hζ x ⊓' orderedTriples hβ hγ hδ hε hζ

@[simp]
theorem insertion2_spec (x : TSet γ) :
    ∀ a b c, ⟨ { {a}' }', ⟨b, c⟩' ⟩' ∈' insertion2 hβ hγ hδ hε hζ x ↔
    ⟨a, c⟩' ∈' x := by
  sorry

def insertion3 (x : TSet γ) : TSet α :=
  insertion3' hβ hγ hδ hε hζ x ⊓' orderedTriples hβ hγ hδ hε hζ

@[simp]
theorem insertion3_spec (x : TSet γ) :
    ∀ a b c, ⟨ { {a}' }', ⟨b, c⟩' ⟩' ∈' insertion3 hβ hγ hδ hε hζ x ↔
    ⟨a, b⟩' ∈' x := by
  sorry

/-- The preimage of a set under a relation. -/
def preimage (r : TSet α) (x : TSet γ) : TSet γ :=
  dom hβ hγ hδ (r ⊓' vCross hβ hγ hδ x)

@[simp]
theorem mem_preimage_iff (r : TSet α) (x : TSet γ) (y : TSet δ) :
    y ∈' preimage hβ hγ hδ r x ↔ y ∈ (ExternalRel hβ hγ hδ r).preimage {a | a ∈' x} := by
  sorry

/-- The image of a set under a relation. -/
def image (r : TSet α) (x : TSet γ) : TSet γ :=
  preimage hβ hγ hδ (converse hβ hγ hδ r) x

@[simp]
theorem mem_image_iff (r : TSet α) (x : TSet γ) (y : TSet δ) :
    y ∈' image hβ hγ hδ r x ↔ y ∈ (ExternalRel hβ hγ hδ r).image {a | a ∈' x} := by
  sorry

theorem exists_smallUnion (s : Set (TSet α)) (hs : Small s) :
    ∃ x : TSet α, ∀ y : TSet β, y ∈' x ↔ ∃ t ∈ s, y ∈' t := by
  sorry

/-- Our model is `κ`-complete; small unions exist.
In particular, the model knows the correct natural numbers. -/
def smallUnion (s : Set (TSet α)) (hs : Small s) : TSet α :=
  (exists_smallUnion hβ s hs).choose

@[simp]
theorem mem_smallUnion_iff (s : Set (TSet α)) (hs : Small s) :
    ∀ x : TSet β, x ∈' smallUnion hβ s hs ↔ ∃ t ∈ s, x ∈' t := by
  sorry

end ConNF
