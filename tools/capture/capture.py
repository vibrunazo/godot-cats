"""Capture in-game screenshots by running Godot with a real display.

Uses the SceneTree helper (cap_helper.gd) which loads a scene, waits N
frames, saves the viewport to PNG, and quits. Must run with rendering
enabled (no --headless): the engine opens a window briefly.

Typical use from the project root::

    source .venv/bin/activate
    python tools/capture/capture.py --scene res://scenes/maps/MainScene.tscn \\
        --output captures/new/menu.png --wait-frames 180
    python tools/capture/capture.py --scene res://scenes/maps/Map01.tscn \\
        --output captures/new/level1.png --wait-frames 240
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from run_godot import run_godot

HERE: Path = Path(__file__).resolve().parent
PROJECT_ROOT: Path = HERE.parent.parent
HELPER: str = "res://tools/capture/cap_helper.gd"


def capture(
    scene: str,
    output: str,
    wait_frames: int = 180,
    timeout: float = 120.0,
    godot: str | None = None,
    resolution: str | None = None,
    extra_args: list[str] | None = None,
) -> int:
    """Run Godot once and save a screenshot. Returns the engine exit code."""
    out_path: Path = Path(output)
    if not out_path.is_absolute():
        out_path = PROJECT_ROOT / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        res_output: str = "res://" + out_path.relative_to(PROJECT_ROOT).as_posix()
    except ValueError:
        res_output = out_path.as_posix()

    # NOTE (WSL + Windows engine): the engine cannot parse /mnt/... absolute
    # paths, so use --path with a relative dot plus cwd instead.
    args: list[str] = ["--path", ".", "-s", HELPER, "--"]
    args += [f"scene={scene}", f"output={res_output}", f"wait_frames={wait_frames}"]
    if resolution:
        args = ["--resolution", resolution] + args
    if extra_args:
        args += list(extra_args)

    result = run_godot(args, timeout=timeout, godot=godot, cwd=str(PROJECT_ROOT))
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    if result.timed_out:
        print(f"capture TIMED OUT after {timeout}s: {scene} -> {out_path}")
        return 124
    if result.returncode != 0:
        print(f"capture FAILED rc={result.returncode}: {scene} -> {out_path}")
    elif not out_path.exists():
        print(f"capture FAILED: no file written at {out_path}")
        return 1
    else:
        print(f"capture OK: {scene} -> {out_path}")
    return result.returncode


def main(argv: list[str] | None = None) -> int:
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="Capture a Godot scene to PNG with a real display."
    )
    parser.add_argument("--scene", required=True, help="Scene path, e.g. res://scenes/maps/MainScene.tscn")
    parser.add_argument("--output", required=True, help="Output PNG path")
    parser.add_argument("--wait-frames", type=int, default=180)
    parser.add_argument("--timeout", type=float, default=120.0)
    parser.add_argument("--godot", default=None)
    parser.add_argument("--resolution", default=None, help="WxH, e.g. 1664x768")
    args: argparse.Namespace = parser.parse_args(argv)
    return capture(
        scene=args.scene,
        output=args.output,
        wait_frames=args.wait_frames,
        timeout=args.timeout,
        godot=args.godot,
        resolution=args.resolution,
    )


if __name__ == "__main__":
    raise SystemExit(main())
