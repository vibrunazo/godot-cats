# tools/capture — reusable Godot screenshot + log tooling (Godot 4.7, project-local `.venv`).

# Setup (once, from the project root)
```sh
python3 -m venv .venv
source .venv/bin/activate
pip install pillow
```

# Capture (needs a real display — do NOT use --headless here)
```sh
source .venv/bin/activate
python tools/capture/capture.py --scene res://scenes/maps/MainScene.tscn --output captures/new/menu.png --wait-frames 180
python tools/capture/capture.py --scene res://scenes/maps/Map01.tscn --output captures/new/level1.png --wait-frames 240
```

How it works: `capture.py` runs `godot --path . -s res://tools/capture/cap_helper.gd --
scene=<tscn> output=<png> wait_frames=<n>`. The helper (`cap_helper.gd`,
`extends SceneTree`, quits explicitly) loads the scene, waits N process
frames, saves `root.get_texture().get_image()` to PNG, and quits. All
subprocess calls use `shell=False` with a hard timeout and resolve the
binary via `shutil.which("godot")`.

# Compare against the phone references
```sh
source .venv/bin/activate
python tools/capture/compare.py --ref captures/<phone_menu>.jpg --new captures/new/menu.png --out-dir captures/new --tag menu
python tools/capture/compare.py --ref captures/<phone_level>.jpg --new captures/new/level1.png --out-dir captures/new --tag level1
```

Writes `<tag>_side_by_side.png` + `<tag>_diff.png` and prints MAE / bad-pixel % / PSNR.

# Gate headless runs for errors/warnings
```sh
source .venv/bin/activate
python tools/capture/check_log.py --timeout 60 -- --headless --path . --import
python tools/capture/check_log.py --timeout 60 -- --headless --path . --quit-after 200
```

Exit 0 = clean, 1 = error/warning signatures found, 124 = timeout.

# Gameplay regression tests (SceneTree harnesses, run with a display)
```sh
source .venv/bin/activate
godot --path . -s res://tools/capture/playtest_combat.gd   # build/spend/spawn/kill/rewards/pause
godot --path . -s res://tools/capture/playtest_upgrades.gd # upgrade popup/delete refund/game over
```
Both print `PLAYTEST* ... ok` lines and finish with `RESULT: PASS`.
`playtest_combat.gd` also saves `captures/new/combat.png`.

# Files
- `run_godot.py` — shared runner (hard timeout, `shell=False`, `shutil.which`).
- `cap_helper.gd` — SceneTree capture script (loads scene, waits, saves PNG, `quit()`).
- `capture.py` — display capture CLI.
- `compare.py` — Pillow reference comparison + review artifacts.
- `check_log.py` — headless error/warning gate (filters engine-shutdown
  audio noise by default; `--strict-noise` disables the filter).
- `playtest_combat.gd`, `playtest_upgrades.gd` — gameplay regression harnesses.
