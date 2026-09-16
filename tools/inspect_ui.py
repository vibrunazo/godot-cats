"""CLI tool to inspect Godot Control UI hierarchy, layout modes, anchors, and bounding rects.

Useful for debugging layout alignment, anchors, and Godot 3 -> 4 migration issues.

Usage:
    python tools/inspect_ui.py res://scenes/UI/CircleButton.tscn
    python tools/inspect_ui.py res://scenes/maps/Map01.tscn --node UI/HUD/ActionBar
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

HERE: Path = Path(__file__).resolve().parent
PROJECT_ROOT: Path = HERE.parent
sys.path.insert(0, str(HERE / "capture"))

from run_godot import run_godot

HELPER: str = "res://tools/capture/ui_dump_helper.gd"


def inspect_ui(scene: str, node: str | None = None, frames: int = 10, timeout: float = 60.0) -> int:
    args: list[str] = ["--path", ".", "-s", HELPER, "--", f"scene={scene}", f"frames={frames}"]
    if node:
        args.append(f"node={node}")
    res = run_godot(args, timeout=timeout, cwd=str(PROJECT_ROOT))
    if res.stdout:
        # Filter for the UI Layout Dump section
        dumping = False
        for line in res.stdout.splitlines():
            if "--- UI Layout Dump:" in line:
                dumping = True
            if dumping:
                print(line)
            if "--- End UI Layout Dump ---" in line:
                dumping = False
        if not dumping and "--- UI Layout Dump:" not in res.stdout:
            # Fallback to full stdout if markers weren't matched
            sys.stdout.write(res.stdout)
    if res.stderr:
        sys.stderr.write(res.stderr)
    return res.returncode


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Inspect Godot UI Control layout and rects.")
    parser.add_argument("scene", help="Scene resource path (e.g. res://scenes/maps/Map01.tscn)")
    parser.add_argument("--node", help="Relative path to target Control node (e.g. UI/HUD/ActionBar)")
    parser.add_argument("--frames", type=int, default=10, help="Frames to wait before inspecting (default: 10)")
    parser.add_argument("--timeout", type=float, default=60.0, help="Timeout in seconds")
    args = parser.parse_args(argv)
    return inspect_ui(scene=args.scene, node=args.node, frames=args.frames, timeout=args.timeout)


if __name__ == "__main__":
    raise SystemExit(main())
