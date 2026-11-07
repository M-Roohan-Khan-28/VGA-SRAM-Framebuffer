# Verification notes

The supplied testbench is [tb_vga_controller_sram](../tb/tb_top.sv). Start with its existing stimulus and checks, then review reset, normal operations, boundaries, and invalid inputs against the actual RTL interface.

Packaging has preserved the original testbench. There is no measured code-coverage report or new standalone assertion suite. Record failures as well as passes in the simulation log; inspect whether each check is automatic or requires waveform review before expanding the test plan.

## Executed raster contract matrix

The [specification](SPECIFICATION.md) and [actual results](RESULTS.md) cover
public pins with an independent input-clock raster model.

| Requirement | Executed check |
| --- | --- |
| 800×525 timing, 4 input clocks/pixel, two wraps | Compare sync, active and RGB after every input clock; two complete frames |
| Active/blanking and sync windows | Model `h<640,v<480`, HSYNC 656–751 and VSYNC 490–491; compare every output observation |
| 80×60 RGB332 framebuffer and 8×8 replication | Independent 4800-byte reference, visible RGB comparisons and all 256 byte values |
| Valid/invalid writes and reset retention | 258 legal writes, two invalid requests, four raster reset pulses |
| Oracle fault response | One-pixel HSYNC and out-of-range alias mutants each fail with wrapper exit 1 |

The 180-second per-command timeout and testbench watchdog bound execution.
The measured short VCD covers one horizontal boundary. Vertical/frame
captures remain a separate evidence enhancement. Counts are not code or
functional coverage percentages.

