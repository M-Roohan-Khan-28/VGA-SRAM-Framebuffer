# Deterministic VGA UVM/SVA adapter — open review package

The reusable environment is in [AMBA PR #18](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/pull/18) at head
`4ca72a17e0dca3ffed9edf5b65ffa025ee8740af`. Tested detached environment: `3afa2912076b6e7dadf6c958d444e2dc9a2a87f4`;
runner last-change `20c9eaa4d79209fb46323451be0783f1d8fe6df2`; inventory last-change
`20c9eaa4d79209fb46323451be0783f1d8fe6df2`. The unchanged production VGA lock is `8e257d11b1964fe82d4d4f3c3192b6a315d3b93d`.
This companion documentation does not change that RTL source pin.

## Actual port contract and checking

The adapter maps `clk`, active-high asynchronous `reset`, `sram_we`,
13-bit `sram_addr`, 8-bit `sram_data_in`, `hsync`, `vsync`, `active_video`,
and the three 4-bit RGB outputs into the unchanged `vga_controller_sram`.
The framebuffer has 4,800 RGB332 bytes. Enabled rising clocks write addresses
0–4799; higher 13-bit addresses are ignored. Raster reset retains framebuffer
contents and still allows writes. RGB during reset may be nonblack.

The [contract/requirements matrix](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/4ca72a17e0dca3ffed9edf5b65ffa025ee8740af/docs/DETERMINISTIC_VGA_UVM.md)
specifies the divide-by-four 800×525 raster, 640×480 active region, sync windows,
8×8 replication, RGB332 expansion and race-free observation schedule. Independent
models use only public input clocks/reset, specified initialization and accepted
write inputs; expected state never reads private DUT counters/memory or tracks
observed sync for resynchronization. Output sampling stays at +1 ns.

Intended controls and observed enabled edges have separate CSV streams and an
independent interval audit. A held enable permits a write per rising input clock,
without a handshake. Idempotent internal writes are not externally distinguished.
Current-pixel writes can change RGB without a raster advance. Pure assertions
sample changed signatures, control/reset events and every enabled write; the
scoreboard still checks every required input-clock observation.

## Executed evidence

Fresh normal GitHub cloning and explicit detached checkout passed
**37/37 required**, aggregate and actual outer wrapper exits **0**.
The source and DUT remained clean and all 14 execution-input hashes matched.
Results: **49 synthetic runner fixtures**, **six negative and four legal SVA
controls**, **30 principal scenarios plus eight unmodified passing
controls**, **8,622,612 observations / 51,735,672 comparisons**,
**9882 valid write edges / 14 ignored attempts**,
and **14 fault parents**. Every fault child exits 1 with exact diagnostics,
while all three tool commands exit 0 without timeout. The existing portable
`scripts/run_regression.ps1` gate separately passed **7 legacy checks**, **8 reset-edge
checks** and **29,588,940 raster comparisons**.

The main run checks two initial uninterrupted frames, all 4,800 entries with
two address-distinguishing patterns, all 256 bytes, all divider phases, current /
previous / future writes, blanking, reset/write overlaps and recovery.
These are procedural checks, not coverage percentages.

[Immutable summary](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/4ca72a17e0dca3ffed9edf5b65ffa025ee8740af/reports/vga-uvm-2026-11-11/SUMMARY.md), [raw results](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/4ca72a17e0dca3ffed9edf5b65ffa025ee8740af/reports/vga-uvm-2026-11-11/run/results.json),
[source/input hashes](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/4ca72a17e0dca3ffed9edf5b65ffa025ee8740af/reports/vga-uvm-2026-11-11/SOURCE_LOCKS.json), [wrapper exit](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/4ca72a17e0dca3ffed9edf5b65ffa025ee8740af/reports/vga-uvm-2026-11-11/wrapper.json),
and [byte audit](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/4ca72a17e0dca3ffed9edf5b65ffa025ee8740af/reports/vga-uvm-2026-11-11/BYTE_AUDIT.json) record real commands, tools, seeds and
all expected-negative/fault results. Five measured public-pin waveform figures
and one **simulation-reconstructed frame** identify their exact raw inputs,
time windows, renderer commands and hashes. Figure axes are relative to an
explicit absolute capture offset; original bytes are preserved with scoped -text.
The image uses actual RGB samples multiplied by 17, not reference memory.

## Reproduce

Use the qualified Questa 2025.2 / QUESTA_UVM-1.2.3 installation and ModelSim
2020.1 portable configuration in the [full reproduction guide](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/4ca72a17e0dca3ffed9edf5b65ffa025ee8740af/reports/vga-uvm-2026-11-11/REPRODUCE.md).
Choose unused short paths and keep the host awake:

```powershell
$python = 'C:\Users\CG\AppData\Local\Python\pythoncore-3.14-64\python.exe'
git clone --config core.longpaths=true --config core.autocrlf=false https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification.git C:\short\vga-uvm-source-new
git -C C:\short\vga-uvm-source-new checkout --detach 3afa2912076b6e7dadf6c958d444e2dc9a2a87f4
& $python C:\short\vga-uvm-source-new\scripts\run_vga_uvm.py --expected-env-sha 3afa2912076b6e7dadf6c958d444e2dc9a2a87f4 --output C:\short\vga-uvm-results-new
if ($LASTEXITCODE -ne 0) { throw 'Required VGA milestone failed or was blocked' }
```

## Preserved attribution and limits

Original reference projects were jointly developed by M. Roohan Khan and Talib,
per owner confirmation. Existing licences, notices, source history, artwork,
attribution and all historical reports are preserved. `SOURCE_PROVENANCE.json`,
`SOURCE_README.md` and `LICENSE_STATUS.md` remain unchanged. No blanket licence
is assigned to inherited material. Both milestone PRs remain open and unmerged.

Functional coverage, constrained randomization and original licence-blocked
advanced ALU/APB environments remain **NOT RUN**. There is no external SRAM bus,
exposed pixel clock, double buffering or frame-update atomicity. Input period
10 ns is a simulation assumption; no physical pixel frequency or refresh rate
is established. Physical display compatibility, board clocks, new resolutions,
coverage closure, synthesis, timing, FPGA and hardware remain separate milestones.
