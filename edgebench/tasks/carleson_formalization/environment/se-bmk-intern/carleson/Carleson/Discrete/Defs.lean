module

public import Carleson.TileStructure
public import Carleson.ToMathlib.MinLayer

@[expose] public section

open MeasureTheory Measure NNReal Metric Set
open scoped ENNReal
noncomputable section

open scoped ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]

def aux𝓒 (k : ℕ) : Set (Grid X) :=
  {i : Grid X | ∃ j : Grid X, i ≤ j ∧ 2 ^ (-k : ℤ) * volume (j : Set X) < volume (G ∩ j) }

/-- The partition `𝓒(G, k)` of `Grid X` by volume, given in (5.1.1) and (5.1.2).
Note: the `G` is fixed with properties in `ProofData`. -/
def 𝓒 (k : ℕ) : Set (Grid X) :=
  aux𝓒 (k + 1) \ aux𝓒 k

/-- The definition `𝔓(k)` given in (5.1.3). -/
def TilesAt (k : ℕ) : Set (𝔓 X) := 𝓘 ⁻¹' 𝓒 k

lemma disjoint_TilesAt_of_ne {m n : ℕ} (h : m ≠ n) : Disjoint (TilesAt (X := X) m) (TilesAt n) := by
  sorry

lemma pairwiseDisjoint_TilesAt : univ.PairwiseDisjoint (TilesAt (X := X)) := by
  sorry

def aux𝔐 (k n : ℕ) : Set (𝔓 X) :=
  {p ∈ TilesAt k | 2 ^ (-n : ℤ) * volume (𝓘 p : Set X) < volume (E₁ p) }

/-- The definition `𝔐(k, n)` given in (5.1.4) and (5.1.5). -/
def 𝔐 (k n : ℕ) : Set (𝔓 X) := {m | Maximal (· ∈ aux𝔐 k n) m}

