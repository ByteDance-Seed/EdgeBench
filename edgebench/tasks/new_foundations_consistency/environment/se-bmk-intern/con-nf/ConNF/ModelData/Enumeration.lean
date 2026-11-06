import ConNF.Background.Rel
import ConNF.Base.Small

/-!
# Enumerations

In this file, we define enumerations of a type.

## Main declarations

* `ConNF.Enumeration`: The type family of enumerations.
-/

universe u

open Cardinal

namespace ConNF

variable [Params.{u}] {X Y : Type u}

@[ext]
structure Enumeration (X : Type u) where
  bound : κ
  rel : Rel κ X
  lt_bound : ∀ i ∈ rel.dom, i < bound
  rel_coinjective : rel.Coinjective

variable {E F G : Enumeration X}

namespace Enumeration

instance : CoeTC (Enumeration X) (Set X) where
  coe E := E.rel.codom

instance : Membership X (Enumeration X) where
  mem E x := x ∈ E.rel.codom

theorem mem_iff (x : X) (E : Enumeration X) :
    x ∈ E ↔ x ∈ E.rel.codom := by
  sorry

theorem mem_congr {E F : Enumeration X} (h : E = F) :
    ∀ x, x ∈ E ↔ x ∈ F := by
  sorry

theorem coe_small (E : Enumeration X) :
    Small (E : Set X) := by
  sorry

theorem graph'_small (E : Enumeration X) :
    Small E.rel.graph' := by
  sorry

noncomputable def empty : Enumeration X where
  bound := 0
  rel _ _ := False
  lt_bound _ h := by cases h; contradiction
  rel_coinjective := by constructor; intros; contradiction

@[simp]
theorem not_mem_empty (x : X) : x ∉ Enumeration.empty := by
  sorry

noncomputable def singleton (x : X) : Enumeration X where
  bound := 1
  rel i y := i = 0 ∧ y = x
  lt_bound i h := by
    have : i = 0 := by simpa only [Rel.dom, exists_eq_right, Set.setOf_eq_eq_singleton,
      Set.mem_singleton_iff] using h
    rw [this, κEquiv_lt, ← Subtype.coe_lt_coe, κEquiv_ofNat, κEquiv_ofNat, Nat.cast_zero,
      Nat.cast_one]
    exact zero_lt_one
  rel_coinjective := by
    constructor
    cc

@[simp]
theorem mem_singleton_iff (x y : X) :
    y ∈ singleton x ↔ y = x := by
  sorry

/-!
## Cardinality bounds on enumerations
-/

end Enumeration

