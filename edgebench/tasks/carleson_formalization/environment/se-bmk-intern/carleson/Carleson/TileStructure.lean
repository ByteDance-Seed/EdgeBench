module

public import Carleson.GridStructure

@[expose] public section

open Set MeasureTheory Metric Function Complex Bornology
open scoped NNReal ENNReal ComplexConjugate
noncomputable section

section Generic
universe u
variable {𝕜 : Type*} [_root_.RCLike 𝕜]
variable {X : Type u} {A : ℝ≥0} [PseudoMetricSpace X] [DoublingMeasure X A]

/- The data in a tile structure, and some basic properties.
This is mostly separated out so that we can nicely define the notation `d_𝔭`.
Note: compose `𝓘` with `Grid` to get the `𝓘` of the paper. -/
class PreTileStructure {A : outParam ℝ≥0} [PseudoMetricSpace X] [DoublingMeasure X A]
  [FunctionDistances 𝕜 X] (Q : outParam (SimpleFunc X (Θ X)))
  (D : outParam ℕ) (κ : outParam ℝ) (S : outParam ℕ) (o : outParam X)
  extends GridStructure X D κ S o where
  protected 𝔓 : Type u
  fintype_𝔓 : Fintype 𝔓
  protected 𝓘 : 𝔓 → Grid
  surjective_𝓘 : Surjective 𝓘
  𝒬 : 𝔓 → Θ X
  range_𝒬 : range 𝒬 ⊆ range Q

export PreTileStructure (𝒬 range_𝒬)

variable {D : ℕ} {κ : ℝ} {S : ℕ} {o : X}
variable [FunctionDistances 𝕜 X] {Q : SimpleFunc X (Θ X)} [PreTileStructure Q D κ S o]

variable (X) in
def 𝔓 := PreTileStructure.𝔓 𝕜 X

instance : Fintype (𝔓 X) := PreTileStructure.fintype_𝔓

def 𝓘 : 𝔓 X → Grid X := PreTileStructure.𝓘

lemma surjective_𝓘 : Surjective (𝓘 : 𝔓 X → Grid X) := by
  sorry

instance : Inhabited (𝔓 X) := ⟨(surjective_𝓘 default).choose⟩

def 𝔠 (p : 𝔓 X) : X := c (𝓘 p)
def 𝔰 (p : 𝔓 X) : ℤ := s (𝓘 p)

local notation "ball_(" D "," 𝔭 ")" => @ball (WithFunctionDistance (𝔠 𝔭) (D ^ 𝔰 𝔭 / 4)) _

