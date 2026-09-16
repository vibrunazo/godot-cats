"""Shared Godot process runner.

Resolves the engine binary dynamically, always uses shell=False, and
enforces a hard timeout so hangs from compilation issues, cyclic
preloads, or runtime exceptions cannot block callers.
"""

from __future__ import annotations

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
    cmd: list[str] = [binary] + list(args)
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