def enumerationEmbedding (X : Type u) : Enumeration X ↪ κ × {s : Set (κ × X) | Small s} where
  toFun E := (E.bound, ⟨E.rel.graph', E.graph'_small⟩)
  inj' := by
    intro E F h
    rw [Prod.mk.injEq, Subtype.mk.injEq] at h
    exact Enumeration.ext h.1 (Rel.graph'_injective h.2)

namespace Enumeration

/-!
## Enumerations from sets
-/

theorem exists_equiv (s : Set X) (hs : Small s) :
    Nonempty ((i : κ) × (s ≃ Set.Iio i)) := by
  sorry

noncomputable def ofSet (s : Set X) (hs : Small s) : Enumeration X where
  bound := (exists_equiv s hs).some.1
  rel i x := ∃ h, i = (exists_equiv s hs).some.2 ⟨x, h⟩
  lt_bound := by
    rintro _ ⟨x, h, rfl⟩
    exact ((exists_equiv s hs).some.2 ⟨x, h⟩).prop
  rel_coinjective := by
    constructor
    rintro x y i ⟨hx, hix⟩ ⟨hy, hiy⟩
    rw [hix] at hiy
    cases (exists_equiv s hs).some.2.injective (Subtype.coe_injective hiy)
    rfl

@[simp]
theorem mem_ofSet_iff (s : Set X) (hs : Small s) (x : X) :
    x ∈ ofSet s hs ↔ x ∈ s := by
  sorry

@[simp]
theorem ofSet_coe (s : Set X) (hs : Small s) :
    (ofSet s hs : Set X) = s := by
  sorry

/-!
## Operations on enumerations
-/

def image (E : Enumeration X) (f : X → Y) : Enumeration Y where
  bound := E.bound
  rel i y := ∃ x, E.rel i x ∧ f x = y
  lt_bound := by
    rintro i ⟨_, x, hi, rfl⟩
    exact E.lt_bound i ⟨x, hi⟩
  rel_coinjective := by
    constructor
    rintro i _ _ ⟨x₁, hx₁, rfl⟩ ⟨x₂, hx₂, rfl⟩
    rw [E.rel_coinjective.coinjective hx₁ hx₂]

@[simp]
theorem image_bound {f : X → Y} :
    (E.image f).bound = E.bound := by
  sorry

theorem image_rel {f : X → Y} (i : κ) (y : Y) :
    (E.image f).rel i y ↔ ∃ x, E.rel i x ∧ f x = y := by
  sorry

@[simp]
theorem mem_image {f : X → Y} (y : Y) :
    y ∈ E.image f ↔ y ∈ f '' E := by
  sorry

def invImage (E : Enumeration X) (f : Y → X) (hf : f.Injective) : Enumeration Y where
  bound := E.bound
  rel i y := E.rel i (f y)
  lt_bound := by
    rintro i ⟨y, hy⟩
    exact E.lt_bound i ⟨f y, hy⟩
  rel_coinjective := by
    constructor
    intro i y₁ y₂ h₁ h₂
    exact hf <| E.rel_coinjective.coinjective h₁ h₂

theorem invImage_rel {f : Y → X} {hf : f.Injective} (i : κ) (y : Y) :
    (E.invImage f hf).rel i y ↔ E.rel i (f y) := by
  sorry

@[simp]
theorem mem_invImage {f : Y → X} {hf : f.Injective} (y : Y) :
    y ∈ E.invImage f hf ↔ f y ∈ E := by
  sorry

def comp (E : Enumeration X) (r : Rel X Y) (hr : r.Coinjective) : Enumeration Y where
  bound := E.bound
  rel := E.rel.comp r
  lt_bound := by
    rintro i ⟨y, x, hy⟩
    exact E.lt_bound i ⟨x, hy.1⟩
  rel_coinjective := E.rel_coinjective.comp hr

instance {G X : Type _} [Group G] [MulAction G X] :
    SMul G (Enumeration X) where
  smul π E := E.invImage (λ x ↦ π⁻¹ • x) (MulAction.injective π⁻¹)

@[simp]
theorem smul_rel {G X : Type _} [Group G] [MulAction G X]
    (π : G) (E : Enumeration X) (i : κ) (x : X) :
    (π • E).rel i x ↔ E.rel i (π⁻¹ • x) := by
  sorry

@[simp]
theorem mem_smul {G X : Type _} [Group G] [MulAction G X]
    (π : G) (E : Enumeration X) (x : X) :
    x ∈ π • E ↔ π⁻¹ • x ∈ E := by
  sorry

open scoped Pointwise in

open scoped Pointwise in
@[simp]
theorem smul_coe {G X : Type _} [Group G] [MulAction G X]
    (π : G) (E : Enumeration X) :
    ((π • E : Enumeration X) : Set X) = π • (E : Set X) := by
  sorry

instance {G X : Type _} [Group G] [MulAction G X] :
    MulAction G (Enumeration X) where
  one_smul E := by
    ext i x
    · rfl
    · rw [smul_rel, inv_one, one_smul]
  mul_smul π₁ π₂ E := by
    ext i x
    · rfl
    · rw [smul_rel, smul_rel, smul_rel, mul_inv_rev, mul_smul]

/-!
## Concatenation of enumerations
-/

noncomputable instance : Add (Enumeration X) where
  add E F := {
    bound := E.bound + F.bound
    rel := E.rel ⊔ Rel.comp (E.bound + ·).graph.inv F.rel
    lt_bound := by
      rintro i ⟨x, hi | ⟨j, rfl, hjx⟩⟩
      · exact (E.lt_bound i ⟨x, hi⟩).trans_le (κ_le_add E.bound F.bound)
      · rw [add_lt_add_iff_left]
        exact F.lt_bound j ⟨x, hjx⟩
    rel_coinjective := by
      constructor
      rintro x y i (hix | ⟨j, hj, hjx⟩) (hiy | ⟨k, hk, hky⟩)
      · exact E.rel_coinjective.coinjective hix hiy
      · cases hk
        have := E.lt_bound _ ⟨x, hix⟩
        rw [add_lt_iff_neg_left] at this
        cases (κ_zero_le k).not_gt this
      · cases hj
        have := E.lt_bound _ ⟨y, hiy⟩
        rw [add_lt_iff_neg_left] at this
        cases (κ_zero_le j).not_gt this
      · cases hj
        simp only [Rel.inv, flip, Function.graph_def, add_right_inj] at hk
        cases hk
        exact F.rel_coinjective.coinjective hjx hky
  }

theorem rel_add_iff {E F : Enumeration X} (i : κ) (x : X) :
    (E + F).rel i x ↔ E.rel i x ∨ ∃ j, E.bound + j = i ∧ F.rel j x := by
  sorry

@[simp]
theorem mem_add_iff {E F : Enumeration X} (x : X) :
    x ∈ E + F ↔ x ∈ E ∨ x ∈ F := by
  sorry

@[simp]
theorem coe_add {E F : Enumeration X} :
    (E + F : Set X) = (E : Set X) ∪ F := by
  sorry

-- TODO: Some stuff about the partial order on enumerations and concatenation of enumerations.

end Enumeration

end ConNF
