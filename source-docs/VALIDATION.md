# Packaging validation — September 13, 2026

Simulator: ModelSim Intel FPGA Starter Edition 2020.1.

| Exercise | Result |
| --- | --- |
| AHB-Lite RAM | 18 checks passed, zero failures |
| APB modports | 2 readback checks passed, zero failures |
| Two-way cache | 7 checks passed, zero failures |
| ALU | Compiles; randomize() execution requires an unavailable verification license |
| APB interface | Compiles; verification features require an unavailable Questa license |
| VGA/SRAM | After the initialized-memory process fix: 7 checks passed, zero failures |

Evidence is in each project's `reports/compile.log` and, where elaboration was
attempted, `reports/simulation.log`. Passing checks are limited to the supplied
testbenches; they do not establish full protocol or functional coverage.

The VGA change keeps the existing initialization and clocked-write behavior while
removing an incompatible always_ff restriction. Other RTL/testbench sources were
copied without behavioral changes.
