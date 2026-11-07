# Measured VGA boundary captures

These are simulator VCD captures from the independently checked
`vga_raster_test` at tested source `950026b022816b961df24c52e5186b051fca83f4`.
The source is the public GitHub technical branch, cloned into a clean worktree
before execution. The run used ModelSim Intel FPGA Starter Edition
`vsim 2020.1 Simulator 2020.02 Feb 28 2020`, 10 ns input clocks, and
deterministic framebuffer input values covering all 256 RGB332 bytes.

| Scenario | Measured figures | Checked interval |
| --- | --- | --- |
| Horizontal boundaries | [Active-to-blank and HSYNC start](../reports/technical-completion-2026-11-07/boundary-captures/horizontal-active.svg), [HSYNC end](../reports/technical-completion-2026-11-07/boundary-captures/horizontal-sync-end.svg) | Reference h=638..658 and h=750..754, line 0 |
| Vertical boundaries | [VSYNC start](../reports/technical-completion-2026-11-07/boundary-captures/vertical-sync-start.svg), [VSYNC end](../reports/technical-completion-2026-11-07/boundary-captures/vertical-sync-end.svg) | Reference line 489 to 490 and 491 to 492; each crop shows adjacent clocks |
| Framebuffer write to pixel | [Write and first displayed pixel](../reports/technical-completion-2026-11-07/boundary-captures/write.svg) | `sram_we` at address `0x03E8`, data `0x5A`, immediately before the pixel at h=320, v=96 |
| Frame wrap | [Last line to next frame](../reports/technical-completion-2026-11-07/boundary-captures/frame.svg) | Reference line 524 h=796 through line 0 h=4 |

The adjacent JSON files give the actual 1 ps VCD tick ranges and trace
SHA-256 values. The four [raw VCDs and simulator logs](../reports/technical-completion-2026-11-07/boundary-captures/)
retain the capture commands and `VGA_WAVE_ARM`/`VGA_WAVE_PASS` markers.
Public pins were scored throughout each capture by a reference clock/reset
and framebuffer model. The plotted reference coordinates and DUT private
counters are explanatory observations; neither feeds that expected-result
model. The SVG renderer labels its origin as `simulator` and does not itself
determine PASS.

The separate complete raster run passed 29,588,940 pin comparisons over two
full frame wraps, and the preserved original directed bench passed seven
checks. Exact commands, simulator exits, source hash and source-clean flag are
in [results.json](../reports/technical-completion-2026-11-07/boundary-captures/results.json).
The earlier short horizontal [capture](../reports/technical-completion-2026-11-07/vga-raster.svg)
and historical report remain unchanged. Neither these traces nor the bounded
raster model establish external SRAM behavior, video compliance, synthesis,
timing, FPGA, or hardware operation.

Reproduce into a new output directory:

```powershell
$env:MODELSIM_BIN = 'C:\intelFPGA\20.1\modelsim_ase\win32aloem'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1 -OutputDir C:\short\vga-boundaries-unique -CaptureWave
if ($LASTEXITCODE -ne 0) { throw 'VGA regression or measured capture failed' }
```
