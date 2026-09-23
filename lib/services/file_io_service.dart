// Tel — «ویرایشگر متن تلگرام»
//
// خواندن و نوشتن فایل روی اندروید و ویندوز.
//
// اندروید: از طریق کانال پلتفرم «tel/file_io» که خودمان در MainActivity.kt
// نوشته‌ایم (بدون هیچ پلاگین بیرونی) و از Storage Access Framework استفاده
// می‌کند؛ بنابراین به هیچ مجوز خاصی نیاز نیست و روی اندروید ۷ تا آخرین نسخه
// کار می‌کند.
//
// ویندوز: دیالوگ‌های بومی ویندوز از طریق PowerShell (System.Windows.Forms)
// باز می‌شوند و خواندن/نوشتن محتوا با dart:io انجام می‌شود؛ پس متن فارسی هیچ
// وقت از خط فرمان عبور نمی‌کند.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// نتیجهٔ باز کردن یک فایل
class OpenedTextFile {
  const OpenedTextFile({
    required this.name,
    required this.text,
    this.path,
    this.location,
  });

  /// نام فایل، مثل tg_inline_strings.xml
  final String name;

  /// محتوای متنی
  final String text;

  /// مسیر فیزیکی (روی ویندوز) — روی اندروید معمولاً null است
  final String? path;

  /// توضیح مکانی که فایل از آن خوانده شده (برای نمایش به کاربر)
  final String? location;

  bool get hasPath => path != null && path!.isNotEmpty;
}

/// نتیجهٔ ذخیره
class SavedTextFile {
  const SavedTextFile({required this.name, this.path, this.location});

  final String name;
  final String? path;
  final String? location;

  String get describe => location ?? path ?? name;
}

class FileIoService {
  FileIoService({MethodChannel? channel}) : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'tel/file_io';

  final MethodChannel _channel;

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  bool get isWindows => !kIsWeb && Platform.isWindows;

  /// آیا امکان باز کردن دیالوگ فایل وجود دارد؟
  bool get supportsFileDialogs => isAndroid || isWindows;

  // ---------------------------------------------------------------------------
  // باز کردن فایل
  // ---------------------------------------------------------------------------

  Future<OpenedTextFile?> openFile({String? initialDirectory}) async {
    if (isAndroid) return _openFileAndroid();
    if (isWindows) return _openFileWindows(initialDirectory: initialDirectory);
    return null;
  }

  Future<OpenedTextFile?> _openFileAndroid() async {
    try {
      final Map<Object?, Object?>? result =
          await _channel.invokeMethod<Map<Object?, Object?>>('pickStringsFile');
      if (result == null) return null;
      final String? text = result['text'] as String?;
      if (text == null) return null;
      return OpenedTextFile(
        name: (result['name'] as String?) ?? 'strings.xml',
        text: stripBom(text),
        path: result['path'] as String?,
        location: (result['displayPath'] as String?) ?? (result['name'] as String?),
      );
    } on PlatformException catch (error) {
      throw FileIoException(error.message ?? 'خطای ناشناخته در باز کردن فایل');
    } on MissingPluginException {
      throw const FileIoException('امکان انتخاب فایل در این دستگاه فعال نیست.');
    }
  }

  Future<OpenedTextFile?> _openFileWindows({String? initialDirectory}) async {
    final String? path = await _runPowerShellDialog(_openFileScript, initialDirectory: initialDirectory);
    if (path == null) return null;
    return readFileByPath(path);
  }

