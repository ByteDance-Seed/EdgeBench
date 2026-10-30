import CombinatorialGames
import Lean
import Lean.Util.CollectAxioms

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
  Std.HashSet.emptyWithCapacity.insert `propext |>.insert `Classical.choice |>.insert `Quot.sound

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
    if moduleName.toString.startsWith modulePrefix then
    let moduleData := env.header.moduleData[i]!
    for j in [:moduleData.constNames.size] do
      decls := decls.push moduleData.constNames[j]!
  return decls

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
-- #eval! (dumpDeclAxioms "CombinatorialGames").run'

-- To also print OK items, use this line instead:
#eval! (dumpDeclAxioms "CombinatorialGames" (onlyBad := false)).run'

-- To only print full names, use this line instead:
-- #eval (dumpDeclNames "CombinatorialGames").run'
