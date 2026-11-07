# VGA reset-edge release evidence

Clean detached GitHub branch clone source:
`e790d1f1caf0f8650352a251465b214a66159a36`.
ModelSim Intel FPGA Starter Edition:
`vsim 2020.1 Simulator 2020.02 Feb 28 2020`.
Deterministic raster stimulus: all 256 RGB332 bytes; no random seed.

| Run | Actual result | Wrapper exit |
| --- | --- | ---: |
| Preserved original bench | 7 checks PASS | 0 |
| New asynchronous reset with two pending writes | 8 temporal checks PASS | 0 |
| Independent two-frame public-pin raster oracle | 29,588,940 comparisons PASS | 0 |
| Disposable old-oracle control with the new test | `VGA_RESET_WRITE_EARLY` at 33 ns, model `5a`, DUT `1c` | 1 |

The old-oracle control restored only the reference model's former
reset-edge write behavior in a disposable worktree. Its mutated bench,
`results.json`, and raw simulator log are under `old-oracle-control/`.
ModelSim reported a fatal but returned process exit 0; the wrapper rejected
the fatal and missing PASS marker. No DUT RTL was changed. The corrected
clean-clone `results.json` and three simulation logs are under `clean-clone/`.
Earlier reports and VCDs remain in place. The boundary figure JSON and
captions distinguish original CRLF simulator-capture hashes from committed
LF Git VCD hashes; this byte change does not change simulation events.

Reproduce with fresh destinations:

```powershell
git -c core.longpaths=true -c core.autocrlf=false clone --branch technical/vga-raster-contract https://github.com/M-Roohan-Khan-28/VGA-SRAM-Framebuffer.git C:\short\vga-release-new
git -C C:\short\vga-release-new config core.autocrlf false
git -C C:\short\vga-release-new checkout --detach e790d1f1caf0f8650352a251465b214a66159a36
$env:MODELSIM_BIN = 'C:\intelFPGA\20.1\modelsim_ase\win32aloem'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\short\vga-release-new\scripts\run_regression.ps1 -OutputDir C:\short\vga-release-output-new
if ($LASTEXITCODE -ne 0) { throw 'VGA regression failed or blocked' }
```
