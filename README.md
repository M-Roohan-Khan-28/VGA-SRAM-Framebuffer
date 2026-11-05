# VGA Timing Controller with SRAM Framebuffer

**SystemVerilog · 640 × 480 timing · RGB output**

A VGA timing and pixel-output design with an 80 × 60 RGB332 framebuffer scaled across a 640 × 480 active image. The RTL generates horizontal and vertical synchronization, blanks inactive video, and supports framebuffer writes.

The framebuffer is internal RTL storage. The retained simulation results do not establish external SRAM-interface compatibility or physical display operation.

See [original source documentation](SOURCE_README.md) for the baseline files and the verification-status section below for the available evidence.

## Run

From the repository root, with the required ModelSim/Questa executables and appropriate licence available:

```bash
bash sim/run.sh
```

Existing Windows instructions, where supplied, are retained in `scripts/`. Do not assume the testbench will run in every edition of a simulator. Check [the retained validation report](source-docs/VALIDATION.md) and the original README.

## Verification status

The included logs are historical evidence copied from the source repository. **The extracted copy has not been simulated by this extraction script.** Re-run before reporting fresh results. Some original exercises were blocked by verification-feature licence restrictions; those restrictions are not changed by packaging.

## Provenance and changes

Source commit: `df8d6f66898a08df75cd2071ddac7bbba9ba9b16`. Source path: `projects/vga-sram`.

[SOURCE_PROVENANCE.json](SOURCE_PROVENANCE.json) records checksums of every original file. `SOURCE_README.md` is the unchanged original README. No RTL or testbench functionality was changed during extraction. Source history remains available in the original repository; this is a snapshot, not a rewrite of its authorship.

## Next engineering work

Planned checks will cover complete frame timing, synchronization widths, blanking, framebuffer address bounds, and pixel-write/readback behaviour. Board timing and physical display results will require a defined FPGA target.
