# VGA controller & SRAM framebuffer

**Verilog / SystemVerilog · RTL and verification exercise**

This standalone repository preserves the original `vga-sram` exercise from my `hdl-labs` collection. Original RTL, testbench, simulator scripts and existing evidence are preserved byte-for-byte. This packaging step is not a new simulation or a claim of full protocol compliance.

## Overview and original documentation

Preserve timing/pixel logic and testbench. Document video timing and distinguish simulation from physical display testing.

See [the original exercise README](SOURCE_README.md) for its existing specification, source layout and tool instructions. The text above identifies review goals; it does not claim that new enhancements have already been implemented.

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

Review the specification and implementation, run the supplied tests, add independently justified checks, and record actual results and known limitations. Waveform screenshots can be added later; no fabricated screenshots or coverage figures are needed.
