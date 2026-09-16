"""Compare a new capture against a reference screenshot.

Metrics are computed on a shared size (reference size by default):
  - mean absolute error (0-255)
  - percentage of pixels differing by more than `tolerance`
  - PSNR in dB (inf when identical)

Also writes a side-by-side PNG and an amplified diff heatmap for review.

Use from the project root::

    source .venv/bin/activate
    python tools/capture/compare.py --ref captures/<phone_menu>.jpg \\
        --new captures/new/menu.png --out-dir captures/new --tag menu
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageChops
except ImportError:
    print("Pillow is required: source .venv/bin/activate && pip install pillow")
    raise SystemExit(2)


def compare(
    ref: str,
    new: str,
    out_dir: str,
    tag: str = "shot",
    tolerance: float = 12.0,
    max_size: tuple[int, int] | None = None,
) -> dict[str, float | str]:
    """Compare two images and write review artifacts. Returns metrics dict."""
    ref_path: Path = Path(ref)
    new_path: Path = Path(new)
    out: Path = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)

    ref_img: Image.Image = Image.open(ref_path).convert("RGB")
    new_img: Image.Image = Image.open(new_path).convert("RGB")
    if max_size is not None:
        ref_img.thumbnail(max_size)
        new_img.thumbnail(max_size)

    # Shared comparison size = reference size (phone screenshots are the spec).
    target: tuple[int, int] = ref_img.size
    new_rs: Image.Image = new_img.resize(target)

    diff: Image.Image = ImageChops.difference(ref_img, new_rs)
    hist = diff.histogram()
    total: int = target[0] * target[1]
    # Mean absolute error across all channels.
    mae: float = sum(i * n for ch in range(3) for i, n in enumerate(hist[ch * 256:(ch + 1) * 256])) / (total * 3)
    # Fraction of pixels whose max-channel diff exceeds tolerance.
    diff_gray = diff.convert("L")
    gray_hist = diff_gray.histogram()
    bad: int = sum(gray_hist[int(tolerance) + 1:])
    bad_pct: float = 100.0 * bad / total
    mse: float = sum(
        (a - b) ** 2
        for a, b in zip(ref_img.tobytes(), new_rs.tobytes())
    ) / (total * 3)
    psnr: float = float("inf") if mse == 0 else 10.0 * math.log10(255.0 * 255.0 / mse)

    side: Image.Image = Image.new("RGB", (target[0] * 2 + 8, target[1]), (30, 30, 30))
    side.paste(ref_img, (0, 0))
    side.paste(new_rs, (target[0] + 8, 0))
    side_path: Path = out / f"{tag}_side_by_side.png"
    side.save(side_path)

    heat: Image.Image = diff_gray.point(lambda v: min(255, int(v * 3)))
    heat_path: Path = out / f"{tag}_diff.png"
    heat.save(heat_path)

    metrics: dict[str, float | str] = {
        "mae": round(mae, 3),
        "bad_pct": round(bad_pct, 3),
        "psnr_db": round(psnr, 2) if psnr != float("inf") else "inf",
        "ref_size": f"{target[0]}x{target[1]}",
        "new_size": f"{new_img.size[0]}x{new_img.size[1]}",
        "side_by_side": str(side_path),
        "diff": str(heat_path),
    }
    print(f"[{tag}] MAE={metrics['mae']} bad>{tolerance}={metrics['bad_pct']}% PSNR={metrics['psnr_db']}dB")
    print(f"[{tag}] side-by-side: {side_path}")
    print(f"[{tag}] diff heatmap: {heat_path}")
    return metrics


def main(argv: list[str] | None = None) -> int:
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="Compare a capture against its reference screenshot."
    )
    parser.add_argument("--ref", required=True)
    parser.add_argument("--new", required=True)
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--tag", default="shot")
    parser.add_argument("--tolerance", type=float, default=12.0)
    args: argparse.Namespace = parser.parse_args(argv)
    compare(args.ref, args.new, args.out_dir, args.tag, args.tolerance)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
