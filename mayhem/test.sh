#!/usr/bin/env bash
#
# mayhem/test.sh — RUN the project's cargo test suite (built by mayhem/build.sh).
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "$SRC"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

out="$(env -u RUSTFLAGS cargo test 2>&1)"
rc=$?
echo "$out"

passed=0
failed=0
skipped=0
while IFS= read -r line; do
  case "$line" in
    *"test result:"*)
      p="$(echo "$line" | sed -nE 's/.* ([0-9]+) passed.*/\1/p')"
      f="$(echo "$line" | sed -nE 's/.* ([0-9]+) failed.*/\1/p')"
      s="$(echo "$line" | sed -nE 's/.* ([0-9]+) ignored.*/\1/p')"
      passed=$(( passed + ${p:-0} ))
      failed=$(( failed + ${f:-0} ))
      skipped=$(( skipped + ${s:-0} ))
      ;;
  esac
done <<< "$out"

if [ "$rc" -ne 0 ] && [ "$failed" = 0 ]; then
  failed=1
fi

emit_ctrf "cargo-test" "$passed" "$failed" "$skipped"
