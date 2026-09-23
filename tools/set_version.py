#!/usr/bin/env python3
"""Write the application version into pubspec.yaml.

The GitHub Actions workflow runs this script so the version the user typed in
is used by the APK, the EXE and every release file name.

Usage:
    python3 tools/set_version.py 1.2.0+7

All strings printed by this script are plain ASCII on purpose: the Windows
console used by the release workflow is not UTF-8 and printing Persian text
there would raise UnicodeEncodeError.

نکته: فقط پیام‌های چاپ‌شده ASCII هستند؛ کامنت‌های زیر فارسی‌اند و مشکلی ایجاد
نمی‌کنند چون پایتون فایل منبع را همیشه UTF-8 می‌خواند.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# 1.2.0 ، 1.2.0+7 ، v1.2.0
VERSION_RE = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$")


def normalize(value: str) -> str:
    """نسخه را به قالب pubspec (X.Y.Z+N) تبدیل می‌کند"""
    match = VERSION_RE.fullmatch(value.strip())
    if not match:
        raise SystemExit(
            f"Invalid version: {value!r} - expected something like 1.2.0 or 1.2.0+7"
        )
    name = ".".join(match.group(1, 2, 3))
    build = match.group(4) or "1"
    return f"{name}+{build}"


def update_pubspec(path: Path, version: str) -> None:
    """خط version در pubspec.yaml را بازنویسی می‌کند (بقیهٔ فایل دست‌نخورده)"""
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(r"^version:\s*\S+\s*$", re.MULTILINE)
    if not pattern.search(text):
        raise SystemExit(f"No version line found in {path}")
    path.write_text(pattern.sub(f"version: {version}", text, count=1), encoding="utf-8")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Usage: python3 tools/set_version.py <version>   (example: 1.2.0+7)")
        return 2

    version = normalize(argv[1])
    pubspec = Path("pubspec.yaml")
    if not pubspec.exists():
        raise SystemExit("pubspec.yaml not found; run this script from the project root")

    update_pubspec(pubspec, version)
    print(f"pubspec.yaml version set to {version}")
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        if line.startswith("version:"):
            print(f"  {line}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
