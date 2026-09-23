#!/usr/bin/env python3
"""بررسی ایستای پروژهٔ Tel (بدون نیاز به Flutter/Dart)

چون در این محیط Flutter و Dart نصب نیست، این اسکریپت ساختار کد را از نظر خطاهای
واضح (پرانتز/آکولاد نامتوازن، import ناموجود، تکرار ناخواستهٔ خطوط، استفاده از
API های ناسازگار با Flutter 3.19 و ...) بررسی می‌کند.

نمونهٔ اجرا:
    python3 tools/verify_sources.py
"""

from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# API هایی که در Flutter 3.19 (ساخت EXE ویندوز) وجود ندارند
FORBIDDEN_IN_DART = {
    "withValues(": "Color.withValues فقط در Flutter 3.27+ وجود دارد (از cardColor یا رنگ ثابت استفاده کنید)",
    "surfaceContainerHighest": "ColorScheme.surfaceContainerHighest فقط در Flutter 3.22+ وجود دارد",
    "withOpacity(": "Color.withOpacity در نسخه‌های جدید منسوخ شده است",
    "surfaceVariant": "ColorScheme.surfaceVariant منسوخ شده است؛ از surface/onSurfaceVariant استفاده کنید",
}

errors: list[str] = []
warnings: list[str] = []


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


def check_balanced(path: Path, text: str) -> None:
    """بررسی توازن آکولاد/پرانتز/براکت با نادیده‌گرفتن رشته‌ها و کامنت‌ها"""
    pairs = {"{": "}", "(": ")", "[": "]"}
    closing = {v: k for k, v in pairs.items()}
    stack: list[tuple[str, int]] = []
    i, line, n = 0, 1, len(text)
    while i < n:
        ch = text[i]
        two = text[i : i + 2]
        three = text[i : i + 3]
        if ch == "\n":
            line += 1
            i += 1
            continue
        if two == "//":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if two == "/*":
            i += 2
            while i < n and text[i : i + 2] != "*/":
                if text[i] == "\n":
                    line += 1
                i += 1
            i += 2
            continue
        if three in ("'''", '"""'):
            quote = three
            i += 3
            while i < n and text[i : i + 3] != quote:
                if text[i] == "\n":
                    line += 1
                i += 1
            i += 3
            continue
        if ch in ("'", '"'):
            quote = ch
            i += 1
            while i < n:
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == quote:
                    i += 1
                    break
                if text[i] == "\n" and quote == "'":
                    break  # رشتهٔ تک‌خطی تمام‌نشده
                i += 1
            continue
        if ch in pairs:
            stack.append((ch, line))
        elif ch in closing:
            if not stack or stack[-1][0] != closing[ch]:
                errors.append(f"{rel(path)}:{line} بستن نادرست «{ch}»")
                return
            stack.pop()
        i += 1
    for open_ch, open_line in stack:
        errors.append(f"{rel(path)}:{open_line} «{open_ch}» بسته نشده است")


def check_repetition(path: Path, text: str) -> None:
    """تشخیص تکرار ناخواسته (نشانهٔ خرابی تولید کد)"""
    lines = [
        line.strip()
        for line in text.splitlines()
        if len(line.strip()) > 25 and not line.strip().startswith("//")
    ]
    if not lines:
        return
    counts: dict[str, int] = {}
    for line in lines:
        counts[line] = counts.get(line, 0) + 1
    worst_line, worst_count = max(counts.items(), key=lambda item: item[1])
    if worst_count > 8:
        errors.append(
            f"{rel(path)} خط تکراری {worst_count} بار تکرار شده است: {worst_line[:70]!r}"
        )
    signatures = re.findall(r"^String _[A-Za-z0-9_]+\(String path\)", text, re.MULTILINE)
    if len(signatures) > 20:
        errors.append(f"{rel(path)} شمار زیادی تابع کمکی تکراری دارد ({len(signatures)})")


def dart_files() -> list[Path]:
    return sorted(
        path
        for path in list((ROOT / "lib").rglob("*.dart")) + list((ROOT / "test").rglob("*.dart"))
        if path.is_file()
    )


