"""Shared Godot process runner.

Resolves the engine binary dynamically, always uses shell=False, and
enforces a hard timeout so hangs from compilation issues, cyclic
preloads, or runtime exceptions cannot block callers.
"""

from __future__ import annotations

import os
import shutil
import subprocess
from dataclasses import dataclass


@dataclass
class RunResult:
    args: list[str]
    returncode: int
    stdout: str
    stderr: str
    timed_out: bool


def resolve_godot(godot: str | None = None) -> str:
    """Return the Godot binary path, resolving via PATH when not given."""
    if godot:
        return godot
    found: str | None = shutil.which("godot")
    if not found:
        raise FileNotFoundError(
            "Godot binary not found. Install Godot 4.7+ or pass --godot <path>."
        )
    # If on Windows and found is a batch wrapper (.cmd / .bat), resolve the underlying
    # .exe so that process timeouts terminate the engine directly rather than leaving
    # orphaned child processes holding open redirected pipe handles.
    if found.lower().endswith((".cmd", ".bat")):
        parent_dir: str = os.path.dirname(found)
        for candidate in (
            "Godot_v4.7.2-stable_win64_console.exe",
            "Godot_v4.7.2-stable_win64.exe",
        ):
            candidate_path: str = os.path.join(parent_dir, candidate)
            if os.path.isfile(candidate_path):
                return candidate_path
        try:
            for fname in os.listdir(parent_dir):
                if fname.lower().startswith("godot") and fname.lower().endswith(".exe"):
                    return os.path.join(parent_dir, fname)
        except OSError:
            pass
    return found


def run_godot(
    args: list[str],
    timeout: float = 120.0,
    godot: str | None = None,
    cwd: str | None = None,
) -> RunResult:
    """Run Godot with a hard timeout. Never uses shell=True.

    Args:
        args: Arguments after the binary (e.g. ["--headless", "--path", "."]).
        timeout: Hard wall-clock timeout in seconds.
        godot: Explicit binary path; resolved via shutil.which when None.
        cwd: Working directory for the child process.

    Returns:
        RunResult with combined output and a timed_out flag.
    """
    binary: str = resolve_godot(godot)
    cmd_args: list[str] = list(args)
    if "--headless" in cmd_args and not any(arg.startswith("--audio-driver") for arg in cmd_args):
        cmd_args.extend(["--audio-driver", "Dummy"])
    cmd: list[str] = [binary] + cmd_args
    try:
        proc: subprocess.CompletedProcess[str] = subprocess.run(
            cmd,
            shell=False,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=cwd,
        )
        return RunResult(
            args=cmd,
            returncode=proc.returncode,
            stdout=proc.stdout or "",
            stderr=proc.stderr or "",
            timed_out=False,
        )
    except subprocess.TimeoutExpired as exc:
        out: str = ""
        err: str = ""
        if exc.stdout:
            out = exc.stdout.decode() if isinstance(exc.stdout, bytes) else str(exc.stdout)
        if exc.stderr:
            err = exc.stderr.decode() if isinstance(exc.stderr, bytes) else str(exc.stderr)
        return RunResult(
            args=cmd,
            returncode=124,
            stdout=out,
            stderr=err,
            timed_out=True,
        )
