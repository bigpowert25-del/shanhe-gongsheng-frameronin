#!/usr/bin/env python3
"""Install only the Godot 4.7 release templates needed by this project.

Godot 4.7's official archive supports HTTP ranges. This mirrors the editor's
individual-template downloader so macOS/Windows/Web builds do not require fetching
the entire 1.2 GB template package.
"""

from __future__ import annotations

import argparse
import binascii
import struct
import sys
import urllib.request
import zlib
from pathlib import Path


ARCHIVE_URL = (
    "https://godot-releases.nbg1.your-objectstorage.com/4.7-stable/"
    "Godot_v4.7-stable_export_templates.tpz"
)
REQUEST_HEADERS = {"User-Agent": "Godot-Template-Installer/4.7", "Accept-Encoding": "identity"}
VERSION = "4.7.stable"
FILES = [
    "macos.zip",
    "windows_release_x86_64.exe",
    "windows_release_x86_64_console.exe",
    "web_nothreads_debug.zip",
    "web_nothreads_release.zip",
    "icudt_godot.dat",
]


def query_archive() -> tuple[str, int]:
    request = urllib.request.Request(ARCHIVE_URL, headers=REQUEST_HEADERS, method="HEAD")
    with urllib.request.urlopen(request, timeout=60) as response:
        length = int(response.headers["Content-Length"])
        return response.geturl(), length


def fetch_range(url: str, start: int, end: int, label: str) -> bytes:
    headers = dict(REQUEST_HEADERS)
    headers["Range"] = f"bytes={start}-{end}"
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=120) as response:
        if response.status != 206:
            raise RuntimeError(f"server ignored HTTP range for {label}: {response.status}")
        total = end - start + 1
        chunks: list[bytes] = []
        loaded = 0
        next_report = 10
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
            loaded += len(chunk)
            percent = int(loaded * 100 / total)
            if percent >= next_report:
                print(f"  {label}: {min(percent, 100)}%", flush=True)
                next_report = percent + 10
        data = b"".join(chunks)
        if len(data) != total:
            raise RuntimeError(f"incomplete range for {label}: {len(data)} of {total} bytes")
        return data


def central_directory(url: str, size: int) -> dict[str, dict]:
    tail_start = max(0, size - 0x10000)
    tail = fetch_range(url, tail_start, size - 1, "读取模板目录")
    eocd = tail.rfind(b"PK\x05\x06")
    if eocd < 0:
        raise RuntimeError("export template archive has no end-of-directory record")
    total_entries = struct.unpack_from("<H", tail, eocd + 10)[0]
    directory_offset = struct.unpack_from("<I", tail, eocd + 16)[0]
    cursor = directory_offset - tail_start
    entries: dict[str, dict] = {}
    for _ in range(total_entries):
        if tail[cursor : cursor + 4] != b"PK\x01\x02":
            raise RuntimeError("invalid central directory record")
        method = struct.unpack_from("<H", tail, cursor + 10)[0]
        crc = struct.unpack_from("<I", tail, cursor + 16)[0]
        compressed_size = struct.unpack_from("<I", tail, cursor + 20)[0]
        uncompressed_size = struct.unpack_from("<I", tail, cursor + 24)[0]
        name_length = struct.unpack_from("<H", tail, cursor + 28)[0]
        extra_length = struct.unpack_from("<H", tail, cursor + 30)[0]
        comment_length = struct.unpack_from("<H", tail, cursor + 32)[0]
        local_offset = struct.unpack_from("<I", tail, cursor + 42)[0]
        name_start = cursor + 46
        name = tail[name_start : name_start + name_length].decode("utf-8")
        entries[name] = {
            "method": method,
            "crc": crc,
            "compressed_size": compressed_size,
            "uncompressed_size": uncompressed_size,
            "local_offset": local_offset,
        }
        cursor += 46 + name_length + extra_length + comment_length
    return entries


def extract_entry(url: str, entry: dict, filename: str) -> bytes:
    offset = entry["local_offset"]
    header = fetch_range(url, offset, offset + 29, f"{filename} 头信息")
    if header[:4] != b"PK\x03\x04":
        raise RuntimeError(f"invalid local header for {filename}")
    name_length = struct.unpack_from("<H", header, 26)[0]
    extra_length = struct.unpack_from("<H", header, 28)[0]
    data_start = offset + 30 + name_length + extra_length
    data_end = data_start + entry["compressed_size"] - 1
    compressed = fetch_range(url, data_start, data_end, filename)
    if entry["method"] == 0:
        data = compressed
    elif entry["method"] == 8:
        data = zlib.decompress(compressed, -zlib.MAX_WBITS)
    else:
        raise RuntimeError(f"unsupported compression method {entry['method']} for {filename}")
    if len(data) != entry["uncompressed_size"]:
        raise RuntimeError(f"size mismatch for {filename}")
    if binascii.crc32(data) & 0xFFFFFFFF != entry["crc"]:
        raise RuntimeError(f"CRC mismatch for {filename}")
    return data


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    target = Path.home() / "Library" / "Application Support" / "Godot" / "export_templates" / VERSION
    target.mkdir(parents=True, exist_ok=True)
    missing = [filename for filename in FILES if args.force or not (target / filename).is_file()]
    if not missing:
        print(f"EXPORT_TEMPLATES_OK path={target} files={len(FILES)}")
        return
    print("正在连接 Godot 官方模板源…", flush=True)
    url, size = query_archive()
    entries = central_directory(url, size)
    for filename in missing:
        archive_name = "templates/" + filename
        if archive_name not in entries:
            raise KeyError(f"missing archive entry: {archive_name}")
        data = extract_entry(url, entries[archive_name], filename)
        (target / filename).write_bytes(data)
        print(f"  已安装 {filename} ({len(data) / 1024 / 1024:.1f} MiB)", flush=True)
    print(f"EXPORT_TEMPLATES_OK path={target} files={len(FILES)}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"EXPORT_TEMPLATES_FAILED {error}", file=sys.stderr)
        raise
