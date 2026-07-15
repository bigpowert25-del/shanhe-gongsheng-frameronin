#!/usr/bin/env python3
"""Fast validation for the generated motion-sheet contract."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    manifest = json.loads((ROOT / "art_pipeline" / "manifest.json").read_text(encoding="utf-8"))
    catalog = json.loads((ROOT / "assets" / "generated" / "actors.json").read_text(encoding="utf-8"))
    frame_w, frame_h = manifest["frame_size"]
    columns, rows = manifest["grid"]
    actors = manifest["actors"]
    assert len(actors) == 11
    assert set(catalog["animations"]) == {"idle", "walk", "attack", "hurt"}
    assert len(catalog["actors"]) == len(actors)
    for actor in actors:
        actor_id = actor["id"]
        assert actor_id in catalog["actors"]
        output = ROOT / actor["output"]
        with Image.open(output) as image:
            assert image.size == (frame_w * columns, frame_h * rows)
            assert image.mode == "RGBA"
            assert image.getchannel("A").getextrema()[0] == 0
    print("PIPELINE_TEST_PASS actors=11 animations=4 grid=4x4")


if __name__ == "__main__":
    main()
