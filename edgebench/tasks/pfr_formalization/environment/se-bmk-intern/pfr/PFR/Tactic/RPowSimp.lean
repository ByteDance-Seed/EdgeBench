module

public import Mathlib.Analysis.SpecialFunctions.Pow.Real

public meta section

namespace Mathlib.Tactic
open Lean
open Qq Meta Real

namespace RPowRing
-- open Ring

/-- The read-only state of the `RPowRing` monad. -/
structure Context where
  /-- A basically empty simp context, passed to the `simp` traversal in `RPowRing.rewrite`. -/
  ctx : Simp.Context
  /-- A cleanup routine, which simplifies normalized polynomials to a more human-friendly
  format. -/
  simp : Simp.Result → SimpM Simp.Result

/-- Configuration for `ring_nf`. -/
@[nolint unusedArguments]
structure Config where
  /-- the reducibility setting to use when comparing atoms for defeq -/
  red := TransparencyMode.reducible
  -- /-- if true, atoms inside ring expressions will be reduced recursively -/
  -- recursive := true
  deriving Inhabited, BEq, Repr

/-- Function elaborating `RingNF.Config`. -/
declare_config_elab elabConfig Config

/-- The monad for `RingNF` contains, in addition to the `AtomM` state,
a simp context for the main traversal and a simp function (which has another simp context)
to simplify normalized polynomials. -/
abbrev M := ReaderT Context AtomM

/--
A monomial, which is a product of powers of `ExBase` expressions,
terminated by a (nonzero) constant coefficient.
-/
inductive ExBase : (e : Q(ℝ)) → Type
  /-- A coefficient `value`, which must not be `0`. `e` is a raw rat cast.
  If `value` is not an integer, then `hyp` should be a proof of `(value.den : α) ≠ 0`. -/
  | atom (id : ℕ) (x : Q(ℝ)) : ExBase x
  /-- A product `x ^ e * b` is a monomial if `b` is a monomial. Here `x` is an `ExBase`
  and `e` is an `ExBase` representing a monomial expression in `ℕ` (it is a monomial instead of
  a polynomial because we eagerly normalize `x ^ (a + b) = x ^ a * x ^ b`.) -/
  | pow (id : ℕ) (x : Q(ℝ)) (h : Q(0 < $x)) (e : Q(ℝ)) : ExBase q($x ^ $e)

def ExBase.id {e : Q(ℝ)} : ExBase e → ℕ
  | .atom id .. | .pow id .. => id

/--
A monomial, which is a product of powers of `ExBase` expressions,
terminated by a (nonzero) constant coefficient.
-/
inductive ExProd : (e : Q(ℝ)) → Type
  /-- A coefficient `value`, which must not be `0`. `e` is a raw rat cast.
  If `value` is not an integer, then `hyp` should be a proof of `(value.den : α) ≠ 0`. -/
  | one : ExProd q(1)
  /-- A product `x ^ e * b` is a monomial if `b` is a monomial. Here `x` is an `ExBase`
  and `e` is an `ExProd` representing a monomial expression in `ℕ` (it is a monomial instead of
  a polynomial because we eagerly normalize `x ^ (a + b) = x ^ a * x ^ b`.) -/
  | mul {x b : Q(ℝ)} : ExBase x → ExProd b → ExProd q($x * $b)

instance : Inhabited (Σ e, ExBase e) := ⟨_, .atom 0 default⟩
instance : Inhabited (Σ e, ExProd e) := ⟨_, .one⟩

/-- Embed an exponent (an `ExBase, ExProd` pair) as an `ExProd` by multiplying by 1. -/
def ExBase.toProd {a : Q(ℝ)} (va : ExBase a) : ExProd q($a * 1) := .mul va .one

nonrec abbrev Result := Ring.Result (u := .zero) (α := q(ℝ))

instance (e : Q(ℝ)) : Inhabited (Result ExProd e) :=
  inferInstanceAs (Inhabited (Ring.Result ExProd e))

