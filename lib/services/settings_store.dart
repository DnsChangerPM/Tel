// Tel — «ویرایشگر متن تلگرام»
//
// ذخیرهٔ تنظیمات کوچک برنامه (زبان، تم، آخرین مسیر فایل).
// روی ویندوز در پوشهٔ %APPDATA%\Tel\settings.json و روی لینوکس/مک در پوشهٔ
// خانهٔ کاربر ذخیره می‌شود. روی اندروید (به دلیل نداشتن پلاگین مسیر) فقط در
// حافظه نگه داشته می‌شود و برنامه بدون آن هم کامل کار می‌کند.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class SettingsStore {
  SettingsStore();

  Map<String, Object?> _cache = <String, Object?>{};

  File? _file;

  bool get isPersistent => _file != null;

  Future<void> load() async {
    _file = _resolveFile();
    if (_file == null) return;
    try {
      if (await _file!.exists()) {
        final String raw = await _file!.readAsString();
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map<String, Object?>) _cache = decoded;
        if (decoded is Map) _cache = decoded.cast<String, Object?>();
      }
    } catch (error) {
      debugPrint('Tel: خواندن تنظیمات ناموفق بود: $error');
    }
  }

  T? read<T>(String key) {
    final Object? value = _cache[key];
    return value is T ? value : null;
  }

  Future<void> write(String key, Object? value) async {
    if (value == null) {
      _cache.remove(key);
    } else {
      _cache[key] = value;
    }
    await _flush();
  }

  Future<void> _flush() async {
    final File? file = _file;
    if (file == null) return;
    try {
      final Directory parent = file.parent;
      if (!await parent.exists()) await parent.create(recursive: true);
      await file.writeAsString(jsonEncode(_cache), flush: true);
    } catch (error) {
      debugPrint('Tel: ذخیرهٔ تنظیمات ناموفق بود: $error');
    }
  }

  static File? _resolveFile() {
    if (kIsWeb) return null;
    try {
      if (Platform.isWindows) {
        final String? appData = Platform.environment['APPDATA'];
        final String base = (appData != null && appData.isNotEmpty)
            ? appData
            : (Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path);
        return File('$base\\Tel\\settings.json');
      }
      if (Platform.isLinux || Platform.isMacOS) {
        final String? home = Platform.environment['HOME'];
        if (home == null || home.isEmpty) return null;
        return File('$home/.config/tel/settings.json');
      }
    } catch (error) {
      debugPrint('Tel: مسیر تنظیمات پیدا نشد: $error');
    }
    // اندروید و بقیهٔ پلتفرم‌ها: فقط حافظه
    return null;
  }
}
