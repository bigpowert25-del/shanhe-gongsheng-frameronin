#!/usr/bin/env python3
"""Build compact, phone-sized WebP assets for the no-WASM web client."""

from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "web_lite" / "assets"


def save_background(source: Path, target: Path) -> None:
    with Image.open(source) as raw:
        image = ImageOps.exif_transpose(raw).convert("RGB")
        image = ImageOps.fit(image, (1280, 720), method=Image.Resampling.LANCZOS)
        target.parent.mkdir(parents=True, exist_ok=True)
        image.save(target, "WEBP", quality=63, method=6)


def save_transparent(source: Path, target: Path, limit: tuple[int, int], quality: int) -> None:
    with Image.open(source) as raw:
        image = ImageOps.exif_transpose(raw).convert("RGBA")
        image.thumbnail(limit, Image.Resampling.LANCZOS)
        target.parent.mkdir(parents=True, exist_ok=True)
        image.save(target, "WEBP", quality=quality, method=6, exact=True)


def main() -> None:
    backgrounds = ROOT / "assets" / "backgrounds"
    for name in ("cover", "chapter_01", "chapter_02", "chapter_03", "chapter_04", "chapter_05", "chapter_06", "epilogue"):
        save_background(backgrounds / f"{name}.jpg", OUTPUT / "backgrounds" / f"{name}.webp")

    portraits = {
        "you": ROOT / "assets" / "characters" / "you.png",
        "ayan": ROOT / "assets" / "characters" / "ayan.png",
        "shenjin": ROOT / "assets" / "characters" / "shenjin.png",
        "qiaosheng": ROOT / "assets" / "characters" / "qiaosheng.png",
        "moyan": ROOT / "assets" / "enemies" / "boss_06.png",
    }
    for actor_id, source in portraits.items():
        save_transparent(source, OUTPUT / "portraits" / f"{actor_id}.webp", (640, 900), 70)

    generated = ROOT / "assets" / "generated"
    for folder in ("characters", "enemies"):
        for source in sorted((generated / folder).glob("*.png")):
            save_transparent(source, OUTPUT / "actors" / f"{source.stem}.webp", (768, 1152), 68)

    total = sum(path.stat().st_size for path in OUTPUT.rglob("*.webp"))
    print(f"WEB_LITE_ASSETS_PASS files={len(list(OUTPUT.rglob('*.webp')))} total={total / 1024 / 1024:.2f}MiB")


if __name__ == "__main__":
    main()
