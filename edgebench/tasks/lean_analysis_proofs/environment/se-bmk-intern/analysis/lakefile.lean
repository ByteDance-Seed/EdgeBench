import Lake
open Lake DSL

package «Analysis» where
  -- Settings applied to both builds and interactive editing
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩, -- pretty-prints `fun a ↦ b`
    ⟨`doc.verso, false⟩ -- use Verso-format docstrings
  ]
  -- Settings applied only to command line builds
  -- add any additional package configuration options here

-- Require Mathlib (the comprehensive library of mathematics in Lean)
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.28.0"

@[default_target]
lean_lib «Analysis» where
  roots := #[`Analysis, `ListDeclAxiom]
  -- add any library configuration options here