  /// خواندن مستقیم یک فایل از مسیر مشخص
  Future<OpenedTextFile> readFileByPath(String path) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw FileIoException('فایل پیدا نشد: $path');
    }
    final List<int> bytes = await file.readAsBytes();
    final String text = stripBom(decodeText(bytes));
    return OpenedTextFile(
      name: file.uri.pathSegments.isEmpty ? path : file.uri.pathSegments.last,
      text: text,
      path: file.path,
      location: file.path,
    );
  }

  // ---------------------------------------------------------------------------
  // ذخیره
  // ---------------------------------------------------------------------------

  /// ذخیره با پرسیدن مسیر (Save As)
  Future<SavedTextFile?> saveFileAs({
    required String suggestedName,
    required String content,
    String? initialDirectory,
  }) async {
    if (isAndroid) return _saveFileAndroid(suggestedName: suggestedName, content: content);
    if (isWindows) {
      final String? path =
          await _runPowerShellDialog(_saveFileScript, initialDirectory: initialDirectory, fileName: suggestedName);
      if (path == null) return null;
      return writeFileByPath(path, content);
    }
    return null;
  }

  Future<SavedTextFile?> _saveFileAndroid({
    required String suggestedName,
    required String content,
  }) async {
    try {
      final Map<Object?, Object?>? result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'saveStringsFile',
        <String, Object?>{'name': suggestedName, 'text': content},
      );
      if (result == null) return null;
      return SavedTextFile(
        name: (result['name'] as String?) ?? suggestedName,
        location: (result['displayPath'] as String?) ?? (result['name'] as String?) ?? suggestedName,
      );
    } on PlatformException catch (error) {
      throw FileIoException(error.message ?? 'خطای ناشناخته در ذخیرهٔ فایل');
    } on MissingPluginException {
      throw const FileIoException('امکان ذخیرهٔ فایل در این دستگاه فعال نیست؛ از «کپی» استفاده کنید.');
    }
  }

  /// نوشتن روی مسیر مشخص (بدون دیالوگ)
  Future<SavedTextFile> writeFileByPath(String path, String content) async {
    final File file = File(path);
    final Directory? parent = file.parent;
    if (parent != null && !await parent.exists()) {
      await parent.create(recursive: true);
    }
    await file.writeAsBytes(utf8.encode(ensureTrailingNewline(content)), flush: true);
    return SavedTextFile(name: file.uri.pathSegments.last, path: file.path, location: file.path);
  }

  // ---------------------------------------------------------------------------
  // ابزارهای کمکی
  // ---------------------------------------------------------------------------

  /// حذف BOM از ابتدای متن (فایل‌های تلگرام UTF-8 هستند)
  static String stripBom(String text) {
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      return text.substring(1);
    }
    return text;
  }

  /// تبدیل بایت‌ها به متن با تشخیص UTF-8 / UTF-16
  static String decodeText(List<int> bytes) {
    if (bytes.length >= 2) {
      final bool utf16Le = bytes[0] == 0xFF && bytes[1] == 0xFE;
      final bool utf16Be = bytes[0] == 0xFE && bytes[1] == 0xFF;
      if (utf16Le || utf16Be) {
        final List<int> body = bytes.sublist(2);
        return String.fromCharCodes(
          utf16Le
              ? List<int>.generate(body.length ~/ 2, (int i) => body[i * 2] | (body[i * 2 + 1] << 8))
              : List<int>.generate(body.length ~/ 2, (int i) => (body[i * 2] << 8) | body[i * 2 + 1]),
        );
      }
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  /// اطمینان از تمام‌شدن فایل با خط جدید
  static String ensureTrailingNewline(String text) => text.endsWith('\n') ? text : '$text\n';

  // ---------------------------------------------------------------------------
  // پیاده‌سازی ویندوز با PowerShell
  // ---------------------------------------------------------------------------

  /// دایرکتوری پیش‌فرض کاربر روی ویندوز (پوشهٔ دانلودها) برای شروع دیالوگ
  static String? windowsDefaultDirectory() {
    final Map<String, String> env = Platform.environment;
    final String? userProfile = env['USERPROFILE'];
    if (userProfile == null || userProfile.isEmpty) return null;
    return '$userProfile\\Downloads';
  }

  Future<String?> _runPowerShellDialog(
    String script, {
    String? initialDirectory,
    String? fileName,
  }) async {
    final StringBuffer header = StringBuffer()
      ..writeln(r"$ErrorActionPreference = 'Stop'")
      ..writeln(r'[Console]::OutputEncoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false')
      ..writeln(r'Add-Type -AssemblyName System.Windows.Forms | Out-Null')
      ..writeln(r'Add-Type -AssemblyName System.Drawing | Out-Null');

    final String dir = initialDirectory ?? windowsDefaultDirectory() ?? '';
    if (dir.isNotEmpty) {
      final String escaped = dir.replaceAll("'", "''");
      header.writeln("\$initialDirectory = '$escaped'");
    } else {
      header.writeln(r'$initialDirectory = ""');
    }
    if (fileName != null && fileName.isNotEmpty) {
      final String escaped = fileName.replaceAll("'", "''");
      header.writeln("\$suggestedName = '$escaped'");
    } else {
      header.writeln(r'$suggestedName = "strings.xml"');
    }

    try {
      final ProcessResult result = await Process.run(
        'powershell.exe',
        <String>[
          '-NoProfile',
          '-WindowStyle',
          'Hidden',
          '-Command',
          '${header.toString()}${_ownerForm}$script',
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
        runInShell: false,
      );

      if (result.exitCode != 0) {
        debugPrint('Tel: PowerShell exit=${result.exitCode} err=${result.stderr}');
        return null;
      }
      final String output = (result.stdout as String).trim();
      if (output.isEmpty) return null; // کاربر لغو کرد
      final String path = output.split(RegExp(r'[\r\n]+')).last.trim();
      return path.isEmpty ? null : path;
    } on ProcessException catch (error) {
      debugPrint('Tel: PowerShell اجرا نشد: $error');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // اسکریپت‌های PowerShell
  // ---------------------------------------------------------------------------

  static const String _ownerForm = r'''
$owner = New-Object System.Windows.Forms.Form
$owner.TopMost = $true
$owner.ShowInTaskbar = $false
$owner.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$owner.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$owner.Size = New-Object -TypeName System.Drawing.Size -ArgumentList 1, 1
$owner.Show()
try {
''';

  static const String _openFileScript = r'''
  $dialog = New-Object System.Windows.Forms.OpenFileDialog
  $dialog.Title = "Tel - باز کردن فایل متن تلگرام"
  $dialog.Filter = "XML strings (*.xml)|*.xml|JSON (*.json)|*.json|همه فایل ها (*.*)|*.*"
  $dialog.Multiselect = $false
  if ($initialDirectory -ne "" -and (Test-Path -LiteralPath $initialDirectory)) {
    $dialog.InitialDirectory = $initialDirectory
  }
  $result = $dialog.ShowDialog($owner)
  if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::Out.Write($dialog.FileName)
  }
} finally {
  $owner.Close()
}
''';

  static const String _saveFileScript = r'''
  $dialog = New-Object System.Windows.Forms.SaveFileDialog
  $dialog.Title = "Tel - ذخیره فایل متن تلگرام"
  $dialog.Filter = "XML strings (*.xml)|*.xml|همه فایل ها (*.*)|*.*"
  $dialog.OverwritePrompt = $true
  $dialog.AddExtension = $true
  $dialog.DefaultExt = "xml"
  $dialog.FileName = $suggestedName
  if ($initialDirectory -ne "" -and (Test-Path -LiteralPath $initialDirectory)) {
    $dialog.InitialDirectory = $initialDirectory
  }
  $result = $dialog.ShowDialog($owner)
  if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::Out.Write($dialog.FileName)
  }
} finally {
  $owner.Close()
}
''';

  /// اسکریپت دیالوگ «باز کردن فایل» (برای تست و بازبینی)
  static String get openFileScriptDebug => '$_ownerForm$_openFileScript';

  /// اسکریپت دیالوگ «ذخیرهٔ فایل» (برای تست و بازبینی)
  static String get saveFileScriptDebug => '$_ownerForm$_saveFileScript';
}

/// خطای مربوط به فایل
class FileIoException implements Exception {
  const FileIoException(this.message);

  final String message;

  @override
  String toString() => message;
}
