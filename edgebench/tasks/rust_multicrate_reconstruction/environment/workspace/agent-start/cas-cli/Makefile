# CAS CLI Makefile
# Local development and testing utilities
#
# ## Testing Strategy
#
# This project uses a multi-layered testing approach:
# - Unit tests: `make test` or `make unit`
# - Integration tests: `make integration`
# - Coverage reports: `make coverage` or `make coverage-html`
#
# ## UI Testing Policy
#
# The `src/ui/` module (TUI components) is EXCLUDED from automated testing.
# Reasons:
# 1. TUI code relies heavily on terminal state and user interaction
# 2. ratatui widgets require mocked terminal backends for testing
# 3. Visual correctness is better verified through manual testing
# 4. ROI on UI unit tests is low for this CLI tool
#
# UI code is excluded from coverage metrics via `--exclude-files "src/ui/*"`.
# Manual testing checklist for UI changes:
# - [ ] TUI renders correctly in different terminal sizes
# - [ ] Keyboard navigation works (j/k, arrow keys, Enter, Esc)
# - [ ] Color scheme is readable in light/dark terminals
# - [ ] Status line updates correctly
# - [ ] No visual artifacts or flickering

.PHONY: test test-full coverage coverage-html clean build build-full release release-fast check check-full lint dev-build dev-test timings benchmark-build check-build-regression

CARGO ?= cargo

# Run all tests
test:
	$(CARGO) test -p cas

# Run full test matrix
test-full:
	$(CARGO) test -p cas --all-features

# Run tests with output
test-verbose:
	$(CARGO) test -p cas -- --nocapture

# Run specific test module
test-%:
	$(CARGO) test -p cas $* -- --nocapture

# Generate coverage report (requires cargo-tarpaulin)
# Install: cargo install cargo-tarpaulin
coverage:
	$(CARGO) tarpaulin --all-features --workspace --timeout 300 \
		--ignore-tests \
		--exclude-files "src/ui/*" \
		--out Stdout

# Generate HTML coverage report
coverage-html:
	$(CARGO) tarpaulin --all-features --workspace --timeout 300 \
		--ignore-tests \
		--exclude-files "src/ui/*" \
		--out Html \
		--output-dir target/coverage
	@echo "Coverage report: target/coverage/tarpaulin-report.html"

# Generate coverage with specific modules
coverage-hooks:
	$(CARGO) tarpaulin --all-features --timeout 300 \
		--ignore-tests \
		--files "src/hooks/*" \
		--out Stdout

coverage-search:
	$(CARGO) tarpaulin --all-features --timeout 300 \
		--ignore-tests \
		--files "src/search/*" \
		--out Stdout

coverage-tracing:
	$(CARGO) tarpaulin --all-features --timeout 300 \
		--ignore-tests \
		--files "src/tracing/*" \
		--out Stdout

coverage-extraction:
	$(CARGO) tarpaulin --all-features --timeout 300 \
		--ignore-tests \
		--files "src/extraction/*" \
		--out Stdout

coverage-mcp:
	$(CARGO) tarpaulin --all-features --timeout 300 \
		--ignore-tests \
		--files "src/mcp/*" \
		--out Stdout

# Build debug
build:
	$(CARGO) build -p cas

# Build debug with all features
build-full:
	$(CARGO) build -p cas --all-features

# Fast local build for iteration
dev-build:
	$(CARGO) build -p cas --no-default-features

# Build release
release:
	$(CARGO) build -p cas --release --all-features

# Build faster release profile for CI/pre-release checks
release-fast:
	$(CARGO) build -p cas --profile release-fast

# Type check
check:
	$(CARGO) check -p cas

# Type check full matrix
check-full:
	$(CARGO) check -p cas --all-features

# Lint with clippy
lint:
	$(CARGO) clippy -p cas --all-features -- -D warnings

# Format code
fmt:
	$(CARGO) fmt

# Clean build artifacts
clean:
	$(CARGO) clean

# Install development tools
install-tools:
	$(CARGO) install cargo-tarpaulin
	$(CARGO) install cargo-nextest

# Run tests with nextest (faster parallel execution)
test-nextest:
	$(CARGO) nextest run -p cas --all-features

# Watch for changes and run tests
watch:
	$(CARGO) watch -x "test -p cas"

# Integration tests only
integration:
	$(CARGO) test -p cas --all-features --test "*" -- --test-threads=1

# Unit tests only (lib tests)
unit:
	$(CARGO) test -p cas --lib

# Fast local tests for iteration
dev-test:
	$(CARGO) test -p cas --lib --no-default-features

# Generate cargo timing report
timings:
	$(CARGO) build -p cas --timings

# Benchmark build times and write history/build-benchmark-latest.{md,env}
benchmark-build:
	../scripts/benchmark-build.sh

# Check build-time regression against history/build-benchmark-baseline.env
check-build-regression:
	../scripts/check-build-regression.sh
