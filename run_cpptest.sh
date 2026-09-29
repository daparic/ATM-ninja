#!/usr/bin/env bash
# Reproduces the whole ATM-ninja C/C++test flow:
#   1. Ninja build + compilation database (compile_commands.json via `ninja -t compdb`)
#   2. builtin://MISRA C++ 2023 static analysis (C/C++test Standard engine -> same HTML report
#      layout as examples/ATM/report/report.html)
#   3. builtin://Generate Unit Tests (C/C++test Professional; creates the project from the JSON)
#   4. builtin://Run Unit Tests with Statement / Decision / MC/DC coverage
#
# Usage: ./run_cpptest.sh [all|compdb|misra|generate|run|clean]   (default: all)
set -euo pipefail

# Note: CPPTEST_HOME is not reused because it may point at the C/C++test CT edition.
CPPTEST_PRO_HOME=${CPPTEST_PRO_HOME:-/opt/parasoft/cpptest_professional-2026.1.0-linux.x86_64}
CPPTEST_STD_HOME=${CPPTEST_STD_HOME:-/opt/parasoft/cpptest_standard-2026.1.0-linux.x86_64}
LICENSE_PROPS=${LICENSE_PROPS:-$HOME/cpptestcli.properties}

ROOT=$(cd "$(dirname "$0")" && pwd)
WORKSPACE=$ROOT/cpptest/workspace
STD_WORKSPACE=$ROOT/cpptest/std-workspace
COMPDB=$ROOT/compile_commands.json
SETTINGS=$ROOT/cpptest/cpptest.properties
RUN_CONFIG="$ROOT/cpptest/Run Unit Tests - SC DC MCDC.properties"
PROJECT=ATM-ninja

cd "$ROOT"

cpptestcli() {
    "$CPPTEST_PRO_HOME/cpptestcli" -data "$WORKSPACE" \
        -settings "$LICENSE_PROPS" -settings "$SETTINGS" \
        -appconsole stdout "$@"
}

step_compdb() {
    echo "### [1] Ninja build + compilation database -> $COMPDB"
    ninja
    ninja -t compdb cxx > "$COMPDB"
}

# -module: without it the module root defaults to the directory of the BDF that C/C++test Standard
#          generates internally from compile_commands.json (9 levels deep in std-workspace), and
#          the report's "Findings by File" tree shows 9 nested ".." folders.
#          With a module defined, headers in it that the sources include (include/*.hxx) are
#          analyzed too.
step_misra() {
    echo "### [2] builtin://MISRA C++ 2023 (C/C++test Standard)"
    rm -rf reports/misra-cpp-2023
    "$CPPTEST_STD_HOME/cpptestcli" -settings "$LICENSE_PROPS" \
        -workspace "$STD_WORKSPACE" \
        -compiler gcc_13-64 \
        -module "$PROJECT=$ROOT" \
        -config "builtin://MISRA C++ 2023" \
        -input "$COMPDB" \
        -report reports/misra-cpp-2023 | tee cpptest/misra.log
}

step_generate() {
    echo "### [3] builtin://Generate Unit Tests"
    local import=()
    # -bdf also accepts a CMake/Ninja-style compile_commands.json
    [ -d "$WORKSPACE/$PROJECT" ] || import=(-bdf "$COMPDB")
    cpptestcli "${import[@]}" -resource "$PROJECT" \
        -config "builtin://Generate Unit Tests" \
        -report reports/generate-unit-tests | tee cpptest/generate.log
}

step_run() {
    echo "### [4] builtin://Run Unit Tests + SC/DC/MC-DC coverage"
    rm -rf reports/run-unit-tests
    cpptestcli -resource "$PROJECT" \
        -config "$RUN_CONFIG" \
        -report reports/run-unit-tests | tee cpptest/run.log
}

step_clean() {
    ninja -t clean || true
    rm -rf "$WORKSPACE" "$STD_WORKSPACE" reports cpptest/*.log
}

case "${1:-all}" in
    compdb)   step_compdb ;;
    misra)    step_misra ;;
    generate) step_generate ;;
    run)      step_run ;;
    clean)    step_clean ;;
    all)      step_compdb; step_misra; step_generate; step_run ;;
    *)        echo "usage: $0 [all|compdb|misra|generate|run|clean]" >&2; exit 2 ;;
esac
