#!/usr/bin/env python3
"""Fresh, bounded, result-aware VGA raster regression."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time


def tool(name):
    prefix = os.environ.get("MODELSIM_BIN")
    choices = ([str(Path(prefix) / (name + ".exe")), str(Path(prefix) / name)]
               if prefix else []) + [name, name + ".exe"]
    for candidate in choices:
        found = shutil.which(candidate)
        if found:
            return found
    raise RuntimeError("Missing simulator tool: " + name)


def invoke(argv, cwd, logpath, timeout=180):
    try:
        result = subprocess.run(argv, cwd=cwd, capture_output=True,
                                timeout=timeout, check=False)
    except subprocess.TimeoutExpired as exc:
        logpath.write_bytes((exc.stdout or b"") + (exc.stderr or b""))
        raise RuntimeError("Command timed out after %d seconds" % timeout) from exc
    raw = result.stdout + result.stderr
    logpath.write_bytes(raw)
    return result.returncode, raw.decode("utf-8", errors="replace")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--rtl", type=Path, help="disposable source override")
    parser.add_argument("--capture-wave", action="store_true")
    parser.add_argument("--raster-only", action="store_true",
                        help="fault qualification: run only the independent raster oracle")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = args.output_dir.resolve()
    if out.exists():
        raise RuntimeError("Output directory exists: " + str(out))
    out.mkdir(parents=True)
    rtl = (args.rtl or root / "rtl/design.sv").resolve()
    source = [rtl, root / "tb/tb_top.sv", root / "tb/vga_raster_test.sv"]
    report = {
        "repository": "VGA-SRAM-Framebuffer",
        "source_revision": subprocess.check_output(
            ["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip(),
        "source_dirty": bool(subprocess.check_output(
            ["git", "-C", str(root), "status", "--porcelain"])),
        "sources": [{"path": str(p), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
                    for p in source],
        "seed": "exhaustive RGB332 0..255", "timeout_seconds_per_command": 180,
        "simulations": [], "overall": "FAIL"
    }
    started = time.monotonic()
    try:
        vlib, vlog, vsim = (tool(n) for n in ("vlib", "vlog", "vsim"))
        report["simulator_version"] = invoke([vsim, "-version"], out,
                                              out / "version.log")[1].strip()
        if invoke([vlib, "work"], out, out / "library.log")[0]:
            raise RuntimeError("vlib failed")
        code, log = invoke([vlog, "-sv", *map(str, source)], out,
                           out / "compile.log")
        if code or "Errors: 0, Warnings: 0" not in log:
            raise RuntimeError("vlog failed or reported diagnostics")
        cases = [
            ("legacy", "tb_vga_controller_sram", [],
             "ALL VGA TESTS PASSED", r"TOTAL PASSED = 7"),
            ("raster", "vga_raster_test", [],
             "VGA_RASTER_PASS checks=", r"frames=2 writes=258 invalid=2 resets=4 seed=all256"),
        ]
        if args.raster_only:
            cases = cases[1:]
        if args.capture_wave:
            cases.append(("wave", "vga_raster_test", ["+WAVE_ONLY"],
                          "VGA_WAVE_PASS checks=", r"pixels=754"))
        for label, top, extra, marker, detail in cases:
            do = "run -all; quit -code 0"
            if label == "wave":
                pins = "clk reset sram_we sram_addr sram_data_in hsync vsync active_video red green blue".split()
                do = ("vcd file vga-raster.vcd; " + "; ".join(
                    "vcd add /vga_raster_test/" + pin for pin in pins) + "; " + do)
            argv = [vsim, "-c", "-onfinish", "exit", top, *extra, "-do", do]
            code, log = invoke(argv, out, out / (label + ".log"))
            item = {"top": top, "command": argv, "simulator_exit_code": code,
                    "status": "FAIL"}
            report["simulations"].append(item)
            if (code or re.search(r"\*\*\s+(?:Error|Fatal):", log) or
                    "# Errors: 0, Warnings: 0" not in log or "$finish" not in log or
                    len(re.findall(re.escape(marker), log)) != 1 or
                    not re.search(detail, log)):
                raise RuntimeError(label + " failed or marker/count missing")
            item["status"] = "PASS"
            item["marker"] = next(line for line in log.splitlines() if marker in line)
            print("PASS " + item["marker"])
        if args.capture_wave:
            vcd = out / "vga-raster.vcd"
            if not vcd.is_file() or not vcd.stat().st_size:
                raise RuntimeError("Requested VCD missing")
            report["waveform"] = {"path": str(vcd),
                                  "sha256": hashlib.sha256(vcd.read_bytes()).hexdigest()}
            signals = ["vga_raster_test." + p for p in
                       "clk reset sram_we sram_addr sram_data_in hsync vsync active_video red* green* blue*".split()]
            render = [sys.executable, str(root / "tools/vcd_to_svg.py"),
                      "--vcd", str(vcd), "--signals", *signals,
                      "--output", str(out / "vga-raster.svg"),
                      "--origin", "simulator", "--title", "Measured VGA row and HSYNC boundary"]
            if invoke(render, out, out / "render.log")[0]:
                raise RuntimeError("VCD rendering failed")
        report["overall"] = "PASS"
    except Exception as exc:
        report["error"] = str(exc)
        print("FAIL: " + str(exc), file=sys.stderr)
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - started, 3)
        (out / "results.json").write_text(json.dumps(report, indent=2) + "\n",
                                          encoding="utf-8")
    return 0 if report["overall"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
