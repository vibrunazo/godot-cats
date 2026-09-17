"""Narrow check: no dead Godot 3 particle property names remain.

Godot 4's ParticleProcessMaterial silently ignores Godot 3 property names
(scalar `initial_velocity =` instead of `initial_velocity_min/max`, the
`*_random` modifiers, and the `flag_*` names), which zeroed particle
velocities after the 3 -> 4 migration. Scans every .tscn/.tres under
scenes/ and resources/, inside particle material blocks only, so node
properties with the same names (e.g. a Sprite2D `scale =`) do not
false-positive. Exit 0 when clean, 1 with a list of offenders.
"""

import re
from pathlib import Path

ROOT: Path = Path(__file__).resolve().parents[3]
SCAN_DIRS: tuple[str, ...] = ("scenes", "resources")

# Exact scalar forms that are dead in Godot 4 (must be _min/_max pairs).
SCALARS: re.Pattern[str] = re.compile(
    r"^(?:initial_velocity|damping|angle|scale|angular_velocity|orbit_velocity) *= *(?:\d|-)",
    re.M,
)
# The Godot 3 `_random` modifier properties have no Godot 4 equivalent.
RANDOMS: re.Pattern[str] = re.compile(
    r"^(?:initial_velocity|damping|angle|scale|angular_velocity|orbit_velocity)_random *=",
    re.M,
)
# Godot 3 flag names were renamed with a `particle_` prefix in Godot 4.
FLAGS: re.Pattern[str] = re.compile(r"^flag_(?:disable_z|align_y|rotate_y) *=", re.M)

BLOCK_MARKERS: tuple[str, ...] = (
    '[sub_resource type="ParticleProcessMaterial"',
    '[sub_resource type="ParticlesMaterial"',
)


def material_blocks(text: str) -> list[str]:
    """Text of each particle material block, bounded by the next section."""
    blocks: list[str] = []
    for marker in BLOCK_MARKERS:
        start: int = 0
        while True:
            index: int = text.find(marker, start)
            if index == -1:
                break
            ends: list[int] = [
                j
                for j in (
                    text.find("\n[sub_resource", index + 1),
                    text.find("\n[node", index + 1),
                    text.find("\n[resource", index + 1),
                )
                if j != -1
            ]
            end: int = min(ends) if ends else len(text)
            blocks.append(text[index:end])
            start = index + 1
    return blocks


def main() -> int:
    problems: list[str] = []
    for directory in SCAN_DIRS:
        for path in sorted((ROOT / directory).rglob("*")):
            if path.suffix not in (".tscn", ".tres"):
                continue
            for block in material_blocks(path.read_text(errors="ignore")):
                for pattern, label in (
                    (SCALARS, "scalar (needs _min/_max)"),
                    (RANDOMS, "dead _random property"),
                    (FLAGS, "dead Godot 3 flag"),
                ):
                    for match in pattern.finditer(block):
                        problems.append(
                            f"{path.as_posix()}: {label}: {match.group(0).strip()}"
                        )
    if problems:
        print("\n".join(problems))
        return 1
    print("CLEAN: no dead Godot 3 particle properties in scenes/ or resources/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