theorem atom_pf (a : ℝ) : a = a * 1 := by simp
theorem atom_pf' {a a' : ℝ} (p : a = a') : a = a * 1 := by simp [*]
theorem atom_pow_pf (a : ℝ) : a = a ^ (1 : ℝ) * 1 := by simp
theorem atom_pow_pf' {a a' : ℝ} (p : (a : ℝ) = a') : a = a ^ 1 * 1 := by simp [*]

/--
Evaluates an atom, an expression where `ring` can find no additional structure.

* `a = a ^ 1 * 1 + 0`
-/
def evalAtom (e : Q(ℝ)) : AtomM (Result ExProd e) := do
  let r ← (← read).evalAtom e
  have a : Q(ℝ) := r.expr
  let (i, _) ← AtomM.addAtom a
  match ← Positivity.catchNone <| Positivity.core q(inferInstance) q(inferInstance) a, r.proof? with
  | .positive pa, none =>
    pure ⟨_, (ExBase.pow i a pa q(1)).toProd, (q(atom_pow_pf $e) : Expr)⟩
  | .positive pa, some (p : Q($e = $a)) =>
    pure ⟨_, (ExBase.pow i a pa q(1)).toProd, (q(atom_pow_pf' $p) : Expr)⟩
  | _, none => pure ⟨_, (ExBase.atom i a).toProd, (q(atom_pf $e) : Expr)⟩
  | _, some (p : Q($e = $a)) => pure ⟨_, (ExBase.atom i a).toProd, (q(atom_pf' $p) : Expr)⟩

theorem mul_pf_left {a₂ b c : ℝ} (a₁ : ℝ) (_ : a₂ * b = c) : (a₁ * a₂ : ℝ) * b = a₁ * c := by
  subst_vars; rw [mul_assoc]

theorem mul_pf_right {a b₂ c : ℝ} (b₁ : ℝ) (_ : a * b₂ = c) : a * (b₁ * b₂) = b₁ * c := by
  subst_vars; rw [mul_left_comm]

theorem mul_pp_pf_overlap {a₂ b₂ c x : ℝ} (ea eb : ℝ) (h : 0 < x) (_ : a₂ * b₂ = c) :
    (x ^ ea * a₂ : ℝ) * (x ^ eb * b₂) = x ^ (ea + eb) * c := by
  subst_vars; rw [rpow_add h, mul_mul_mul_comm]

/-- Multiplies two monomials `va, vb` together to get a normalized result monomial.

* `x * y = (x * y)` (for `x`, `y` coefficients)
* `x * (b₁ * b₂) = b₁ * (b₂ * x)` (for `x` coefficient)
* `(a₁ * a₂) * y = a₁ * (a₂ * y)` (for `y` coefficient)
* `(x ^ ea * a₂) * (x ^ eb * b₂) = x ^ (ea + eb) * (a₂ * b₂)`
    (if `ea` and `eb` are identical except coefficient)
* `(a₁ * a₂) * (b₁ * b₂) = a₁ * (a₂ * (b₁ * b₂))` (if `a₁.lt b₁`)
* `(a₁ * a₂) * (b₁ * b₂) = b₁ * ((a₁ * a₂) * b₂)` (if not `a₁.lt b₁`)
-/
partial def evalMul {a b : Q(ℝ)} (va : ExProd a) (vb : ExProd b) : Result ExProd q($a * $b) :=
  match va, vb with
  | .one, vb => ⟨b, vb, q(one_mul $b)⟩
  | va, .one => ⟨a, va, q(mul_one $a)⟩
  | .mul (x := ax) (b := ab) vax vab, .mul (x := bx) (b := bb) vbx vbb => Id.run do
    have els (_ : Unit) : Result ExProd q($ax * $ab * ($bx * $bb)) :=
      if vax.id < vbx.id then
        let ⟨_, vc, pc⟩ := evalMul vab vb
        ⟨_, .mul vax vc, (q(mul_pf_left $ax $pc) : Expr)⟩
      else
        let ⟨_, vc, pc⟩ := evalMul va vbb
        ⟨_, .mul vbx vc, (q(mul_pf_right $bx $pc) : Expr)⟩
    let .pow ai ax ah ae := vax | els ()
    let .pow bi _ _ be := vbx | els ()
    unless ai = bi do return els ()
    let ⟨_, vc, pc⟩ := evalMul vab vbb
    ⟨_, .mul (.pow ai ax ah q($ae + $be)) vc, (q(mul_pp_pf_overlap $ae $be $ah $pc) : Expr)⟩

theorem pow_pos {a b e : ℝ} (ha : 0 < a) (hb : 0 < b) : 0 < a ^ e * b :=
  mul_pos (rpow_pos_of_pos ha e) hb

theorem pow_pf {a b b' e₁ e₂ : ℝ} (ha : 0 < a) (hb : 0 < b) (_ : b ^ e₂ = b') :
    (a ^ e₁ * b) ^ e₂ = a ^ (e₁ * e₂) * b' := by
  subst_vars; rw [mul_rpow (rpow_pos_of_pos ha e₁).le hb.le, rpow_mul ha.le]

def evalPow {a : Q(ℝ)} (va : ExProd a) (e : Q(ℝ)) : Option (Q(0 < $a) × Result ExProd q($a ^ $e)) :=
  match va with
  | .one => some ⟨q(one_pos), _, .one, q(one_rpow _)⟩
  | .mul (x := x) vx vb =>
    match x, vx with
    | _, .atom .. => none
    | _, .pow i x hx e₁ => do
      let ⟨hb, _, vc, pc⟩ ← evalPow vb e
      some ⟨q(pow_pos $hx $hb), _, .mul (.pow i x hx q($e₁ * $e)) vc, q(pow_pf $hx $hb $pc)⟩

theorem pow_congr {a a' b c : ℝ} (_ : a = a') (_ : a' ^ b = c) : a ^ b = c := by subst_vars; rfl

theorem inv_congr {a a' b : ℝ} (_ : a = a') (_ : a' ^ (-1 : ℝ) = b) : (a⁻¹ : ℝ) = b := by
  subst_vars; simp [rpow_neg_one]

theorem npow_congr {a a' c : ℝ} {b : ℕ} (_ : a = a') (_ : a' ^ (b : ℝ) = c) :
    Monoid.npow b a = c := by subst_vars; simp [rpow_natCast]

partial def eval (e : Q(ℝ)) : AtomM (Result ExProd e) := Lean.withIncRecDepth do
  let els := evalAtom e
  let .const n _ := (← withReducible <| whnf e).getAppFn | els
  match n with
  | ``HMul.hMul | ``Mul.mul => match e with
    | ~q($a * $b) =>
      let ⟨_, va, pa⟩ ← eval a
      let ⟨_, vb, pb⟩ ← eval b
      let ⟨c, vc, p⟩ := evalMul va vb
      pure ⟨c, vc, (q(Ring.mul_congr $pa $pb $p) : Expr)⟩
    | _ => els
  | ``HPow.hPow | ``Pow.pow => match e with
    | ~q($a ^ ($b : ℝ)) =>
      let ⟨_, va, pa⟩ ← eval a
      let some ⟨_, c, vc, p⟩ := evalPow va b | els
      pure ⟨c, vc, (q(pow_congr $pa $p) : Expr)⟩
    | ~q(Monoid.npow $b $a) =>
      let ⟨_, va, pa⟩ ← eval a
      let some ⟨_, c, vc, p⟩ := evalPow va q($b) | els
      pure ⟨c, vc, (q(npow_congr $pa $p) : Expr)⟩
    | _ => els
  | ``Inv.inv => match e with
    | ~q($a⁻¹) =>
      let ⟨_, va, pa⟩ ← eval a
      let some ⟨_, b, vb, p⟩ := evalPow va q(-1) | els
      pure ⟨b, vb, (q(inv_congr $pa $p) : Expr)⟩
    | _ => els
  | _ => els

def rewrite (parent : Expr) (root := true) : M Simp.Result := fun nctx rctx s ↦
  let pre : Simp.Simproc := fun e =>
    try
      guard <| root || parent != e -- recursion guard
      let e ← withReducible <| whnf e
      guard e.isApp -- all interesting ring expressions are applications
      guard <| ← isDefEq (← inferType e) q(ℝ)
      let ⟨a, _, pa⟩ ← eval e rctx s
      let r ← nctx.simp { expr := a, proof? := pa }
      if ← withReducible <| isDefEq r.expr e then return .done { expr := r.expr }
      pure (.done r)
    catch _ => pure <| .continue
  let post := (Simp.postDefault #[])
  (·.1) <$> Simp.main parent nctx.ctx (methods := { pre, post })

open RingNF in
/--
Runs a tactic in the `RingNF.M` monad, given initial data:

* `s`: a reference to the mutable state of `ring`, for persisting across calls.
  This ensures that atom ordering is used consistently.
* `cfg`: the configuration options
* `x`: the tactic to run
-/
def M.run {α : Type} (s : IO.Ref AtomM.State) (cfg : RPowRing.Config) (x : M α) : MetaM α := do
  let ctx ← Simp.mkContext
    Simp.neutralConfig
    (simpTheorems := #[← Elab.Tactic.simpOnlyBuiltins.foldlM (·.addConst ·) {}])
    (congrTheorems := ← getSimpCongrTheorems)
  let thms : SimpTheorems := {}
  let thms ← [``mul_one, ``one_mul, ``pow_one, ``RingNF.mul_neg, ``RingNF.add_neg
    ].foldlM (·.addConst ·) thms
  let ctx' := ctx.setSimpTheorems #[thms]
  let simp (r' : Simp.Result) := do
    r'.mkEqTrans (← Simp.main r'.expr ctx' (methods := ← Lean.Meta.Simp.mkDefaultMethods)).1
  x { ctx := ← Simp.mkContext
        { Simp.neutralConfig with singlePass := true } ctx.simpTheorems ctx.congrTheorems, simp }
    { red := cfg.red } s

open Elab.Tactic Parser.Tactic
/-- Use `rpow_ring` to rewrite the main goal. -/
def rpowRingTarget (s : IO.Ref AtomM.State) (cfg : Config) : TacticM Unit := withMainContext do
  let goal ← getMainGoal
  let tgt ← instantiateMVars (← goal.getType)
  let r ← M.run s cfg <| rewrite tgt
  if r.expr.consumeMData.isConstOf ``True then
    goal.assign (← mkOfEqTrue (← r.getProof))
    replaceMainGoal []
  else
    replaceMainGoal [← applySimpResultToTarget goal tgt r]

/-- Use `rpow_ring` to rewrite hypothesis `h`. -/
def rpowRingLocalDecl (s : IO.Ref AtomM.State) (cfg : Config) (fvarId : FVarId) :
    TacticM Unit := withMainContext do
  let tgt ← instantiateMVars (← fvarId.getType)
  let goal ← getMainGoal
  let myres ← M.run s cfg <| rewrite tgt
  match ← applySimpResultToLocalDecl goal fvarId myres false with
  | none => replaceMainGoal []
  | some (_, newGoal) => replaceMainGoal [newGoal]

/--
Simplification tactic for expressions in the language of commutative (semi)rings,
which rewrites all ring expressions into a normal form.
* `rpow_ring!` will use a more aggressive reducibility setting to identify atoms.
* `rpow_ring (config := cfg)` allows for additional configuration:
  * `red`: the reducibility setting (overridden by `!`)
  * `recursive`: if true, `rpow_ring` will also recurse into atoms
* `rpow_ring` works as both a tactic and a conv tactic.
  In tactic mode, `rpow_ring at h` can be used to rewrite in a hypothesis.
-/
elab (name := rpowRing) "rpow_ring" tk:"!"? cfg:(config ?) loc:(location)? : tactic => do
  let mut cfg ← elabConfig cfg
  if tk.isSome then cfg := { cfg with red := .default }
  let loc := (loc.map expandLocation).getD (.targets #[] true)
  let s ← IO.mkRef {}
  withLocation loc (rpowRingLocalDecl s cfg) (rpowRingTarget s cfg)
    fun _ ↦ throwError "rpow_ring failed"

@[inherit_doc rpowRing] macro "rpow_ring!" cfg:(config)? loc:(location)? : tactic =>
  `(tactic| rpow_ring ! $(cfg)? $(loc)?)

@[inherit_doc rpowRing] syntax (name := rpowRingConv) "rpow_ring" "!"? (config)? : conv

/-- Elaborator for the `rpow_ring` tactic. -/
@[tactic rpowRingConv] def elabRPowRingConv : Tactic := fun stx ↦ match stx with
  | `(conv| rpow_ring $[!%$tk]? $(_cfg)?) => withMainContext do
    let mut cfg ← elabConfig stx[2]
    if tk.isSome then cfg := { cfg with red := .default }
    let s ← IO.mkRef {}
    Conv.applySimpResult (← M.run s cfg <| rewrite (← instantiateMVars (← Conv.getLhs)))
  | _ => Elab.throwUnsupportedSyntax

theorem _root_.Real.pow_neg (a b : ℝ) (h : 0 ≤ a) : a ^ (-b) = a⁻¹ ^ b := by
  simp [← rpow_neg_one, ← rpow_mul h]

theorem _root_.Real.inv_rpow' {x : ℝ} (hx : 0 ≤ x) (y : ℝ) : x⁻¹ ^ y = x ^ (-y) := by
  simp only [← rpow_neg_one, ← rpow_mul hx, neg_mul, one_mul]

theorem _root_.Real.rpow_inv {x : ℝ} (hx : 0 ≤ x) (y : ℝ) : (x ^ y)⁻¹ = x ^ (-y) := by
  simp [← inv_rpow' hx, inv_rpow hx]

lemma fix_cast₁ : (Int.cast (Int.ofNat 1) : ℝ) = 1 := Int.cast_eq_one.mpr rfl

lemma fix_cast₂ {n : ℕ} : (Int.cast (Int.ofNat n) : ℝ) = n := rfl

lemma fix_cast₃ {n : ℕ} [n.AtLeastTwo] : (Nat.cast n : ℝ) = OfNat.ofNat n := by rfl

open Lean Lean.PrettyPrinter.Delaborator in
@[delab app.OfNat.ofNat] def delab_ofNat := whenPPOption Lean.getPPNotation do
  SubExpr.withNaryArg 1 delab

open Lean Parser Tactic
macro "rpow_simp" loc:(location)? : tactic => `(tactic|
  ((((simp (config := {failIfUnchanged := false}) (discharger := positivity) only
      [abs_one, abs_mul, abs_inv, abs_div, abs_abs, abs_zero, mul_rpow, ← rpow_mul, div_rpow,
       ← rpow_natCast, abs_rpow_of_nonneg, rpow_one, ← rpow_add, ← rpow_sub, zero_rpow, one_rpow,
       rpow_one, inv_rpow', rpow_inv] $(loc)? <;> try push_cast) <;>
   try rpow_ring) <;> try field_simp)) <;>
   try simp (discharger := positivity) only [abs_one, abs_zero, one_rpow, rpow_one, rpow_zero,
     mul_zero, zero_mul, mul_one, one_mul, fix_cast₁, fix_cast₂, fix_cast₃, Nat.cast_one, inv_rpow',
     rpow_inv] $(loc)?)

example (a e b : ℝ) (_ : 0 < a) :
    ((a ^ (e / b)) ^ b) * b ^ e * a ^ (-b) = a ^ (e / b * b - b) * b ^ e := by
  rpow_simp

end Mathlib.Tactic.RPowRing
