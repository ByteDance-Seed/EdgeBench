# CVRPTW solver build script.
# Targets:
#   make            -> cvrptw_solver + tools/verify
#   make solver     -> cvrptw_solver only
#   make verify     -> tools/verify only
#   make clean      -> remove build artifacts
#   make bench      -> run tools/bench.sh on workspace/instances/public

CXX      ?= g++
CXXSTD   ?= -std=c++17

# Choose -march flag based on toolchain. Remote evaluation runs Ubuntu 22.04
# with g++ 12 and uses -march=x86-64-v3; on macOS Apple-clang we fall back to
# -march=native so 'make' still works locally.
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    MARCH ?= -march=native
else
    MARCH ?= -march=x86-64-v3
endif

OPT      ?= -O3 $(MARCH) -DNDEBUG
WARN     ?= -Wall -Wextra -Wno-unused-parameter
CXXFLAGS ?= $(CXXSTD) $(OPT) $(WARN)
LDFLAGS  ?=

SRC_SOLVER  := src/solver.cpp
SRC_VERIFY  := tools/verify.cpp

BIN_SOLVER  := cvrptw_solver
BIN_VERIFY  := tools/verify

.PHONY: all solver verify clean bench

all: solver verify

solver: $(BIN_SOLVER)

$(BIN_SOLVER): $(SRC_SOLVER) include/types.h
	$(CXX) $(CXXFLAGS) -o $@ $(SRC_SOLVER) $(LDFLAGS)

verify: $(BIN_VERIFY)

$(BIN_VERIFY): $(SRC_VERIFY) include/types.h
	$(CXX) $(CXXFLAGS) -o $@ $(SRC_VERIFY) $(LDFLAGS)

bench: all
	@echo "bench target is not available in the agent workspace; use tools/verify on public samples"

clean:
	rm -f $(BIN_SOLVER) $(BIN_VERIFY) out_bench.csv
	rm -rf out_*
