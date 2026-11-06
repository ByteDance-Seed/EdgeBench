import Batteries.Tactic.PrintDependents
import Mathlib.Data.List.Sort
import Mathlib.Data.String.Basic
import Mathlib.Util.AssertNoSorry
import ConNF

open Lean

def nameCode (n : Name) : String :=
  if n = .anonymous then
    "anonymous"
  else
    n.toString.replace "." "_"

def nameDisplay (n : Name) : String :=
  n.components.getLast!.toString

def printDeps₁ (k : Name) (_v : Array Name) (print : String → IO Unit) : IO Unit := do
  let n := k.componentsRev[1]!
  print (nameCode k ++ " [label=\"" ++ nameDisplay k ++ "\"" ++
    " group=\"" ++ n.toString ++ "\"]" ++ ";\n")

def printDeps₂ (k : Name) (v : Array Name) (print : String → IO Unit) : IO Unit := do
  for val in v do
    if (`ConNF).isPrefixOf val then
      print (nameCode val ++ " -> " ++ nameCode k ++ ";\n")

def group (name : Name) : Name :=
  (name.eraseSuffix? name.componentsRev.head!).get!

def groups (imports : NameMap (Array Name)) : NameMap Unit :=
  RBMap.fromList (imports.fold (fun xs k _ =>
    if (`ConNF).isPrefixOf k then (group k, ()) :: xs else xs) []) _

/-- `#deptree` outputs a graphviz dependency graph to `depgraph.dot`. Build it with
`dot -Tpdf -Gnewrank=true -Goverlaps=false -Gsplines=ortho depgraph.dot > depgraph.pdf`. -/
elab "#deptree " : command => do
  let env ← getEnv
  let imports := env.importGraph
  IO.FS.withFile "docs/depgraph.dot" IO.FS.Mode.write fun h => do
  h.write "digraph {\n".toUTF8
  h.write "compound=true;\n".toUTF8
  for (gp, _) in groups imports do
    h.write ("subgraph cluster_" ++ nameCode gp ++ " {\n").toUTF8
    for (k, v) in imports do
      if (`ConNF).isPrefixOf k && k != `ConNF && group k = gp then do
        printDeps₁ k v (fun s => h.write s.toUTF8)
    h.write ("label = \"" ++ gp.toString ++ "\";\n").toUTF8
    h.write ("margin = 32;\n").toUTF8
    h.write ("pad = 32;\n").toUTF8
    h.write ("penwidth = 5;\n").toUTF8
    h.write ("color = cyan4;\n").toUTF8
    h.write "}\n".toUTF8
  for (k, v) in imports do
    if (`ConNF).isPrefixOf k && k != `ConNF then do
      printDeps₂ k v (fun s => h.write s.toUTF8)
  h.write "}\n".toUTF8

/-- Extracts the names of the declarations in `env` on which `decl` depends. -/
-- source:
-- https://leanprover.zulipchat.com/#narrow/stream/287929-mathlib4/topic/Counting.20prerequisites.20of.20a.20theorem/near/425370265
def getVisited (env : Environment) (decl : Name) :=
  let (_, { visited, .. }) := CollectAxioms.collect decl |>.run env |>.run {}
  visited.erase decl

partial def allDeclsIn (module : Name) : Elab.Command.CommandElabM (Array Name) := do
  let mFile ← findOLean module
  unless (← mFile.pathExists) do
    logError m!"object file '{mFile}' of module {module} does not exist"
  let (md, _) ← readModuleData mFile
  let decls ← md.constNames.filterM fun d =>
    return !(← d.isBlackListed) && !(`injEq).isSuffixOf d && !(`sizeOf_spec).isSuffixOf d
  return decls

def allFiles (env : Environment) : List Name :=
  (env.importGraph.fold (fun xs k _ => if (`ConNF).isPrefixOf k then k :: xs else xs) []).mergeSort
    (toString · < toString ·)

def allDecls (env : Environment) : Elab.Command.CommandElabM NameSet :=
  (fun l => RBTree.ofList (l.map (fun a => a.toList)).flatten) <$>
    (allFiles env).mapM allDeclsIn

/-- `#index` computes an index of the declarations in the project and saves it to `index.csv`. -/
elab "#index " : command => do
  let env ← getEnv
  let allDecls ← allDecls env
  let result ← List.mapM (fun decl => do
    let ranges ← findDeclarationRanges? decl
    let mod ← findModuleOf? decl
    match (ranges, mod) with
    | (some ranges, some mod) => pure (some (decl, ranges, mod))
    | _ => pure none)
    (allDecls.toList.mergeSort (toString · < toString ·))
  let result' := result.filterMap id
  IO.FS.withFile "docs/index.csv" IO.FS.Mode.write (fun h => do
    for (decl, ranges, mod) in result' do
      h.write (decl.toString ++ ", " ++ mod.toString ++ ", " ++
        ranges.range.pos.line.repr ++ ", " ++ ranges.range.pos.column.repr ++ "\n").toUTF8)

def seenIn (env : Environment) (allDecls : NameSet) (decl : Name) : NameSet :=
  (getVisited env decl).fold
    (fun decls x => if allDecls.contains x then decls.insert x else decls) RBTree.empty

/-- `#unseen` computes a list of the declarations in the project that are
defined but not used in the current file. The list is stored in `unseen_defs.txt`.
The average runtime on my computer is 1 minute, with 16 threads. -/
elab "#unseen " : command => do
  let env ← getEnv
  let allDecls ← allDecls env
  let mut unseen := allDecls
  let timeStart ← IO.monoMsNow
  let tasks := (fun l => Task.spawn (fun _ => seenIn env allDecls l)) <$>
    allDecls.toList.mergeSort (toString · < toString ·)
  for task in tasks do
    for v in task.get do
      unseen := unseen.erase v
  IO.FS.withFile "docs/unseen_defs.txt" IO.FS.Mode.write (fun h => do
    for v in unseen.toList.mergeSort (toString · < toString ·) do
      h.write (v.toString ++ "\n").toUTF8)
  let timeEnd ← IO.monoMsNow
  logInfo m!"operation took {(timeEnd - timeStart) / 1000}s"