/-- The definition `dens'_k(𝔓')` given in (5.1.6). -/
def dens' (k : ℕ) (P' : Set (𝔓 X)) : ℝ≥0∞ :=
  ⨆ p' ∈ P', ⨆ (l : ℝ≥0), ⨆ (_hl : 2 ≤ l),
  ⨆ (p : 𝔓 X) (_h1p : p ∈ TilesAt k) (_h2p : smul l p' ≤ smul l p),
  l ^ (-a : ℤ) * volume (E₂ l p) / volume (𝓘 p : Set X)

lemma dens'_iSup {k : ℕ} {P : Set (𝔓 X)} : dens' k P = ⨆ p ∈ P, dens' k {p} := by
  sorry

def auxℭ (k n : ℕ) : Set (𝔓 X) :=
  { p ∈ TilesAt k | 2 ^ (4 * a - n) < dens' k {p} }

/-- The partition `ℭ(k, n)` of `𝔓(k)` by density, given in (5.1.7). -/
def ℭ (k n : ℕ) : Set (𝔓 X) :=
  { p ∈ TilesAt k | dens' k {p} ∈ Ioc (2 ^ (4 * a - n : ℤ)) (2 ^ (4 * a - n + 1 : ℤ)) }

lemma ℭ_subset_TilesAt {k n : ℕ} : ℭ k n ⊆ TilesAt (X := X) k := by
  sorry

lemma disjoint_ℭ_of_ne {k m n : ℕ} (h : m ≠ n) : Disjoint (ℭ (X := X) k m) (ℭ k n) := by
  sorry

lemma pairwiseDisjoint_ℭ :
    (univ : Set (ℕ × ℕ)).PairwiseDisjoint (fun kn ↦ ℭ (X := X) kn.1 kn.2) := by
  sorry

lemma exists_bound_ℭ : ∃ (n : ℕ × ℕ),
    ∀ x ∈ {kn : ℕ × ℕ | (ℭ (X := X) kn.1 kn.2).Nonempty}, Prod.snd x ≤ Prod.snd n := by
  sorry

variable (X) in
def maxℭ : ℕ := (exists_bound_ℭ (X := X)).choose.2

lemma le_maxℭ_of_nonempty {k n : ℕ} (h : (ℭ (X := X) k n).Nonempty) : n ≤ maxℭ X := by
  sorry

lemma eq_empty_of_maxℭ_lt {k n : ℕ} (hn : maxℭ X < n) : ℭ (X := X) k n = ∅ := by
  sorry

/-- Lemma 5.3.11 -/
lemma dens1_le_dens' {k : ℕ} {P : Set (𝔓 X)} (hP : P ⊆ TilesAt k) : dens₁ P ≤ dens' k P := by
  sorry

/-- Lemma 5.3.12 -/
lemma dens1_le {k n : ℕ} {A : Set (𝔓 X)} (hA : A ⊆ ℭ k n) : dens₁ A ≤ 2 ^ (4 * (a : ℝ) - n + 1) := by
  sorry

/-- The subset `𝔅(p)` of `𝔐(k, n)`, given in (5.1.8). -/
def 𝔅 (k n : ℕ) (p : 𝔓 X) : Set (𝔓 X) :=
  { m ∈ 𝔐 k n | smul 100 p ≤ smul 1 m }

open scoped Classical in
def preℭ₁ (k n j : ℕ) : Set (𝔓 X) :=
  { p ∈ ℭ k n | 2 ^ j ≤ Finset.card { q | q ∈ 𝔅 k n p } }

/-- The subset `ℭ₁(k, n, j)` of `ℭ(k, n)`, given in (5.1.9).
Together with `𝔏₀(k, n)` this forms a partition. -/
def ℭ₁ (k n j : ℕ) : Set (𝔓 X) :=
  preℭ₁ k n j \ preℭ₁ k n (j + 1)

lemma ℭ₁_subset_ℭ {k n j : ℕ} : ℭ₁ k n j ⊆ ℭ (X := X) k n := by
  sorry

lemma disjoint_ℭ₁_of_ne {k n j l : ℕ} (h : j ≠ l) : Disjoint (ℭ₁ (X := X) k n j) (ℭ₁ k n l) := by
  sorry

lemma pairwiseDisjoint_ℭ₁ {k n : ℕ} : univ.PairwiseDisjoint (ℭ₁ (X := X) k n) := by
  sorry

lemma pairwiseDisjoint_ℭ₁' :
    (univ : Set (ℕ × ℕ × ℕ)).PairwiseDisjoint (fun knj ↦ ℭ₁ (X := X) knj.1 knj.2.1 knj.2.2) := by
  sorry

lemma card_𝔅_of_mem_ℭ₁ {k n j : ℕ} {p : 𝔓 X} (hp : p ∈ ℭ₁ k n j) [Fintype (𝔅 k n p)] :
    (𝔅 k n p).toFinset.card ∈ Ico (2 ^ j) (2 ^ (j + 1)) := by
  sorry

/-- The subset `𝔏₀(k, n)` of `ℭ(k, n)`, given in (5.1.10).
Not to be confused with `𝔏₀(k, n, j)` which is called `𝔏₀'` in Lean. -/
def 𝔏₀ (k n : ℕ) : Set (𝔓 X) :=
  { p ∈ ℭ k n | 𝔅 k n p = ∅ }

/-- `𝔏₁(k, n, j, l)` consists of the minimal elements in `ℭ₁(k, n, j)` not in
  `𝔏₁(k, n, j, l')` for some `l' < l`. Defined near (5.1.11). -/
def 𝔏₁ (k n j l : ℕ) : Set (𝔓 X) :=
  (ℭ₁ k n j).minLayer l

/-- The subset `ℭ₂(k, n, j)` of `ℭ₁(k, n, j)`, given in (5.1.13). -/
def ℭ₂ (k n j : ℕ) : Set (𝔓 X) :=
  (ℭ₁ k n j).layersAbove (Z * (n + 1))

lemma ℭ₂_subset_ℭ₁ {k n j : ℕ} : ℭ₂ k n j ⊆ ℭ₁ (X := X) k n j := by
  sorry

/-- The subset `𝔘₁(k, n, j)` of `ℭ₁(k, n, j)`, given in (5.1.14). -/
def 𝔘₁ (k n j : ℕ) : Set (𝔓 X) :=
  { u ∈ ℭ₁ k n j | ∀ p ∈ ℭ₁ k n j, 𝓘 u < 𝓘 p → Disjoint (ball_(u) (𝒬 u) 100) (ball_(p) (𝒬 p) 100) }

lemma 𝔘₁_subset_ℭ₁ {k n j : ℕ} : 𝔘₁ k n j ⊆ ℭ₁ (X := X) k n j := by
  sorry

/-- The subset `𝔏₂(k, n, j)` of `ℭ₂(k, n, j)`, given in (5.1.15). -/
def 𝔏₂ (k n j : ℕ) : Set (𝔓 X) :=
  { p ∈ ℭ₂ k n j | ¬ ∃ u ∈ 𝔘₁ k n j, 𝓘 p ≠ 𝓘 u ∧ smul 2 p ≤ smul 1 u }

lemma 𝔏₂_subset_ℭ₂ {k n j : ℕ} : 𝔏₂ k n j ⊆ ℭ₂ (X := X) k n j := by
  sorry

/-- The subset `ℭ₃(k, n, j)` of `ℭ₂(k, n, j)`, given in (5.1.16). -/
def ℭ₃ (k n j : ℕ) : Set (𝔓 X) :=
  ℭ₂ k n j \ 𝔏₂ k n j

lemma ℭ₃_def {k n j : ℕ} {p : 𝔓 X} :
    p ∈ ℭ₃ k n j ↔ p ∈ ℭ₂ k n j ∧ ∃ u ∈ 𝔘₁ k n j, 𝓘 p ≠ 𝓘 u ∧ smul 2 p ≤ smul 1 u := by
  sorry

lemma ℭ₃_subset_ℭ₂ {k n j : ℕ} : ℭ₃ k n j ⊆ ℭ₂ (X := X) k n j := by
  sorry

/-- `𝔏₃(k, n, j, l)` consists of the maximal elements in `ℭ₃(k, n, j)` not in
  `𝔏₃(k, n, j, l')` for some `l' < l`. Defined near (5.1.17). -/
def 𝔏₃ (k n j l : ℕ) : Set (𝔓 X) :=
 (ℭ₃ k n j).maxLayer l

/-- The subset `ℭ₄(k, n, j)` of `ℭ₃(k, n, j)`, given in (5.1.19). -/
def ℭ₄ (k n j : ℕ) : Set (𝔓 X) :=
  (ℭ₃ k n j).layersBelow (Z * (n + 1))

lemma ℭ₄_subset_ℭ₃ {k n j : ℕ} : ℭ₄ k n j ⊆ ℭ₃ (X := X) k n j := by
  sorry

/-- The subset `𝓛(u)` of `Grid X`, given near (5.1.20).
Note: It seems to also depend on `n`. -/
def 𝓛 (n : ℕ) (u : 𝔓 X) : Set (Grid X) :=
  { i : Grid X | i ≤ 𝓘 u ∧ s i + (Z * (n + 1) : ℕ) + 1 = 𝔰 u ∧ ¬ ball (c i) (8 * D ^ s i) ⊆ 𝓘 u }

/-- The subset `𝔏₄(k, n, j)` of `ℭ₄(k, n, j)`, given near (5.1.22).
Todo: we may need to change the definition to say that `p`
is at most the least upper bound of `𝓛 n u` in `Grid X`. -/
def 𝔏₄ (k n j : ℕ) : Set (𝔓 X) :=
  { p ∈ ℭ₄ k n j | ∃ u ∈ 𝔘₁ k n j, (𝓘 p : Set X) ⊆ ⋃ (i ∈ 𝓛 (X := X) n u), i }

lemma 𝔏₄_subset_ℭ₄ {k n j : ℕ} : 𝔏₄ k n j ⊆ ℭ₄ (X := X) k n j := by
  sorry

/-- The subset `ℭ₅(k, n, j)` of `ℭ₄(k, n, j)`, given in (5.1.23). -/
def ℭ₅ (k n j : ℕ) : Set (𝔓 X) :=
  ℭ₄ k n j \ 𝔏₄ k n j

lemma ℭ₅_def {k n j : ℕ} {p : 𝔓 X} :
    p ∈ ℭ₅ k n j ↔ p ∈ ℭ₄ k n j ∧ ∀ u ∈ 𝔘₁ k n j, ¬(𝓘 p : Set X) ⊆ ⋃ (i ∈ 𝓛 (X := X) n u), i := by
  sorry

lemma ℭ₅_subset_ℭ₄ {k n j : ℕ} : ℭ₅ k n j ⊆ ℭ₄ (X := X) k n j := by
  sorry

lemma ℭ₅_subset_ℭ₁ {k n j : ℕ} : ℭ₅ k n j ⊆ ℭ₁ (X := X) k n j := by
  sorry

lemma pairwiseDisjoint_ℭ₅ :
    (univ : Set (ℕ × ℕ × ℕ)).PairwiseDisjoint (fun knj ↦ ℭ₅ (X := X) knj.1 knj.2.1 knj.2.2) := by
  sorry

-- These inclusion and disjointness lemmas are only used in `antichain_decomposition`
section AntichainDecomp

variable {k n j l : ℕ}

lemma 𝔏₀_subset_ℭ : 𝔏₀ (X := X) k n ⊆ ℭ k n := by
  sorry
lemma 𝔏₀_disjoint_ℭ₁ : Disjoint (𝔏₀ (X := X) k n) (ℭ₁ k n j) := by
  sorry

lemma 𝔏₁_subset_ℭ₁ : 𝔏₁ (X := X) k n j l ⊆ ℭ₁ k n j := by
  sorry
lemma 𝔏₁_subset_ℭ : 𝔏₁ (X := X) k n j l ⊆ ℭ k n := by
  sorry

lemma 𝔏₂_subset_ℭ₁ : 𝔏₂ k n j ⊆ ℭ₁ (X := X) k n j := by
  sorry
lemma 𝔏₂_subset_ℭ : 𝔏₂ k n j ⊆ ℭ (X := X) k n := by
  sorry
lemma 𝔏₂_disjoint_ℭ₃ : Disjoint (𝔏₂ (X := X) k n j) (ℭ₃ k n j) := by
  sorry

lemma 𝔏₃_subset_ℭ₁ : 𝔏₃ k n j l ⊆ ℭ₁ (X := X) k n j := by
  sorry
lemma 𝔏₃_subset_ℭ : 𝔏₃ k n j l ⊆ ℭ (X := X) k n := by
  sorry

lemma 𝔏₄_subset_ℭ₁ : 𝔏₄ k n j ⊆ ℭ₁ (X := X) k n j := by
  sorry
lemma 𝔏₄_subset_ℭ : 𝔏₄ k n j ⊆ ℭ (X := X) k n := by
  sorry

lemma ℭ₅_subset_ℭ : ℭ₅ k n j ⊆ ℭ (X := X) k n := by
  sorry

end AntichainDecomp

/-- The set $\mathcal{P}_{F,G}$, defined in (5.1.24). -/
def highDensityTiles : Set (𝔓 X) :=
  { p : 𝔓 X | 2 ^ (2 * a + 5) * volume F / volume G < dens₂ {p} }

lemma highDensityTiles_empty (hF : volume F = 0) : highDensityTiles = (∅ : Set (𝔓 X)) := by
  sorry

lemma highDensityTiles_empty' (hG : volume G = 0) :
    highDensityTiles = (∅ : Set (𝔓 X)) := by
  sorry

/-- The exceptional set `G₁`, defined in (5.1.25). -/
def G₁ : Set X := ⋃ (p : 𝔓 X) (_ : p ∈ highDensityTiles), 𝓘 p

lemma G₁_empty (hF : volume F = 0) : G₁ = (∅ : Set X) := by
  sorry

lemma G₁_empty' (hG : volume G = 0) : G₁ = (∅ : Set X) := by
  sorry

lemma measurable_G₁ : MeasurableSet (G₁ (X := X)) := by
  sorry

/-- The set `A(λ, k, n)`, defined in (5.1.26). -/
def setA (l k n : ℕ) : Set X :=
  {x : X | l * 2 ^ (n + 1) < stackSize (𝔐 (X := X) k n) x }

lemma setA_subset_iUnion_𝓒 {l k n : ℕ} :
    setA (X := X) l k n ⊆ ⋃ i ∈ 𝓒 (X := X) k, i := by
  sorry

lemma setA_subset_setA {l k n : ℕ} : setA (X := X) (l + 1) k n ⊆ setA l k n := by
  sorry

lemma measurable_setA {l k n : ℕ} : MeasurableSet (setA (X := X) l k n) := by
  sorry

open scoped Classical in
/-- Finset of cubes in `setA`. Appears in the proof of Lemma 5.2.5. -/
def MsetA (l k n : ℕ) : Finset (Grid X) := { j | (j : Set X) ⊆ setA l k n }

/-- The set `G₂`, defined in (5.1.27). -/
def G₂ : Set X := ⋃ (n : ℕ) (k ≤ n), setA (2 * n + 6) k n

lemma measurable_G₂ : MeasurableSet (G₂ (X := X)) := by
  sorry

/-- The set `G₃`, defined in (5.1.28). -/
def G₃ : Set X := ⋃ (n : ℕ) (k ≤ n) (j ≤ 2 * n + 3) (p ∈ 𝔏₄ (X := X) k n j), 𝓘 p

lemma measurable_G₃ : MeasurableSet (G₃ (X := X)) := by
  sorry

/-- The set `G'`, defined below (5.1.28). -/
def G' : Set X := G₁ ∪ G₂ ∪ G₃

lemma measurable_G' : MeasurableSet (G' (X := X)) := by
  sorry

/-- The set `𝔓₁`, defined in (5.1.30). -/
def 𝔓₁ : Set (𝔓 X) := ⋃ (n : ℕ) (k ≤ n) (j ≤ 2 * n + 3), ℭ₅ k n j
