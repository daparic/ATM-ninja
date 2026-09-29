# ATM-ninja — Parasoft C/C++test on a Ninja build

This project adapts the Parasoft C/C++test **ATM** example
(`/opt/parasoft/cpptest_professional-2026.1.0-linux.x86_64/examples/ATM/`) from a GNU Makefile to a
**Ninja** build. Both C/C++test editions read the build from the Ninja compilation database,
`compile_commands.json`. The flow then runs these Parasoft C/C++test 2026.1 steps from the command
line:

1. `builtin://MISRA C++ 2023`: static analysis. It runs on the **C/C++test Standard** engine, so the
   HTML report has the same layout as `examples/ATM/report/report.html`.
2. `builtin://Generate Unit Tests`: automatic test generation (C/C++test Professional)
3. `builtin://Run Unit Tests`: test execution with **Statement**, **Decision** and **MC/DC** coverage
   (C/C++test Professional). The HTML coverage reports show the annotated source code.

To reproduce everything from scratch, run one command (about 35 s on this machine):

```bash
./run_cpptest.sh clean && ./run_cpptest.sh all
```

## Results at a glance

| Step | Tool / configuration | Result | HTML report |
|---|---|---|---|
| Static analysis | Standard, `builtin://MISRA C++ 2023` | **53 violations** of 20 rules in 8 files (4 `.cxx` + 4 `.hxx`) | `reports/misra-cpp-2023/report.html` |
| Test generation | Professional, `builtin://Generate Unit Tests` | **122 test cases** in 6 suites | `reports/generate-unit-tests/report.html` |
| Test execution | Professional, `builtin://Run Unit Tests` + coverage | **107 passed, 15 failed** (SIGSEGV) | `reports/run-unit-tests/report.html` |
| Statement coverage | same run | **88 %** (45/51) | `reports/run-unit-tests/cvg_<ts>/SC/coverage_index.html` |
| Decision coverage | same run | **71 %** (10/14) | `reports/run-unit-tests/cvg_<ts>/DC/coverage_index.html` |
| MC/DC coverage | same run | **17 %** (1/6) | `reports/run-unit-tests/cvg_<ts>/MCDC/coverage_index.html` |

---

## Environment

| Item | Value |
|---|---|
| OS | Linux x86_64 (Ubuntu 24.04) |
| Compiler | `g++` 13.3.0 → C/C++test compiler family `gcc_13-64` |
| Build tool | Ninja 1.13.2 |
| C/C++test Professional | 2026.1.0 (`/opt/parasoft/cpptest_professional-2026.1.0-linux.x86_64`): unit test generation and execution |
| C/C++test Standard | 2026.1.0 (`/opt/parasoft/cpptest_standard-2026.1.0-linux.x86_64`): MISRA C++ 2023 report |
| License | Node-locked, `~/cpptestcli.properties` (passed with `-settings`) |

## Reference

[![Watch the video](https://img.youtube.com/vi/t65olE05nGM/0.jpg)](https://www.youtube.com/watch?v=t65olE05nGM)
