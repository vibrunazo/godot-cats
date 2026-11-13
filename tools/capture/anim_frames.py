"""Contact sheet of a cat animation at chosen times (wraps anim_frames.gd).

Example:
    python tools/capture/anim_frames.py --anim knock_over --call up_teacup \
        --times 0,0.1,0.2,0.3 --output captures/new/knock.png
Needs a display (the viewport is read back), so no --headless.
"""

from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run_godot import run_godot  # noqa: E402


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--scene", default="res://scenes/cats/Cat01.tscn")
    p.add_argument("--anim", default="attack")
    p.add_argument("--call", default="", help="method to call on the cat first, e.g. up_teacup")
    p.add_argument("--times", default="0,0.1,0.2,0.3,0.4,0.5,0.6,0.7")
    p.add_argument("--output", default="captures/new/anim.png")
    p.add_argument("--cell", type=int, default=220, help="cell size in screen pixels")
    p.add_argument("--zoom", type=float, default=2.0)
    p.add_argument("--columns", type=int, default=6)
    p.add_argument("--timeout", type=float, default=60.0)
    a = p.parse_args()

    os.makedirs(os.path.dirname(os.path.abspath(a.output)), exist_ok=True)
    user_args = [
        f"scene={a.scene}", f"anim={a.anim}", f"times={a.times}", f"output={a.output}",
        f"cell={a.cell}", f"zoom={a.zoom}", f"columns={a.columns}",
    ]
    if a.call:
        user_args.append(f"call={a.call}")
    res = run_godot(["--path", ".", "-s", "res://tools/capture/anim_frames.gd", "--", *user_args], timeout=a.timeout)
    out = (res.stdout + res.stderr).strip()
    print("\n".join(line for line in out.splitlines() if "anim_frames" in line or "ERROR" in line or "SCRIPT" in line))
    return 1 if res.timed_out else res.returncode


if __name__ == "__main__":
    sys.exit(main())
