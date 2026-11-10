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

The 8 November release corrected the reference framebuffer's reset-edge
write handling and added eight bounded pending-write temporal checks. A clean
detached clone passed those checks alongside the seven original checks and
29,588,940 raster pin comparisons. The disposable old-oracle control failed
as expected; [raw logs and byte provenance](docs/RESULTS.md) are separate
from the earlier reports.

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

The original `reports/` logs are historical extraction evidence. The 7 November
Starter capability statements belong to that earlier tool configuration, which
did not qualify UVM/SVA/covergroups. A separate Questa 2025.2 configuration has
now executed the deterministic UVM/SVA review milestone linked below. Functional
coverage and constrained randomization remain NOT RUN. Synthesis, timing, FPGA
and hardware results remain separate.

## Provenance and changes

Source commit: `df8d6f66898a08df75cd2071ddac7bbba9ba9b16`. Source path: `projects/vga-sram`.

[SOURCE_PROVENANCE.json](SOURCE_PROVENANCE.json) records checksums of every original file. `SOURCE_README.md` is the unchanged original README. No RTL or testbench functionality was changed during extraction. Source history remains available in the original repository; this is a snapshot, not a rewrite of its authorship.

## Next engineering work

Planned checks will cover complete frame timing, synchronization widths, blanking, framebuffer address bounds, and pixel-write/readback behaviour. Board timing and physical display results will require a defined FPGA target.

## Separate deterministic UVM/SVA review milestone

The [AMBA-hosted adapter and reproduction guide](docs/DETERMINISTIC_VGA_UVM.md)
links a fresh detached `37/37` required PASS, actual wrapper/aggregate
exits 0, 30 principal scenarios, 8,622,612 observations /
51,735,672 comparisons, 14 fault parents and 49 runner fixtures.
The RTL remains locked to `8e257d11b1964fe82d4d4f3c3192b6a315d3b93d`. [Raw evidence, measured waveforms and
simulation-reconstructed frame](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/4ca72a17e0dca3ffed9edf5b65ffa025ee8740af/reports/vga-uvm-2026-11-11/SUMMARY.md) identify actual pins and bytes.
This is an open review package; previous main/release results above remain
historical. Functional coverage, randomization and original advanced ALU/APB
remain **NOT RUN**. No external SRAM, physical display/clock or FPGA/hardware
operation is claimed.
