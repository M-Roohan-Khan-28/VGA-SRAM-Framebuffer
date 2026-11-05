$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    if (!(Test-Path work)) { & vlib work; if ($LASTEXITCODE) { throw 'Library creation failed' } }
    & vlog -sv -f sim/filelist.f 2>&1 | Tee-Object reports/compile.log
    if ($LASTEXITCODE) { throw 'Compilation failed' }
    & vsim -c -onfinish exit tb_vga_controller_sram -do 'onerror {quit -code 1}; run -all; quit -code 0' 2>&1 | Tee-Object reports/simulation.log
    if ($LASTEXITCODE) { throw 'Simulation failed' }
    $simulation = Get-Content -Raw reports/simulation.log
    if ($simulation -match '(?im)\*\*\s+(Error|Fatal)|TOTAL FAILED\s*=\s*[1-9]|Errors:\s*[1-9]' -or $simulation -notmatch '\$finish') {
        throw 'Simulation did not complete successfully; inspect reports/simulation.log'
    }
} finally { Pop-Location }
