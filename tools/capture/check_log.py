"""Project Godot log checker: fails on SCRIPT ERROR / parse errors / warnings.

Scans Godot stdout+stderr for error signatures so headless runs can gate
migration work. Exit 0 = clean, 1 = problems found, 124 = engine timeout.

Use::

    source .venv/bin/activate
    python tools/capture/check_log.py --timeout 60 -- --headless --path . --quit-after 200
    python tools/capture/check_log.py --timeout 60 -- --headless --path . --import
"""

from __future__ import annotations

import argparse
import re
import sys

from run_godot import run_godot

PATTERNS: list[tuple[str, str]] = [
    ("script_error", r"SCRIPT ERROR"),
    ("parse_error", r"Parse Error|Parse error"),
    ("failed_load", r"Failed to load script|not compiling"),
    ("engine_error", r"^ERROR:"),
    ("shader_error", r"SHADER ERROR|Shader compilation failed"),
    ("warning", r"^WARNING:"),
]

# Known engine-shutdown noise, not game defects: quitting while audio plays
# (music/sfx) leaves playback objects alive at exit even in clean projects.
# Filtered by default; pass --strict-noise to treat them as failures.
NOISE: list[str] = [
    "leaked at exit",
    "still in use at exit",
    "Orphan StringName",
    "unclaimed string",
    "were leaked",
    "RIDs of type",
]


def check(
    args: list[str],
    timeout: float,
    godot: str | None,
    strict_noise: bool = False,
) -> int:
    result = run_godot(args, timeout=timeout, godot=godot)
    text: str = (result.stdout or "") + "\n" + (result.stderr or "")
    if not strict_noise:
        text = "\n".join(
            line for line in text.splitlines() if not any(n in line for n in NOISE)
        )
    hits: dict[str, int] = {}
    for name, pat in PATTERNS:
        found: list[str] = re.findall(pat, text, re.MULTILINE)
        if found:
            hits[name] = len(found)
    # Echo the log so failures are inspectable.
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    if result.timed_out:
        print(f"check_log TIMED OUT after {timeout}s: {args}")
        return 124
    if hits:
        print(f"check_log FAIL {hits}")
        return 1
    if result.returncode != 0:
        print(f"check_log FAIL engine rc={result.returncode}")
        return 1
    print("check_log OK: no errors or warnings")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="Fail when Godot output contains errors or warnings."
    )
    parser.add_argument("--timeout", type=float, default=120.0)
    parser.add_argument("--godot", default=None)
    parser.add_argument("--strict-noise", action="store_true",
                        help="Also fail on engine-shutdown noise (audio leaks at exit).")
    parser.add_argument("engine_args", nargs=argparse.REMAINDER)
    args: argparse.Namespace = parser.parse_args(argv)
    engine: list[str] = list(args.engine_args)
    if engine and engine[0] == "--":
        engine = engine[1:]
    if not engine:
        parser.error("pass engine args after --, e.g. -- --headless --path . --import")
    return check(engine, args.timeout, args.godot, args.strict_noise)


if __name__ == "__main__":
    raise SystemExit(main())