/-- A tile structure. -/
-- note: we don't explicitly include injectivity of `Ω` on `𝔓(I)`, since it follows from these
-- axioms: see `toTileLike_injective`
class TileStructure {A : outParam ℝ≥0} [PseudoMetricSpace X] [DoublingMeasure X A]
    [FunctionDistances ℝ X] (Q : outParam (SimpleFunc X (Θ X)))
    (D : outParam ℕ) (κ : outParam ℝ) (S : outParam ℕ) (o : outParam X)
    extends PreTileStructure Q D κ S o where
  Ω : 𝔓 → Set (Θ X)
  biUnion_Ω {i} : range Q ⊆ ⋃ p ∈ 𝓘 ⁻¹' {i}, Ω p -- 2.0.13, union contains `Q`
  disjoint_Ω {p p'} (h : p ≠ p') (hp : 𝓘 p = 𝓘 p') : -- 2.0.13, union is disjoint
    Disjoint (Ω p) (Ω p')
  relative_fundamental_dyadic {p p'} (h :
    -- why is the next line needed?!!
    letI : PartialOrder (Grid) := @instPartialOrderGrid X A _ _ D κ S o _
    𝓘 p ≤ 𝓘 p') : -- 2.0.14
    Disjoint (Ω p) (Ω p') ∨ Ω p' ⊆ Ω p
  cball_subset {p : _root_.𝔓 X} : ball_(D, p) (𝒬 p) 5⁻¹ ⊆ Ω p -- 2.0.15, first inclusion
  subset_cball {p : _root_.𝔓 X} : Ω p ⊆ ball_(D, p) (𝒬 p) 1 -- 2.0.15, second inclusion

export TileStructure (Ω biUnion_Ω disjoint_Ω relative_fundamental_dyadic)

end Generic

open scoped ShortVariables
variable {X : Type*} [PseudoMetricSpace X] {a : ℕ} {q : ℝ} {K : X → X → ℂ}
  {σ₁ σ₂ : X → ℤ} {F G : Set X} [ProofData a q K σ₁ σ₂ F G]

section

variable [TileStructure Q D κ S o] {p p' : 𝔓 X} {f g : Θ X}

-- maybe we should delete the following three notations, and use `dist_{𝓘 p}` instead?
notation "dist_(" 𝔭 ")" => @dist (WithFunctionDistance (𝔠 𝔭) (D ^ 𝔰 𝔭 / 4)) _
notation "nndist_(" 𝔭 ")" => @nndist (WithFunctionDistance (𝔠 𝔭) (D ^ 𝔰 𝔭 / 4)) _
notation "edist_(" 𝔭 ")" => @edist (WithFunctionDistance (𝔠 𝔭) (D ^ 𝔰 𝔭 / 4)) _
notation "ball_(" 𝔭 ")" => @ball (WithFunctionDistance (𝔠 𝔭) (D ^ 𝔰 𝔭 / 4)) _

@[simp] lemma dist_𝓘 (p : 𝔓 X) : dist_{𝓘 p} f g = dist_(p) f g := by
  sorry
@[simp] lemma nndist_𝓘 (p : 𝔓 X) : nndist_{𝓘 p} f g = nndist_(p) f g := by
  sorry
@[simp] lemma ball_𝓘 (p : 𝔓 X) {r : ℝ} : ball_{𝓘 p} f r = ball_(p) f r := by
  sorry

@[simp] lemma cball_subset {p : 𝔓 X} : ball_(p) (𝒬 p) 5⁻¹ ⊆ Ω p := by
  sorry
@[simp] lemma subset_cball {p : 𝔓 X} : Ω p ⊆ ball_(p) (𝒬 p) 1 := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma ball_eq_of_grid_eq {p q : 𝔓 X} {ϑ : Θ X} {r : ℝ} (h : 𝓘 p = 𝓘 q) :
    ball_(p) ϑ r = ball_(q) ϑ r := by
  sorry

lemma cball_disjoint {p p' : 𝔓 X} (h : p ≠ p') (hp : 𝓘 p = 𝓘 p') :
    Disjoint (ball_(p) (𝒬 p) 5⁻¹) (ball_(p') (𝒬 p') 5⁻¹) := by
  sorry

/-- A bound used in both nontrivial cases of Lemma 7.5.5. -/
lemma volume_xDsp_bound {x : X} (hx : x ∈ 𝓘 p) :
    volume (ball (𝔠 p) (4 * D ^ 𝔰 p)) / 2 ^ (3 * a) ≤ volume (ball x (D ^ 𝔰 p)) := by
  sorry

/-- A bound used in Lemma 7.6.2. -/
lemma volume_xDsp_bound_4 {x : X} (hx : x ∈ 𝓘 p) :
    volume (ball (𝔠 p) (8 * D ^ 𝔰 p)) / 2 ^ (4 * a) ≤ volume (ball x (D ^ 𝔰 p)) := by
  sorry

/-- The set `E` defined in Proposition 2.0.2. -/
def E (p : 𝔓 X) : Set X :=
  { x ∈ 𝓘 p | Q x ∈ Ω p ∧ 𝔰 p ∈ Icc (σ₁ x) (σ₂ x) }

lemma E_subset_𝓘 {p : 𝔓 X} : E p ⊆ 𝓘 p := by
  sorry

lemma Q_mem_Ω {p : 𝔓 X} {x : X} (hp : x ∈ E p) : Q x ∈ Ω p := by
  sorry

lemma disjoint_E {p p' : 𝔓 X} (h : p ≠ p') (hp : 𝓘 p = 𝓘 p') : Disjoint (E p) (E p') := by
  sorry

lemma measurableSet_E {p : 𝔓 X} : MeasurableSet (E p) := by
  sorry

lemma volume_E_lt_top : volume (E p) < ⊤ := by
  sorry

variable (X) in
def TileLike : Type _ := Grid X × OrderDual (Set (Θ X))

def TileLike.fst (x : TileLike X) : Grid X := x.1
def TileLike.snd (x : TileLike X) : Set (Θ X) := x.2

@[simp] lemma TileLike.fst_mk (x : Grid X) (y : Set (Θ X)) : TileLike.fst (x, y) = x := by
  sorry
@[simp] lemma TileLike.snd_mk (x : Grid X) (y : Set (Θ X)) : TileLike.snd (x, y) = y := by
  sorry

instance : PartialOrder (TileLike X) := by dsimp [TileLike]; infer_instance

lemma TileLike.le_def (x y : TileLike X) : x ≤ y ↔ x.fst ≤ y.fst ∧ y.snd ⊆ x.snd := by
  sorry

def toTileLike (p : 𝔓 X) : TileLike X := (𝓘 p, Ω p)

@[simp] lemma toTileLike_fst (p : 𝔓 X) : (toTileLike p).fst = 𝓘 p := by
  sorry
@[simp] lemma toTileLike_snd (p : 𝔓 X) : (toTileLike p).snd = Ω p := by
  sorry

/-- This is not defined as such in the blueprint, but `λp ≲ λ'p'` can be written using
`smul l p ≤ smul l' p'`.
Beware: `smul 1 p` is very different from `toTileLike p`. -/
def smul (l : ℝ) (p : 𝔓 X) : TileLike X :=
  (𝓘 p, ball_(p) (𝒬 p) l)

@[simp] lemma smul_fst (l : ℝ) (p : 𝔓 X) : (smul l p).fst = 𝓘 p := by
  sorry
@[simp] lemma smul_snd (l : ℝ) (p : 𝔓 X) : (smul l p).snd = ball_(p) (𝒬 p) l := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma smul_mono_left {l l' : ℝ} {p : 𝔓 X} (h : l ≤ l') : smul l' p ≤ smul l p := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma smul_le_toTileLike : smul 1 p ≤ toTileLike p := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma toTileLike_le_smul : toTileLike p ≤ smul 5⁻¹ p := by
  sorry

lemma 𝒬_mem_Ω : 𝒬 p ∈ Ω p := by
  sorry

lemma 𝒬_inj {p' : 𝔓 X} (h : 𝒬 p = 𝒬 p') (h𝓘 : 𝓘 p = 𝓘 p') : p = p' := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma toTileLike_injective : Injective (fun p : 𝔓 X ↦ toTileLike p) := by
  sorry

instance : PartialOrder (𝔓 X) := PartialOrder.lift toTileLike toTileLike_injective

lemma 𝔓.le_def {p q : 𝔓 X} : p ≤ q ↔ toTileLike p ≤ toTileLike q := by
  sorry
lemma 𝔓.le_def' {p q : 𝔓 X} : p ≤ q ↔ 𝓘 p ≤ 𝓘 q ∧ Ω q ⊆ Ω p := by
  sorry

/-- Deduce an inclusion of tiles from an inclusion of their cubes and
non-disjointness of their `Ω`s. -/
lemma tile_le_of_cube_le_and_not_disjoint {p q : 𝔓 X} (hi : 𝓘 p ≤ 𝓘 q)
    {x : Θ X} (mxp : x ∈ Ω p) (mxq : x ∈ Ω q) : p ≤ q := by
  sorry

lemma dist_𝒬_lt_one_of_le {p q : 𝔓 X} (h : p ≤ q) : dist_(p) (𝒬 q) (𝒬 p) < 1 := by
  sorry

lemma dist_𝒬_lt_one_of_le' {p q : 𝔓 X} (h : p ≤ q) : dist_(p) (𝒬 p) (𝒬 q) < 1 := by
  sorry

lemma 𝓘_strictMono : StrictMono (𝓘 (X := X)) := by
  sorry

/-- Lemma 5.3.1 -/
lemma smul_mono {m m' n n' : ℝ} (hp : smul n p ≤ smul m p') (hm : m' ≤ m) (hn : n ≤ n') :
    smul n' p ≤ smul m' p' := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Lemma 5.3.2 (generalizing `1` to `k > 0`) -/
lemma smul_C2_1_2 (m : ℝ) {n k : ℝ} (hk : 0 < k) (hp : 𝓘 p ≠ 𝓘 p') (hl : smul n p ≤ smul k p') :
    smul (n + C2_1_2 a * m) p ≤ smul m p' := by
  sorry

lemma dist_LTSeries {n : ℕ} {u : Set (𝔓 X)} {s : LTSeries u} (hs : s.length = n) {f g : Θ X} :
    dist_(s.head.1) f g ≤ C2_1_2 a ^ n * dist_(s.last.1) f g := by
  sorry

end

/-- The constraint on `λ` in the first part of Lemma 5.3.3. -/
def C5_3_3 (a : ℕ) : ℝ := (1 - C2_1_2 a)⁻¹

include q K σ₁ σ₂ F G in
lemma C5_3_3_le : C5_3_3 a ≤ 11 / 10 := by
  sorry

variable [TileStructure Q D κ S o] {p p' : 𝔓 X} {f g : Θ X}

/-- Lemma 5.3.3, Equation (5.3.3) -/
lemma wiggle_order_11_10 {n : ℝ} (hp : p ≤ p') (hn : C5_3_3 a ≤ n) : smul n p ≤ smul n p' := by
  sorry

/-- Lemma 5.3.3, Equation (5.3.4) -/
lemma wiggle_order_100 (hp : smul 10 p ≤ smul 1 p') (hn : 𝓘 p ≠ 𝓘 p') :
    smul 100 p ≤ smul 100 p' := by
  sorry

/-- Lemma 5.3.3, Equation (5.3.5) -/
lemma wiggle_order_500 (hp : smul 2 p ≤ smul 1 p') (hn : 𝓘 p ≠ 𝓘 p') :
    smul 4 p ≤ smul 500 p' := by
  sorry

def C5_3_2 (a : ℕ) : ℝ := 2 ^ (-95 * (a : ℝ))

def TileLike.toTile (t : TileLike X) : Set (X × Θ X) :=
  (t.fst : Set X) ×ˢ t.snd

/-- From a TileLike, we can construct a set. This is used in the definitions `E₁` and `E₂`. -/
def TileLike.toSet (t : TileLike X) : Set X :=
  t.fst ∩ G ∩ Q ⁻¹' t.snd

def E₁ (p : 𝔓 X) : Set X :=
  (toTileLike p).toSet

def E₂ (l : ℝ) (p : 𝔓 X) : Set X :=
  (smul l p).toSet

lemma E₁_subset (p : 𝔓 X) : E₁ p ⊆ 𝓘 p := by
  sorry

lemma E₂_subset (l : ℝ) (p : 𝔓 X) : E₂ l p ⊆ 𝓘 p := by
  sorry

lemma E₂_mono {p : 𝔓 X} : Monotone fun l ↦ E₂ l p := by
  sorry

/-- `𝔓(𝔓')` in the blueprint.
The set of all tiles whose cubes are less than the cube of some tile in the given set. -/
def lowerCubes (𝔓' : Set (𝔓 X)) : Set (𝔓 X) :=
  {p | ∃ p' ∈ 𝔓', 𝓘 p ≤ 𝓘 p'}

lemma mem_lowerCubes {𝔓' : Set (𝔓 X)} : p ∈ lowerCubes 𝔓' ↔ ∃ p' ∈ 𝔓', 𝓘 p ≤ 𝓘 p' := by
  sorry

lemma lowerCubes_mono : Monotone (lowerCubes (X := X)) := by
  sorry

lemma subset_lowerCubes {𝔓' : Set (𝔓 X)} : 𝔓' ⊆ lowerCubes 𝔓' := by
  sorry

/-- This density is defined to live in `ℝ≥0∞`. Use `ENNReal.toReal` to get a real number. -/
def dens₁ (𝔓' : Set (𝔓 X)) : ℝ≥0∞ :=
  ⨆ (p' ∈ 𝔓') (l ≥ (2 : ℝ≥0)), l ^ (-a : ℝ) *
    ⨆ (p ∈ lowerCubes 𝔓') (_h2 : smul l p' ≤ smul l p),
      volume (E₂ l p) / volume (𝓘 p : Set X)

lemma dens₁_mono {𝔓₁ 𝔓₂ : Set (𝔓 X)} (h : 𝔓₁ ⊆ 𝔓₂) :
    dens₁ 𝔓₁ ≤ dens₁ 𝔓₂ := by
  sorry

/-- This density is defined to live in `ℝ≥0∞`. Use `ENNReal.toReal` to get a real number. -/
def dens₂ (𝔓' : Set (𝔓 X)) : ℝ≥0∞ :=
  ⨆ (p ∈ 𝔓') (r ≥ 4 * (D ^ 𝔰 p : ℝ)),
    volume (F ∩ ball (𝔠 p) r) / volume (ball (𝔠 p) r)

lemma le_dens₂ (𝔓' : Set (𝔓 X)) {p : 𝔓 X} (hp : p ∈ 𝔓') {r : ℝ} (hr : r ≥ 4 * (D ^ 𝔰 p : ℝ)) :
    volume (F ∩ ball (𝔠 p) r) / volume (ball (𝔠 p) r) ≤ dens₂ 𝔓' := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma dens₂_eq_biSup_dens₂ (𝔓' : Set (𝔓 X)) :
    dens₂ (𝔓') = ⨆ (p ∈ 𝔓'), dens₂ ({p}) := by
  sorry

/- A rough estimate. It's also less than 2 ^ (-a) -/
lemma dens₁_le_one {𝔓' : Set (𝔓 X)} : dens₁ 𝔓' ≤ 1 := by
  sorry

lemma volume_E₂_le_dens₁_mul_volume {𝔓' : Set (𝔓 X)} (mp : p ∈ lowerCubes 𝔓') (mp' : p' ∈ 𝔓')
    {l : ℝ≥0} (hl : 2 ≤ l) (sp : smul l p' ≤ smul l p) :
    volume (E₂ l p) ≤ l ^ a * dens₁ 𝔓' * volume (𝓘 p : Set X) := by
  sorry

/-! ### Stack sizes -/

variable {C C' : Set (𝔓 X)} {x x' : X}

open scoped Classical in
/-- The number of tiles `p` in `s` whose underlying cube `𝓘 p` contains `x`. -/
def stackSize (C : Set (𝔓 X)) (x : X) : ℕ :=
  ∑ p with p ∈ C, (𝓘 p : Set X).indicator 1 x

lemma stackSize_setOf_add_stackSize_setOf_not {P : 𝔓 X → Prop} :
    stackSize {p ∈ C | P p} x + stackSize {p ∈ C | ¬P p} x = stackSize C x := by
  sorry

lemma stackSize_inter_add_stackSize_sdiff :
    stackSize (C ∩ C') x + stackSize (C \ C') x = stackSize C x := by
  sorry

lemma stackSize_sdiff_eq (x : X) :
    stackSize (C \ C') x = stackSize C x - stackSize (C ∩ C') x := by
  sorry

lemma stackSize_congr (h : ∀ p ∈ C, x ∈ (𝓘 p : Set X) ↔ x' ∈ (𝓘 p : Set X)) :
    stackSize C x = stackSize C x' := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma stackSize_mono (h : C ⊆ C') : stackSize C x ≤ stackSize C' x := by
  sorry

set_option backward.isDefEq.respectTransparency false in
open scoped Classical in
-- Simplify the cast of `stackSize C x` from `ℕ` to `ℝ`
lemma stackSize_real (C : Set (𝔓 X)) (x : X) :
    (stackSize C x : ℝ) = ∑ p with p ∈ C, (𝓘 p : Set X).indicator (1 : X → ℝ) x := by
  sorry

lemma stackSize_measurable : Measurable fun x ↦ (stackSize C x : ℝ≥0∞) := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma stackSize_le_one_of_pairwiseDisjoint {C : Set (𝔓 X)} {x : X}
    (h : C.PairwiseDisjoint (fun p ↦ (𝓘 p : Set X))) : stackSize C x ≤ 1 := by
  sorry

lemma eq_empty_of_forall_stackSize_zero (s : Set (𝔓 X)) :
    (∀ x, stackSize s x = 0) → s = ∅ := by
  sorry

/-! ### Decomposing a set of tiles into disjoint subfamilies -/

set_option backward.isDefEq.respectTransparency false in
/-- Given any family of tiles, one can extract a maximal disjoint subfamily, covering everything. -/
lemma exists_maximal_disjoint_covering_subfamily (A : Set (𝔓 X)) :
    ∃ (B : Set (𝔓 X)), B.PairwiseDisjoint (fun p ↦ (𝓘 p : Set X)) ∧
      B ⊆ A ∧ (∀ a ∈ A, ∃ b ∈ B, (𝓘 a : Set X) ⊆ 𝓘 b) := by
  sorry

/-- A disjoint subfamily of `A` covering everything. -/
def maximalSubfamily (A : Set (𝔓 X)) : Set (𝔓 X) :=
  (exists_maximal_disjoint_covering_subfamily A).choose

/-- Iterating `maximalSubfamily` to obtain disjoint subfamilies of `A`. -/
def iteratedMaximalSubfamily (A : Set (𝔓 X)) (n : ℕ) : Set (𝔓 X) :=
  maximalSubfamily (A \ (⋃ (i : {i | i < n}), have : i < n := i.2; iteratedMaximalSubfamily A i))

lemma pairwiseDisjoint_iteratedMaximalSubfamily_image (A : Set (𝔓 X)) (n : ℕ) :
    (iteratedMaximalSubfamily A n).PairwiseDisjoint (fun p ↦ (𝓘 p : Set X)) := by
  sorry

lemma iteratedMaximalSubfamily_subset (A : Set (𝔓 X)) (n : ℕ) :
    iteratedMaximalSubfamily A n ⊆ A := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma pairwiseDisjoint_iteratedMaximalSubfamily (A : Set (𝔓 X)) :
    univ.PairwiseDisjoint (iteratedMaximalSubfamily A) := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Any set of tiles can be written as the union of disjoint subfamilies, their number being
controlled by the maximal stack size. -/
lemma eq_biUnion_iteratedMaximalSubfamily (A : Set (𝔓 X)) {N : ℕ} (hN : ∀ x, stackSize A x ≤ N) :
    A = ⋃ n < N, iteratedMaximalSubfamily A n := by
  sorry
