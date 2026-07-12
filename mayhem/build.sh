#!/usr/bin/env bash
#
# mayhem/build.sh — build the taoCPP/config fuzz harness and the upstream test suite.
#
# taocpp/config is a HEADER-ONLY C++17 library (include/tao/config.hpp), depending on the
# bundled submodules external/json (taoJSON) and its nested external/PEGTL — also header-only,
# so the whole fuzzed code path is instrumented by compiling the harness with $SANITIZER_FLAGS.
#
# Outputs:
#   build/fuzz/config-fuzz             sanitized libFuzzer target (the Mayhem target)
#   build/fuzz/config-fuzz-standalone  run-once reproducer (STANDALONE_FUZZ_MAIN)
#   build/bin/test/config/*            upstream unit tests, NORMAL flags (run by mayhem/test.sh)
#   build/bin/example/config/*         upstream examples (dump_only_data used as known-answer oracle)
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${CC:=clang}" ; : "${CXX:=clang++}" ; : "${LIB_FUZZING_ENGINE:=-fsanitize=fuzzer}"
: "${MAYHEM_JOBS:=$(nproc)}"
: "${COVERAGE_FLAGS=}"
export SANITIZER_FLAGS DEBUG_FLAGS CC CXX LIB_FUZZING_ENGINE MAYHEM_JOBS COVERAGE_FLAGS

cd "${SRC:-/mayhem}"

INCLUDES="-Iinclude -Iexternal/json/include -Iexternal/json/external/PEGTL/include"

# 1) Upstream test suite + examples, with the project's NORMAL flags (upstream Makefile).
#    We pass CXXFLAGS explicitly to drop upstream's -Werror (kept for their own CI; newer clang
#    may flag benign warnings as errors) and to append $COVERAGE_FLAGS for coverage builds.
#    Header-only library => nothing else to "build" for the project itself.
make -j"$MAYHEM_JOBS" compile CXX="$CXX" CXXFLAGS="-Wall -Wextra -O2 $COVERAGE_FLAGS"

# 2) Sanitized libFuzzer harness — header-only, so the PROJECT code is instrumented here.
#    -O1 keeps triage frames readable; $DEBUG_FLAGS after sanitizers so -gdwarf-3 wins (DWARF < 4).
mkdir -p build/fuzz
# shellcheck disable=SC2086
$CXX -std=c++17 $SANITIZER_FLAGS $DEBUG_FLAGS -O1 $INCLUDES $LIB_FUZZING_ENGINE \
    mayhem/config-fuzz.cpp -o build/fuzz/config-fuzz

# 3) Standalone run-once reproducer (same harness, LLVM's standalone driver instead of libFuzzer).
#    Compile the driver as C first so LLVMFuzzerTestOneInput keeps C linkage.
# shellcheck disable=SC2086
$CC $SANITIZER_FLAGS $DEBUG_FLAGS -c "$STANDALONE_FUZZ_MAIN" -o /tmp/standalone_main.o
# shellcheck disable=SC2086
$CXX -std=c++17 $SANITIZER_FLAGS $DEBUG_FLAGS -O1 $INCLUDES \
    mayhem/config-fuzz.cpp /tmp/standalone_main.o -o build/fuzz/config-fuzz-standalone

echo "build.sh: built build/fuzz/config-fuzz (sanitized), -standalone, and the upstream test suite"