def check_dart(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    check_balanced(path, text)
    check_repetition(path, text)

    for needle, message in FORBIDDEN_IN_DART.items():
        if needle in text:
            errors.append(f"{rel(path)} استفاده از «{needle}»: {message}")

    # import ها
    for match in re.finditer(r"""import\s+['"]([^'"]+)['"]""", text):
        target = match.group(1)
        if target.startswith("package:tel/"):
            resolved = ROOT / "lib" / target[len("package:tel/") :]
            if not resolved.exists():
                errors.append(f"{rel(path)} import ناموجود: {target}")
        elif target.startswith("dart:") or target.startswith("package:") or ":" in target:
            continue
        else:
            resolved = (path.parent / target).resolve()
            if not resolved.exists():
                errors.append(f"{rel(path)} import ناموجود: {target}")

    if "TODO" in text or "FIXME" in text:
        warnings.append(f"{rel(path)} یادداشت TODO/FIXME دارد")


def check_translations() -> None:
    """همهٔ کلیدهای استفاده‌شده در UI باید در l10n.dart وجود داشته باشند"""
    l10n = (ROOT / "lib/i18n/l10n.dart").read_text(encoding="utf-8")

    getters = set(re.findall(r"^\s{2}[\w<>\s]+\sget (\w+) =>", l10n, re.MULTILINE))
    # getter های کمکی که کلید ترجمه نیستند
    helper_getters = {"isRtl", "direction"}
    getters -= helper_getters
    table_keys: dict[str, set[str]] = {}
    for lang in ("fa", "en"):
        block = re.search(rf"'{lang}': <String, String>\{{(.*?)\n    \}},", l10n, re.DOTALL)
        if not block:
            errors.append(f"lib/i18n/l10n.dart جدول زبان {lang} پیدا نشد")
            continue
        table_keys[lang] = set(re.findall(r"^\s*'(\w+)':", block.group(1), re.MULTILINE))

    for lang, keys in table_keys.items():
        missing = getters - keys
        if missing:
            errors.append(f"l10n.dart کلیدهای بدون ترجمه در {lang}: {sorted(missing)}")
        extra = keys - getters
        if extra:
            errors.append(f"l10n.dart کلیدهای بدون getter: {sorted(extra)}")

    used: set[str] = set()
    for path in (ROOT / "lib").rglob("*.dart"):
        if path.name == "l10n.dart":
            continue
        text = path.read_text(encoding="utf-8")
        used.update(re.findall(r"\bl10n\.(?!dart\b)([a-zA-Z]\w*)", text))
    unknown = {name for name in used if name not in getters and name not in helper_getters}
    if unknown:
        errors.append(f"کلیدهای ترجمهٔ ناموجود در UI: {sorted(unknown)}")


def check_python_and_yaml() -> None:
    import ast

    for path in sorted((ROOT / "tools").rglob("*.py")):
        try:
            ast.parse(path.read_text(encoding="utf-8"))
        except SyntaxError as exc:
            errors.append(f"{rel(path)} خطای نگارشی پایتون: {exc}")

    try:
        import yaml  # type: ignore
    except ImportError:
        warnings.append("PyYAML نصب نیست؛ بررسی فایل‌های YAML انجام نشد")
        return

    for path in sorted((ROOT / ".github").rglob("*.yaml")) + sorted((ROOT / ".github").rglob("*.yml")):
        try:
            data = yaml.safe_load(path.read_text(encoding="utf-8"))
        except yaml.YAMLError as exc:
            errors.append(f"{rel(path)} خطای YAML: {exc}")
            continue
        if not isinstance(data, dict):
            errors.append(f"{rel(path)} ساختار YAML نامعتبر است")
        elif "jobs" not in data:
            errors.append(f"{rel(path)} بخش jobs ندارد")


def check_xml() -> None:
    for path in sorted(ROOT.rglob("*.xml")):
        if any(part in {".git", "build", "windows/flutter/ephemeral"} for part in path.parts):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        try:
            ET.fromstring(text)
        except ET.ParseError as exc:
            # مانیفست‌های اندروید ممکن است چند ریشه داشته باشند (این طبیعی است)
            try:
                ET.fromstring(f"<wrapper>{text}</wrapper>")
            except ET.ParseError:
                errors.append(f"{rel(path)} XML نامعتبر: {exc}")


def check_json() -> None:
    for path in sorted(ROOT.rglob("*.json")):
        if ".git" in path.parts or "node_modules" in path.parts:
            continue
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError) as exc:
            warnings.append(f"{rel(path)} JSON نامعتبر: {exc}")


