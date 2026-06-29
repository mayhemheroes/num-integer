#!/usr/bin/env bash
#
# mayhem/build.sh — build cargo-fuzz targets (ASan via RUSTFLAGS) and the test suite.
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
: "${RUST_DEBUG_FLAGS:=-Cdebuginfo=2 -Zdwarf-version=3 -Clinker=/opt/mayhem-dwarf3-anchor/cc-wrapper.sh}"
: "${MAYHEM_JOBS:=$(nproc)}"
export CARGO_BUILD_JOBS="$MAYHEM_JOBS"
export SANITIZER_FLAGS RUST_DEBUG_FLAGS

cd "$SRC"

SANITIZER_RUSTFLAGS="--cfg fuzzing -Zsanitizer=address -Cforce-frame-pointers"
FUZZ_RUSTFLAGS="${RUST_DEBUG_FLAGS} ${SANITIZER_RUSTFLAGS}"

FUZZ_DIR="mayhem/fuzz"
TRIPLE="x86_64-unknown-linux-gnu"

FUZZ_TARGETS=()
for f in "$FUZZ_DIR"/fuzz_targets/*.rs; do
  FUZZ_TARGETS+=("$(basename "${f%.*}")")
done
[ "${#FUZZ_TARGETS[@]}" -gt 0 ] || { echo "ERROR: no fuzz targets under $FUZZ_DIR/fuzz_targets/" >&2; exit 1; }

echo "=== cargo fuzz build (ASan via RUSTFLAGS) ==="
echo "RUSTFLAGS=$FUZZ_RUSTFLAGS"
echo "targets: ${FUZZ_TARGETS[*]}"

for t in "${FUZZ_TARGETS[@]}"; do
  echo "--- building fuzz target: $t ---"
  RUSTFLAGS="${RUSTFLAGS:-} ${FUZZ_RUSTFLAGS}" cargo fuzz build --fuzz-dir "$FUZZ_DIR" -O --debug-assertions "$t"
  bin="$SRC/$FUZZ_DIR/target/$TRIPLE/release/$t"
  [ -x "$bin" ] || { echo "ERROR: expected fuzz binary not found at $bin" >&2; exit 1; }
  # Install path matches Mayhemfile `target:` slug (upstream harness is still named "functions").
  out="$t"
  [ "$t" = "functions" ] && out="num-integer"
  cp "$bin" "/mayhem/$out"
  echo "built /mayhem/$out"
done

echo "=== cargo test (clean, non-sanitized oracle build) ==="
env -u RUSTFLAGS cargo test --no-run

echo "build.sh complete"
