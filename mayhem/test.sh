#!/usr/bin/env bash
#
# mayhem/test.sh — RUN the upstream taocpp/config test suite (built by mayhem/build.sh).
#
# Upstream's own suite is `make check`: every binary under build/bin/test/config/ is one unit-test
# program (17 of them) full of TAO_CONFIG_TEST_ASSERT known-answer assertions; success.cpp/failure.cpp
# additionally iterate the whole tests/ corpus (74 .success + expected-.jaxn pairs, ~200 .failure
# cases). We run ALL of them, exactly as `make check` does (TAO_CONFIG_VAR=hello in the env).
#
# Anti-reward-hack: the unit tests are silent-and-exit-0 on success, so a neutered exit(0) binary
# would be indistinguishable by exit status alone. Test 18 is therefore a KNOWN-ANSWER check: the
# upstream example `dump_only_data` must reproduce the committed golden JAXN for tests/simple.success
# byte-for-byte — a no-op program produces no output and FAILS it.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "${SRC:-/mayhem}"

passed=0; failed=0

emit_ctrf() {
  local tool="$1" p="$2" f="$3" s="${4:-0}"
  local tests=$(( p + f + s ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": { "tests": $tests, "passed": $p, "failed": $f, "pending": 0, "skipped": $s, "other": 0 }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":0,"skipped":%d,"other":0}}}\n' \
    "$tool" "$tests" "$p" "$f" "$s"
  [ "$f" -eq 0 ]
}

TESTS=(build/bin/test/config/*)
if [ ! -x "${TESTS[0]:-/nonexistent}" ]; then
  echo "test.sh: build/bin/test/config/* missing — build.sh must build the suite (not rebuilding here)" >&2
  emit_ctrf make-check 0 1; exit 1
fi

# 1..17) upstream unit tests, run from the repo root exactly like `make check`.
for T in "${TESTS[@]}"; do
  if TAO_CONFIG_VAR=hello "$T" >/tmp/config-test.log 2>&1; then
    echo "  ok   - $T"; passed=$((passed+1))
  else
    echo "  FAIL - $T"; sed 's/^/        /' /tmp/config-test.log; failed=$((failed+1))
  fi
done

# 18) known-answer: dump_only_data(tests/simple.success) must match the committed golden output.
DUMP=build/bin/example/config/dump_only_data
if [ -x "$DUMP" ] && "$DUMP" tests/simple.success >/tmp/config-golden.out 2>/dev/null \
   && cmp -s /tmp/config-golden.out mayhem/golden/simple.jaxn; then
  echo "  ok   - dump_only_data(tests/simple.success) matches mayhem/golden/simple.jaxn"; passed=$((passed+1))
else
  echo "  FAIL - dump_only_data(tests/simple.success) golden mismatch"; failed=$((failed+1))
fi

echo "test.sh: passed=$passed failed=$failed"
emit_ctrf make-check "$passed" "$failed"