def check_required_files() -> None:
    required = [
        "pubspec.yaml",
        "analysis_options.yaml",
        "README.md",
        ".gitignore",
        "LICENSE",
        "lib/main.dart",
        "lib/core/xml_document.dart",
        "lib/core/xml_validation.dart",
        "lib/core/app_info.dart",
        "lib/services/file_io_service.dart",
        "lib/services/settings_store.dart",
        "lib/i18n/l10n.dart",
        "lib/state/editor_state.dart",
        "lib/ui/home_screen.dart",
        "lib/ui/editor_panel.dart",
        "lib/ui/entries_panel.dart",
        "lib/ui/issues_panel.dart",
        "lib/ui/help_panel.dart",
        "lib/ui/theme.dart",
        "lib/ui/widgets.dart",
        "test/xml_document_test.dart",
        "test/xml_validation_test.dart",
        "test/file_io_service_test.dart",
        "test/l10n_test.dart",
        "test/project_structure_test.dart",
        "assets/samples/tg_inline_strings_sample.xml",
        "assets/samples/tg_inline_strings_en_sample.xml",
        "assets/fonts/Vazirmatn-Regular.ttf",
        "android/settings.gradle.kts",
        "android/build.gradle.kts",
        "android/gradle.properties",
        "android/gradlew",
        "android/gradle/wrapper/gradle-wrapper.jar",
        "android/gradle/wrapper/gradle-wrapper.properties",
        "android/app/build.gradle.kts",
        "android/app/src/main/AndroidManifest.xml",
        "android/app/src/main/kotlin/com/dnschanger/tel/MainActivity.kt",
        "android/app/src/main/res/values/styles.xml",
        "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml",
        "windows/CMakeLists.txt",
        "windows/runner/main.cpp",
        "windows/runner/Runner.rc",
        "windows/runner/runner.exe.manifest",
        "windows/runner/resources/app_icon.ico",
        "windows/flutter/generated_plugins.cmake",
        "windows/flutter/generated_plugin_registrant.cc",
        ".github/workflows/release.yml",
        "tools/set_version.py",
        "tools/installer.iss",
    ]
    for name in required:
        if not (ROOT / name).exists():
            errors.append(f"فایل لازم پیدا نشد: {name}")


def check_no_mustache() -> None:
    for pattern in ("windows/**/*", "android/**/*"):
        for path in ROOT.glob(pattern):
            if not path.is_file() or path.suffix.lower() not in {
                ".txt",
                ".cmake",
                ".cpp",
                ".h",
                ".rc",
                ".kts",
                ".gradle",
                ".properties",
                ".kt",
                ".xml",
                ".manifest",
                ".gitignore",
            }:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            if "{{" in text and "{{NO_DEPENDENCIES}}" not in text:
                errors.append(f"{rel(path)} جای‌نگهدار قالب (mustache) باقی مانده است")


def check_workflow_contract() -> None:
    yml = (ROOT / ".github/workflows/release.yml").read_text(encoding="utf-8")
    for needle in (
        "workflow_dispatch",
        "flutter build apk --release",
        "flutter build windows --release",
        "softprops/action-gh-release",
        "FLUTTER_VERSION_WINDOWS: '3.19.6'",
        "TEL_APP_VERSION",
        "--build-name",
        "--build-number",
    ):
        if needle not in yml:
            errors.append(f"ورک‌فلو مورد «{needle}» را ندارد")


def main() -> int:
    dart = dart_files()
    for path in dart:
        check_dart(path)
    check_translations()
    check_python_and_yaml()
    check_xml()
    check_json()
    check_required_files()
    check_no_mustache()
    check_workflow_contract()

    print(f"بررسی {len(dart)} فایل Dart ... تمام شد")
    if warnings:
        print("\nهشدارها:")
        for item in warnings:
            print(f"  - {item}")
    if errors:
        print("\nخطاها:")
        for item in errors:
            print(f"  ✗ {item}")
        print(f"\nنتیجه: {len(errors)} خطا")
        return 1
    print("\nنتیجه: بدون خطا ✓")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
