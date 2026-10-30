# Build rules for libintcompress.so + local benchmark tools.
# The remote evaluator uses an equivalent Makefile; ensure `make -j4` succeeds
# in under 5 minutes of CPU time.

CXX      ?= g++
CXXSTD    = -std=c++17
OPT       = -O3 -march=x86-64-v3 -fno-exceptions -fno-rtti
WARN      = -Wall -Wextra -Wno-unused-parameter
INC       = -Iinclude
CXXFLAGS  = $(CXXSTD) $(OPT) $(WARN) $(INC) -fPIC

SRCS      = $(wildcard src/*.cpp)
OBJS      = $(SRCS:.cpp=.o)

LIB       = libintcompress.so
BENCH     = tools/bench
VERIFY    = tools/verify

.PHONY: all clean submit
all: $(LIB) $(BENCH) $(VERIFY)

$(LIB): $(OBJS)
	$(CXX) -shared $(CXXFLAGS) -o $@ $^

src/%.o: src/%.cpp include/intcompress.h
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BENCH): tools/bench.cpp $(LIB)
	$(CXX) $(CXXSTD) -O2 $(INC) -o $@ $< -L. -lintcompress -lpthread -Wl,-rpath,'$$ORIGIN/..'

$(VERIFY): tools/verify.cpp $(LIB)
	$(CXX) $(CXXSTD) -O2 $(INC) -o $@ $< -L. -lintcompress -lpthread -Wl,-rpath,'$$ORIGIN/..'

clean:
	rm -f $(OBJS) $(LIB) $(BENCH) $(VERIFY)

# Create a submission tarball containing only the sources the evaluator needs.
submit:
	@test -n "$(TAR)" || (echo "usage: make submit TAR=my_submission.tar.gz" ; exit 1)
	tar --exclude='datasets/*.u32' --exclude='*.o' --exclude='*.so' \
	    --exclude='tools/bench' --exclude='tools/verify' \
	    -czf $(TAR) include src Makefile
	@echo "Wrote $(TAR)"
