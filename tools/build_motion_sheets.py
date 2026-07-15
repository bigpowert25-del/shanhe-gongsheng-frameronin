#!/usr/bin/env python3
"""Build normalized 4x4 motion sheets for the Godot runtime.

FrameRonin exports placed in art_pipeline/inbox take priority. When an export is
missing, a deterministic starter sheet is derived from the original cutout.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from shutil import copy2

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "art_pipeline" / "manifest.json"


POSES = {
    "idle": [
        (0.0, 1.000, 1.000, 0, 0),
        (0.4, 1.006, 0.993, 0, 1),
        (0.0, 1.010, 0.985, 0, 2),
        (-0.4, 1.006, 0.993, 0, 1),
    ],
    "walk": [
        (-2.2, 0.985, 1.010, -3, 1),
        (0.8, 1.012, 0.982, 2, 4),
        (2.2, 0.985, 1.010, 3, 1),
        (-0.8, 1.012, 0.982, -2, 4),
    ],
    "attack": [
        (-7.0, 0.970, 1.015, -7, 1),
        (-2.0, 1.020, 0.985, 1, 2),
        (11.0, 1.045, 0.960, 11, 5),
        (3.0, 1.010, 0.990, 5, 3),
    ],
    "hurt": [
        (0.0, 1.000, 1.000, 0, 0),
        (-7.0, 0.980, 1.005, -7, 4),
        (6.0, 0.980, 1.005, 7, 3),
        (0.0, 1.000, 1.000, 0, 1),
    ],
}


def load_manifest() -> dict:
    with MANIFEST_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def crop_visible(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").getbbox()
    if not bbox:
        raise ValueError("source image has no visible pixels")
    return rgba.crop(bbox)


def fit_subject(subject: Image.Image, frame_w: int, frame_h: int) -> Image.Image:
    scale = min(frame_w * 0.82 / subject.width, frame_h * 0.91 / subject.height)
    size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
    return subject.resize(size, Image.Resampling.LANCZOS)


def pose_frame(base: Image.Image, frame_w: int, frame_h: int, pose: tuple) -> Image.Image:
    angle, scale_x, scale_y, offset_x, offset_y = pose
    width = max(1, round(base.width * scale_x))
    height = max(1, round(base.height * scale_y))
    actor = base.resize((width, height), Image.Resampling.LANCZOS)
    actor = actor.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    x = round((frame_w - actor.width) * 0.5 + offset_x)
    y = round(frame_h - actor.height - frame_h * 0.025 + offset_y)
    frame.alpha_composite(actor, (x, y))
    return frame


def build_fallback(source: Path, target: Path, frame_size: tuple[int, int], animations: dict) -> None:
    frame_w, frame_h = frame_size
    original = crop_visible(Image.open(source))
    base = fit_subject(original, frame_w, frame_h)
    sheet = Image.new("RGBA", (frame_w * 4, frame_h * 4), (0, 0, 0, 0))
    for name, animation in sorted(animations.items(), key=lambda item: item[1]["row"]):
        row = int(animation["row"])
        poses = POSES[name]
        for column, pose in enumerate(poses):
            frame = pose_frame(base, frame_w, frame_h, pose)
            sheet.alpha_composite(frame, (column * frame_w, row * frame_h))
    target.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(target, compress_level=6)


def validate_sheet(path: Path, expected_size: tuple[int, int]) -> None:
    with Image.open(path) as sheet:
        if sheet.size != expected_size:
            raise ValueError(
                f"{path.relative_to(ROOT)} size is {sheet.size[0]}x{sheet.size[1]}, "
                f"expected {expected_size[0]}x{expected_size[1]}"
            )
        if sheet.mode not in ("RGBA", "LA", "P"):
            raise ValueError(f"{path.relative_to(ROOT)} must contain transparency")
        if sheet.mode != "P" and sheet.getchannel("A").getextrema()[0] == 255:
            raise ValueError(f"{path.relative_to(ROOT)} has no transparent background")


def is_same_file(left: Path, right: Path) -> bool:
    if not left.exists() or not right.exists() or left.stat().st_size != right.stat().st_size:
        return False
    with Image.open(left) as a, Image.open(right) as b:
        return ImageChops.difference(a.convert("RGBA"), b.convert("RGBA")).getbbox() is None


def build(strict_inbox: bool = False) -> dict:
    manifest = load_manifest()
    frame_size = tuple(int(value) for value in manifest["frame_size"])
    grid = tuple(int(value) for value in manifest["grid"])
    expected_size = (frame_size[0] * grid[0], frame_size[1] * grid[1])
    catalog = {
        "schema_version": manifest["schema_version"],
        "frame_size": list(frame_size),
        "grid": list(grid),
        "animations": manifest["animations"],
        "actors": {},
    }
    counts = {"frameronin": 0, "fallback": 0}
    for actor in manifest["actors"]:
        source = ROOT / actor["source"]
        inbox = ROOT / actor["inbox"]
        output = ROOT / actor["output"]
        if not source.exists():
            raise FileNotFoundError(source)
        if inbox.exists():
            validate_sheet(inbox, expected_size)
            output.parent.mkdir(parents=True, exist_ok=True)
            if not is_same_file(inbox, output):
                copy2(inbox, output)
            provider = "frameronin"
        else:
            if strict_inbox:
                raise FileNotFoundError(f"missing FrameRonin export: {inbox.relative_to(ROOT)}")
            build_fallback(source, output, frame_size, manifest["animations"])
            provider = "fallback"
        validate_sheet(output, expected_size)
        counts[provider] += 1
        catalog["actors"][actor["id"]] = {
            "kind": actor["kind"],
            "texture": "res://" + actor["output"],
            "provider": provider,
        }
        print(f"[{provider:11}] {actor['id']} -> {actor['output']}")

    catalog_path = ROOT / "assets" / "generated" / "actors.json"
    catalog_path.parent.mkdir(parents=True, exist_ok=True)
    with catalog_path.open("w", encoding="utf-8") as handle:
        json.dump(catalog, handle, ensure_ascii=False, indent=2, sort_keys=True)
        handle.write("\n")
    print(
        f"MOTION_SHEETS_OK actors={len(catalog['actors'])} "
        f"frameronin={counts['frameronin']} fallback={counts['fallback']}"
    )
    return catalog


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--strict-inbox",
        action="store_true",
        help="require a valid FrameRonin sheet for every actor",
    )
    args = parser.parse_args()
    build(strict_inbox=args.strict_inbox)


if __name__ == "__main__":
    main()
