# VGA raster results — 7 November 2026

Tested source/runner commit: `bc29290c9e223325f82d23d2eebbc797a017609c`.
ModelSim Intel FPGA Starter Edition `vsim 2020.1 Simulator 2020.02
Feb 28 2020`. Deterministic input class: all 256 RGB332 byte values.

| Executed simulation | Actual result |
| --- | --- |
| Original seven-check directed bench | PASS, 7 checks, wrapper exit 0 |
| Independent public-pin raster oracle | PASS, 29,588,940 pin comparisons over 1,232,740 sampled pixels; 2 complete frame wraps, 922,318 active samples, 147,845 HSYNC-low samples, 3,201 VSYNC-low samples, 258 valid writes, 2 invalid-write attempts and 4 raster reset pulses; wrapper exit 0 |
| Short measured wave run | PASS, 21,222 pin comparisons and 754 sampled pixels; wrapper exit 0 |

The [reference model](../tb/vga_raster_test.sv) advances from input clock
edges and reset rather than DUT private counters, and compares externally
visible sync, active and RGB pins. It checks every output observation in its
test interval. It verified all 256 RGB332 values through display outputs,
8×8 replication, row/line/frame transitions, both sync windows, retained
framebuffer writes during reset, a later visible write, and invalid-address
non-aliasing. The counts include partial intervals before the final two
complete frames; they are check totals, not coverage percentages.

Two disposable RTL faults each raised `VGA_RASTER_MISMATCH` and caused
wrapper exit **1**: shifting the HSYNC start from 656 to 657, and wrapping
an out-of-range write back into the valid framebuffer. Their mutant source,
hash, raw logs, JSON and fault summary are in separate `fault-*` directories.
No mutant is in the tested source. The runner rejects simulator fatals even
when ModelSim returns process exit 0.

The [passing raw logs/JSON](../reports/technical-completion-2026-11-07/)
record exact commands, source SHA-256 hashes, simulator version, terminal
markers and 180-second per-command timeouts. The
[measured SVG](../reports/technical-completion-2026-11-07/vga-raster.svg)
was rendered from the [simulator VCD](../reports/technical-completion-2026-11-07/vga-raster.vcd),
covering the first 35.365 µs, including a visible row and horizontal sync
boundary. The adjacent metadata identifies top, selected pins, 1 ps tick
units and VCD SHA-256. The renderer does not establish functional PASS.
Vertical sync and frame wrap were checked by the oracle; this published
short SVG does not depict those later intervals.

Reproduce from a clean checkout with a fresh output directory:

```powershell
$env:MODELSIM_BIN = 'C:\intelFPGA\20.1\modelsim_ase\win32aloem'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1 -OutputDir C:\short\vga-run-unique -CaptureWave
if ($LASTEXITCODE -ne 0) { throw 'VGA regression failed or blocked' }
```

UVM, SVA and covergroup capabilities were not qualified in this Starter
simulator. No external SRAM, full video interface compliance, coverage
closure, synthesis, timing, FPGA or hardware result is claimed.
