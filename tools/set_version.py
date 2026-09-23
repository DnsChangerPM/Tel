#!/usr/bin/env python3
"""نوشتن نسخه در فایل pubspec.yaml

ورک‌فلوی گیت‌هاب نسخه‌ای را که کاربر وارد کرده با این اسکریپت داخل pubspec.yaml
می‌نویسد تا نسخهٔ APK، نسخهٔ EXE و نام فایل‌های انتشار همه یکسان باشند.

نمونه:
    python3 tools/set_version.py 1.2.0+7
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

VERSION_RE = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$")


def normalize(value: str) -> str:
    match = VERSION_RE.fullmatch(value.strip())
    if not match:
        raise SystemExit(
            f"نسخهٔ نامعتبر: {value!r} — قالب درست مثل 1.2.0 یا 1.2.0+7 است"
        )
    name = ".".join(match.group(1, 2, 3))
    build = match.group(4) or "1"
    return f"{name}+{build}"


def update_pubspec(path: Path, version: str) -> str:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(r"^version:\s*\S+\s*$", re.MULTILINE)
    if not pattern.search(text):
        raise SystemExit(f"خط version در {path} پیدا نشد")
    updated = pattern.sub(f"version: {version}", text, count=1)
    path.write_text(updated, encoding="utf-8")
    return updated


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__)
        return 2

    version = normalize(argv[1])
    pubspec = Path("pubspec.yaml")
    if not pubspec.exists():
        raise SystemExit("pubspec.yaml پیدا نشد؛ اسکریپت را از ریشهٔ پروژه اجرا کنید")

    update_pubspec(pubspec, version)
    print(f"نسخه در pubspec.yaml به {version} تغییر کرد")

    # نمایش تأییدی برای لاگ ورک‌فلو
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        if line.startswith("version:"):
            print(f"  {line}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
