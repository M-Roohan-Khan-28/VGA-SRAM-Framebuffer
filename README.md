# VGA Timing Controller with SRAM Framebuffer

**SystemVerilog · 640 × 480 timing · RGB output**

A VGA timing and pixel-output design with an 80 × 60 RGB332 framebuffer scaled across a 640 × 480 active image. The RTL generates horizontal and vertical synchronization, blanks inactive video, and supports framebuffer writes.

The framebuffer is internal RTL storage. The retained simulation results do not establish external SRAM-interface compatibility or physical display operation.

The corrected bounded contract ignores framebuffer write addresses 4800–8191.
At tested source `950026b022816b961df24c52e5186b051fca83f4`, the
[independent raster regression](docs/RESULTS.md) passed the preserved seven
checks plus 29,588,940 public-pin comparisons over two complete frame wraps,
including all 256 RGB332 values. Separate HSYNC and invalid-address faults
produced nonzero wrapper exits. Four measured boundary scenarios now show
horizontal and vertical sync transitions, a framebuffer write through its
first displayed pixel, and frame wrap. The [VCDs, six readable figures and
reproduction details](docs/MEASURED_WAVEFORMS.md) accompany the checked run.
The earlier short horizontal capture remains as historical evidence.
See the [implemented specification](docs/SPECIFICATION.md).

See [original source documentation](SOURCE_README.md) for the baseline files and the verification-status section below for the available evidence.

## Run

From the repository root, with ModelSim/Questa executables and Python 3:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1 -OutputDir C:\short\vga-run-unique -CaptureWave
```

Choose a new output directory for each run. The original `sim/run.sh` and
`scripts/run_sim.ps1` remain historical entry points. Check
[the retained validation report](source-docs/VALIDATION.md) and original
README for the baseline.

## Verification status

The original `reports/` logs are historical extraction evidence. New executed
results are under `reports/technical-completion-2026-11-07/`. The installed
Starter simulator did not qualify licensed UVM, SVA or covergroups. No
coverage, synthesis, timing, FPGA or hardware result is claimed.

## Provenance and changes

Source commit: `df8d6f66898a08df75cd2071ddac7bbba9ba9b16`. Source path: `projects/vga-sram`.

[SOURCE_PROVENANCE.json](SOURCE_PROVENANCE.json) records checksums of every original file. `SOURCE_README.md` is the unchanged original README. No RTL or testbench functionality was changed during extraction. Source history remains available in the original repository; this is a snapshot, not a rewrite of its authorship.

## Next engineering work

Planned checks will cover complete frame timing, synchronization widths, blanking, framebuffer address bounds, and pixel-write/readback behaviour. Board timing and physical display results will require a defined FPGA target.
