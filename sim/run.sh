#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$0")/.."
mkdir -p reports
[[ -d work ]] || vlib work
vlog -sv -f sim/filelist.f | tee reports/compile.log
vsim -c -onfinish exit tb_vga_controller_sram -do 'onerror {quit -code 1}; run -all; quit -code 0' | tee reports/simulation.log
if grep -Eq '\*\* (Error|Fatal)|TOTAL FAILED *= *[1-9]|Errors: *[1-9]' reports/simulation.log || ! grep -Fq '$finish' reports/simulation.log; then
  echo 'Simulation did not complete successfully; inspect reports/simulation.log' >&2
  exit 1
fi
