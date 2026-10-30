#!/usr/bin/env bash

# Update mathlib and the lean toolchain.
curl -L https://raw.githubusercontent.com/leanprover-community/mathlib4/master/lean-toolchain -o lean-toolchain

# Update dependencies
lake update