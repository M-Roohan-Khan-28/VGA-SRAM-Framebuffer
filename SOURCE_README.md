# VGA controller with SRAM framebuffer

A coursework exercise with the original SystemVerilog design and testbench.

## Run

From this project folder, with ModelSim/Questa on PATH:

```powershell
powershell -NoProfile -File scripts/run_sim.ps1
```

On Linux or Git Bash: `bash sim/run.sh`.

The test module is `tb_vga_controller_sram`. Compilation and simulation logs are saved under `reports/`. Read the test output before treating a run as verified: a simulator exit alone is not proof that every check passed.

## Files

- [RTL](rtl/design.sv)
- [Testbench](tb/tb_top.sv)
- [Verification notes](docs/verification_plan.md)
- [Report status](reports/README.md)
- [Waveform notes](waves/README.md)

