param([string]$OutputDir = '', [switch]$CaptureWave)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$out = if ($OutputDir) {
    if ([IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $root $OutputDir }
} else { Join-Path ([IO.Path]::GetTempPath()) ("vga-raster-" + [guid]::NewGuid().ToString('N')) }
$py = Get-Command py.exe -ErrorAction SilentlyContinue
if ($py) { $command = $py.Source; $arguments = @('-3', (Join-Path $PSScriptRoot 'run_raster.py'), '--output-dir', $out) }
else {
    $python = Get-Command python3.exe -ErrorAction SilentlyContinue
    if (-not $python) { throw 'Python 3.9+ is required' }
    $command = $python.Source
    $arguments = @((Join-Path $PSScriptRoot 'run_raster.py'), '--output-dir', $out)
}
if ($CaptureWave) { $arguments += '--capture-wave' }
& $command @arguments
$code = $LASTEXITCODE
if ($code -ne 0) { exit $code }
Write-Output "VGA_RASTER_REGRESSION_PASS output=$out"
