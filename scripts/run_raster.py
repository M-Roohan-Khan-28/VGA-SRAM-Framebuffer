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


def observed_tick(trace, signal, value):
    """Locate a measured model-coordinate transition in the simulator VCD."""
    code = trace.signals["vga_raster_test." + signal].code
    for tick, bits in trace.events[code]:
        if "x" not in bits.lower() and "z" not in bits.lower() and int(bits, 2) == value:
            return tick
    raise RuntimeError("VCD coordinate not observed: %s=%d" % (signal, value))


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
    parser.add_argument("--reset-write-only", action="store_true",
                        help="run only the asynchronous-reset pending-write qualification")
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
            ("reset-write-edge", "vga_raster_test", ["+RESET_WRITE_EDGE"],
             "VGA_RESET_WRITE_EDGE_PASS checks=8 reset_held=1", r"reset_held=1"),
            ("raster", "vga_raster_test", [],
             "VGA_RASTER_PASS checks=", r"frames=2 writes=258 invalid=2 resets=4 seed=all256"),
        ]
        if args.reset_write_only:
            cases = cases[1:2]
        elif args.raster_only:
            cases = cases[2:]
        wave_modes = ("horizontal", "vertical", "write", "frame")
        if args.capture_wave:
            for mode in wave_modes:
                cases.append(("wave-" + mode, "vga_raster_test",
                              ["+WAVE_" + mode.upper()],
                              "VGA_WAVE_PASS mode=" + mode + " checks=", r"checks=\d+"))
        for label, top, extra, marker, detail in cases:
            do = "run -all; quit -code 0"
            if label.startswith("wave-"):
                pins = "clk reset sram_we sram_addr sram_data_in hsync vsync active_video red green blue rh rv rd frames".split()
                private = "clock_divider h_count v_count read_address pixel_data".split()
                do = ("run -all; vcd file " + label + ".vcd; " + "; ".join(
                    ["vcd add /vga_raster_test/" + pin for pin in pins] +
                    ["vcd add /vga_raster_test/dut/" + pin for pin in private]) +
                    "; run -all; quit -code 0")
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
            if label.startswith("wave-") and len(re.findall(
                    re.escape("VGA_WAVE_ARM mode=" + label[5:]), log)) != 1:
                raise RuntimeError(label + " did not stop at the requested boundary")
            item["status"] = "PASS"
            item["marker"] = next(line for line in log.splitlines() if marker in line)
            print("PASS " + item["marker"])
        if args.capture_wave:
            report["waveforms"] = []
            selected = {
                "horizontal": ("clk hsync active_video red* green* blue* rh rv",
                               "clock_divider h_count v_count pixel_data"),
                "vertical": ("clk vsync active_video rh rv",
                             "clock_divider h_count v_count"),
                "write": ("clk sram_we sram_addr sram_data_in active_video red* green* blue* rh rv",
                          "h_count v_count read_address pixel_data"),
                "frame": ("clk hsync vsync active_video red* green* blue* rh rv frames",
                          "clock_divider h_count v_count"),
            }
            titles = {
                "horizontal": "Measured VGA visible row and HSYNC boundaries",
                "vertical": "Measured VGA vertical blank and VSYNC boundaries",
                "write": "Measured framebuffer write through displayed pixel",
                "frame": "Measured VGA frame wrap",
            }
            for mode in wave_modes:
                label = "wave-" + mode
                vcd = out / (label + ".vcd")
                if not vcd.is_file() or not vcd.stat().st_size:
                    raise RuntimeError(label + " VCD missing")
                report["waveforms"].append({"mode": mode, "path": str(vcd),
                                             "sha256": hashlib.sha256(vcd.read_bytes()).hexdigest()})
                sys.path.insert(0, str(root / "tools"))
                from vcd_to_svg import parse_vcd
                trace = parse_vcd(vcd)
                public, private = selected[mode]
                signals = ["vga_raster_test." + p for p in public.split()]
                signals += ["vga_raster_test.dut." + p for p in private.split()]
                windows = [(mode, trace.events[next(iter(trace.events))][0][0], trace.last_tick)]
                if mode == "horizontal":
                    windows = [
                        ("horizontal-active", observed_tick(trace, "rh", 638),
                         observed_tick(trace, "rh", 658)),
                        ("horizontal-sync-end", observed_tick(trace, "rh", 750),
                         observed_tick(trace, "rh", 754)),
                    ]
                elif mode == "vertical":
                    windows = []
                    for name, line in (("vertical-sync-start", 490),
                                       ("vertical-sync-end", 492)):
                        tick = observed_tick(trace, "rv", line)
                        windows.append((name, tick - 120000, tick + 120000))
                for name, start, end in windows:
                    if start < 0 or end > trace.last_tick or start >= end:
                        raise RuntimeError(name + " measured VCD window invalid")
                    render = [sys.executable, str(root / "tools/vcd_to_svg.py"),
                              "--vcd", str(vcd), "--signals", *signals,
                              "--start", str(start), "--end", str(end),
                              "--output", str(out / (name + ".svg")),
                              "--origin", "simulator", "--title", titles[mode]]
                    if invoke(render, out, out / ("render-" + name + ".log"))[0]:
                        raise RuntimeError(name + " VCD rendering failed")
                    report["waveforms"][-1].setdefault("figures", []).append(
                        {"name": name, "start_tick": start, "end_tick": end,
                         "path": str(out / (name + ".svg"))})
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
