import FltRegular
import Lean
import Lean.Util.CollectAxioms

/- THIS IS NEW VERSION OF LISTDECLAXIOM THAT CALCULATE HASH OF DECLARATION.-/

open Lean Meta

def kindOf : ConstantInfo → String
  | .axiomInfo _  => "axiom"
  | .defnInfo _   => "def"
  | .thmInfo _    => "theorem"
  | .opaqueInfo _ => "opaque"
  | .quotInfo _   => "quot"
  | .inductInfo _ => "inductive"
  | .ctorInfo _   => "ctor"
  | .recInfo _    => "recursor"

def allowedAxioms : Std.HashSet Name :=
  Std.HashSet.emptyWithCapacity
    |>.insert `propext
    |>.insert `Classical.choice
    |>.insert `Quot.sound

def formatNames (names : Array Name) : String :=
  String.append (String.append "[" (String.intercalate ", " (names.map Name.toString).toList)) "]"

def oneLine (s : String) : String :=
  s.replace "\n" " "

def declSummary (name : Name) : MetaM String := do
  let env ← getEnv
  match env.checked.get.find? name with
  | some info =>
      let typeFmt ← ppExpr info.type
      let typeStr := oneLine typeFmt.pretty
      return s!"{name} : type={typeStr}"
  | none =>
      return s!"{name} : type=<unknown>"

def pushName (names : Array Name) (name : Name) : Array Name :=
  if names.contains name then names else names.push name

def mergeNames (xs ys : Array Name) : Array Name :=
  ys.foldl pushName xs

def nameSetOf (names : Array Name) : Std.HashSet Name :=
  names.foldl (fun acc name => acc.insert name) (Std.HashSet.emptyWithCapacity)

def isModuleUnderPrefix (modulePrefix : String) (moduleName : Name) : Bool :=
  let moduleNameString := moduleName.toString
  moduleNameString == modulePrefix || moduleNameString.startsWith (modulePrefix ++ ".")

structure AxiomCache where
  memo : Std.HashMap Name (Array Name) := {}
  visiting : NameSet := {}

abbrev AxiomM := StateT AxiomCache MetaM

partial def collectAxiomDeps (name : Name) : AxiomM (Array Name) := do
  if let some axioms := (← get).memo[name]? then
    return axioms
  if (← get).visiting.contains name then
    return #[]
  modify fun st => { st with visiting := st.visiting.insert name }
  let env ← getEnv
  let mut axioms := #[]
  let collectExpr (start : Array Name) (e : Expr) : AxiomM (Array Name) := do
    let mut acc := start
    for usedName in e.getUsedConstants do
      acc := mergeNames acc (← collectAxiomDeps usedName)
    return acc
  match env.checked.get.find? name with
  | some (.axiomInfo v) =>
      axioms := pushName axioms name
      axioms ← collectExpr axioms v.type
  | some (.defnInfo v) =>
      axioms ← collectExpr axioms v.type
      axioms ← collectExpr axioms v.value
  | some (.thmInfo v) =>
      axioms ← collectExpr axioms v.type
      axioms ← collectExpr axioms v.value
  | some (.opaqueInfo v) =>
      axioms ← collectExpr axioms v.type
      axioms ← collectExpr axioms v.value
  | some (.quotInfo _) =>
      pure ()
  | some (.ctorInfo v) =>
      axioms ← collectExpr axioms v.type
  | some (.recInfo v) =>
      axioms ← collectExpr axioms v.type
  | some (.inductInfo v) =>
      axioms ← collectExpr axioms v.type
      for ctor in v.ctors do
        axioms := mergeNames axioms (← collectAxiomDeps ctor)
  | none =>
      pure ()
  modify fun st =>
    { memo := st.memo.insert name axioms
      visiting := st.visiting.erase name }
  return axioms.qsort Name.lt

def analysisDecls (modulePrefix : String) : MetaM (Array Name) := do
  let env ← getEnv
  let mut decls := #[]
  for i in [:env.header.moduleNames.size] do
    let moduleName := env.header.moduleNames[i]!
    if isModuleUnderPrefix modulePrefix moduleName then
    let moduleData := env.header.moduleData[i]!
    for j in [:moduleData.constNames.size] do
      decls := decls.push moduleData.constNames[j]!
  return decls

def projectDeclSet (modulePrefix : String) : MetaM (Std.HashSet Name) := do
  let decls ← analysisDecls modulePrefix
  return nameSetOf decls

def collectProjectConstantsInExpr
    (projectDecls : Std.HashSet Name)
    (e : Expr) : Array Name := Id.run do
  let mut acc := #[]
  for usedName in e.getUsedConstants do
    if projectDecls.contains usedName then
      acc := pushName acc usedName
  return acc.qsort Name.lt

def collectProjectConstantsInExprs
    (projectDecls : Std.HashSet Name)
    (exprs : Array Expr) : Array Name := Id.run do
  let mut acc := #[]
  for expr in exprs do
    acc := mergeNames acc (collectProjectConstantsInExpr projectDecls expr)
  return acc.qsort Name.lt

def specHashExprsForDecl (name : Name) : MetaM (Array Expr) := do
  let env ← getEnv
  match env.checked.get.find? name with
  | some (.axiomInfo v) =>
      return #[v.type]
  | some (.defnInfo v) =>
      return #[v.type, v.value]
  | some (.thmInfo v) =>
      return #[v.type]
  | some (.opaqueInfo v) =>
      return #[v.type, v.value]
  | some (.quotInfo _) =>
      return #[]
  | some (.ctorInfo v) =>
      return #[v.type]
  | some (.recInfo v) =>
      return #[v.type]
  | some (.inductInfo v) =>
      let mut exprs := #[v.type]
      for ctor in v.ctors do
        if let some (.ctorInfo c) := env.checked.get.find? ctor then
          exprs := exprs.push c.type
      return exprs
  | none =>
      return #[]

def collectSpecDirectDeps
    (projectDecls : Std.HashSet Name)
    (name : Name) : MetaM (Array Name) := do
  let exprs ← specHashExprsForDecl name
  let deps := collectProjectConstantsInExprs projectDecls exprs
  return deps.filter (· != name)

structure SpecClosureCache where
  memo : Std.HashMap Name (Array Name) := {}
  visiting : NameSet := {}

abbrev SpecClosureM := ReaderT (Std.HashSet Name) (StateT SpecClosureCache MetaM)

partial def collectSpecClosureFromDecl (name : Name) : SpecClosureM (Array Name) := do
  if let some deps := (← get).memo[name]? then
    return deps
  if (← get).visiting.contains name then
    return #[]
  modify fun st => { st with visiting := st.visiting.insert name }
  let projectDecls ← read
  let directDeps ← liftM <| collectSpecDirectDeps projectDecls name
  let mut deps := #[]
  for dep in directDeps do
    deps := pushName deps dep
    deps := mergeNames deps (← collectSpecClosureFromDecl dep)
  let sortedDeps := deps.qsort Name.lt
  modify fun st =>
    { memo := st.memo.insert name sortedDeps
      visiting := st.visiting.erase name }
  return sortedDeps

def collectSpecClosureFromRoots (roots : Array Name) : SpecClosureM (Array Name) := do
  let mut deps := #[]
  for root in roots do
    deps := pushName deps root
    deps := mergeNames deps (← collectSpecClosureFromDecl root)
  return deps.qsort Name.lt

def targetTypeProjectRoots
    (projectDecls : Std.HashSet Name)
    (target : Name) : MetaM (Array Name × Expr) := do
  let env ← getEnv
  match env.checked.get.find? target with
  | some info =>
      return (collectProjectConstantsInExpr projectDecls info.type, info.type)
  | none =>
      throwError "target declaration not found: {target}"

def mixExprArrayHash (seed : UInt64) (exprs : Array Expr) : UInt64 :=
  exprs.foldl (fun h expr => mixHash h (hash expr)) seed

def specHashForDecl (name : Name) : MetaM UInt64 := do
  let env ← getEnv
  match env.checked.get.find? name with
  | some (.inductInfo v) =>
      let exprs ← specHashExprsForDecl name
      let mut h := mixExprArrayHash (mixHash (hash name) (hash "inductive")) exprs
      for ctor in v.ctors do
        h := mixHash h (hash ctor)
      return h
  | some info =>
      let exprs ← specHashExprsForDecl name
      return mixExprArrayHash (mixHash (hash name) (hash (kindOf info))) exprs
  | none =>
      return mixHash (hash name) (hash "missing")

def targetSpecClosureHash (modulePrefix : String) (target : Name) : MetaM UInt64 := do
  let projectDecls ← projectDeclSet modulePrefix
  if projectDecls.isEmpty then
    throwError "no declarations found for module prefix {modulePrefix}"
  if !projectDecls.contains target then
    throwError "target {target} is not a declaration from modules matching prefix {modulePrefix}"
  let (roots, targetType) ← targetTypeProjectRoots projectDecls target
  let (closure, _) ← (collectSpecClosureFromRoots roots).run projectDecls |>.run {}
  let mut total := mixHash (hash "target-spec-closure-v1") (hash target)
  total := mixHash total (hash targetType)
  for dep in closure do
    total := mixHash total (← specHashForDecl dep)
  return total

def dumpDeclNames (modulePrefix : String) : MetaM Unit := do
  for name in ← analysisDecls modulePrefix do
    IO.println name

def dumpDeclAxioms (modulePrefix : String) (onlyBad : Bool := true) : MetaM Unit := do
  let checkedRef ← IO.mkRef 0
  let badRef ← IO.mkRef 0
  let (_, _) ← (do
  for name in ← analysisDecls modulePrefix do
    checkedRef.modify (· + 1)
    let summary ← declSummary name
    let axiomArray ← collectAxiomDeps name
    let unexpected := axiomArray.filter fun ax => !allowedAxioms.contains ax
    if unexpected.isEmpty then
      unless onlyBad do
        IO.println s!"OK {summary}; axioms={formatNames axiomArray}"
    else
      badRef.modify (· + 1)
      IO.println
        s!"BAD {summary}; unexpected={formatNames unexpected}; all={formatNames axiomArray}"
  : AxiomM Unit).run {}
  let checked ← checkedRef.get
  let bad ← badRef.get
  IO.println s!"SUMMARY checked={checked} bad={bad}"

-- Check whether the axioms each declaration depends on are all in allowedAxioms; only print anomalies:
-- #eval! (dumpDeclAxioms "FltRegular").run'

-- To also print OK items, use this line instead:
#eval! (dumpDeclAxioms "FltRegular" (onlyBad := false)).run'

-- #eval! (targetSpecClosureHash "FltRegular" `flt_regular).run'

def targetSpecClosureHashpp (modulePrefix : String) (target : Name) : MetaM Unit := do
  let got ← (targetSpecClosureHash modulePrefix target).run'
  let result := got == (5661755412503949330 : UInt64)
  IO.println s!"HASH checked={target} result={result}"

#eval! (targetSpecClosureHashpp "FltRegular" `flt_regular).run'

-- To only print full names, use this line instead:
-- #eval (dumpDeclNames "PrimeNumberTheoremAnd.Erdos392").run'
