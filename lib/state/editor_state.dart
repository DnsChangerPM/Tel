// Tel — «ویرایشگر متن تلگرام»
//
// وضعیت مرکزی برنامه (بدون هیچ پکیج مدیریت وضعیت بیرونی).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_info.dart';
import '../core/xml_document.dart';
import '../core/xml_validation.dart';
import '../i18n/l10n.dart';
import '../services/file_io_service.dart';
import '../services/settings_store.dart';

/// فیلترهای فهرست رشته‌ها
enum EntryFilter { all, untranslated, edited, empty, technical }

class EditorState extends ChangeNotifier {
  EditorState({FileIoService? fileIo, SettingsStore? settings})
      : files = fileIo ?? FileIoService(),
        _settings = settings ?? SettingsStore();

  final FileIoService files;
  final SettingsStore _settings;

  // --- تنظیمات کاربر ---
  AppLanguage language = AppLanguage.fa;
  ThemeMode themeMode = ThemeMode.dark;

  L10n get l10n => L10n(language);

  // --- سند ---
  XmlDocument document = XmlDocument();
  String? filePath;
  String? fileName;
  String? lastDirectory;
  bool isSampleFile = false;

  // --- بررسی سلامت ---
  ValidationReport? report;
  Map<String, String> englishBaseline = <String, String>{};
  String? englishBaselineName;

  // --- وضعیت ---
  String statusMessage = '';
  bool statusIsError = false;
  bool busy = false;
  EntryFilter filter = EntryFilter.all;
  String entrySearch = '';

  // ---------------------------------------------------------------------------
  // راه‌اندازی
  // ---------------------------------------------------------------------------

  Future<void> bootstrap() async {
    await _settings.load();
    language = AppLanguage.fromCode(_settings.read<String>('language'));
    final String? theme = _settings.read<String>('theme');
    themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    lastDirectory = _settings.read<String>('lastDirectory');
    statusMessage = l10n.statusNoFile;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (language == value) return;
    language = value;
    notifyListeners();
    await _settings.write('language', value.code);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (themeMode == value) return;
    themeMode = value;
    notifyListeners();
    await _settings.write(
      'theme',
      switch (value) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }

  // ---------------------------------------------------------------------------
  // باز کردن و بارگذاری
  // ---------------------------------------------------------------------------

  bool get hasFile => fileName != null || filePath != null;

  bool get isDirty => document.isDirty;

  String get displayName => fileName ?? (filePath ?? l10n.statusNoFile);

  Future<bool> openFile() async {
    if (!files.supportsFileDialogs) {
      _setStatus(l10n.dialogsUnsupported, isError: true);
      return false;
    }
    busy = true;
    notifyListeners();
    try {
      final OpenedTextFile? opened = await files.openFile(initialDirectory: lastDirectory);
      if (opened == null) {
        _setStatus(l10n.statusReady);
        return false;
      }
      loadText(opened.text, name: opened.name, path: opened.path);
      if (opened.path != null) {
        final int cut = opened.path!.lastIndexOf(RegExp(r'[\\/]'));
        if (cut > 0) {
          lastDirectory = opened.path!.substring(0, cut);
          await _settings.write('lastDirectory', lastDirectory);
        }
      }
      _setStatus('${l10n.statusLoaded}: ${opened.name}');
      return true;
    } on FileIoException catch (error) {
      _setStatus('${l10n.errorOpenFile}: ${error.message}', isError: true);
      return false;
    } catch (error) {
      _setStatus('${l10n.errorOpenFile}: $error', isError: true);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> openPath(String path) async {
    if (path.trim().isEmpty) return false;
    busy = true;
    notifyListeners();
    try {
      final OpenedTextFile opened = await files.readFileByPath(path.trim());
      loadText(opened.text, name: opened.name, path: opened.path);
      final int cut = opened.path!.lastIndexOf(RegExp(r'[\\/]'));
      if (cut > 0) {
        lastDirectory = opened.path!.substring(0, cut);
        await _settings.write('lastDirectory', lastDirectory);
      }
      _setStatus('${l10n.statusLoaded}: ${opened.name}');
      return true;
    } catch (error) {
      _setStatus('${l10n.errorOpenFile}: $error', isError: true);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void loadText(String text, {String? name, String? path, bool sample = false}) {
    document.load(FileIoService.stripBom(text));
    fileName = name;
    filePath = path;
    isSampleFile = sample;
    report = null;
    _setStatus(name == null ? l10n.statusReady : '${l10n.statusLoaded}: $name');
    validate();
    notifyListeners();
  }

  Future<void> loadSample() async {
    busy = true;
    notifyListeners();
    try {
      final String text = await rootBundle.loadString('assets/samples/tg_inline_strings_sample.xml');
      loadText(text, name: 'tg_inline_strings_sample.xml', sample: true);
    } catch (error) {
      _setStatus('${l10n.statusError}: $error', isError: true);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void clearAll() {
    document = XmlDocument();
    fileName = null;
    filePath = null;
    report = null;
    isSampleFile = false;
    englishBaseline = <String, String>{};
    englishBaselineName = null;
    _setStatus(l10n.statusNoFile);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ویرایش
  // ---------------------------------------------------------------------------

  void updateSource(String text) {
    document.updateSource(text);
    notifyListeners();
  }

  void setEntryValue(XmlStringEntry entry, String value) {
    document.setValue(entry, value);
    notifyListeners();
  }

  void revertEntry(XmlStringEntry entry) {
    document.revertEntry(entry);
    notifyListeners();
  }

  void revertAllEdits() {
    document.revertAllEdits();
    _setStatus(l10n.revertAll);
    notifyListeners();
  }

  /// ویرایش‌های فهرست را داخل متن XML می‌نویسد (تب «متن فایل» به‌روز می‌شود)
  void applyEditsToText() {
    if (!document.hasPendingEdits) {
      _setStatus(l10n.statusReady);
      notifyListeners();
      return;
    }
    document.commit();
    validate();
    _setStatus(l10n.statusEditsApplied);
    notifyListeners();
  }

  void setFilter(EntryFilter value) {
    filter = value;
    notifyListeners();
  }

  void setEntrySearch(String value) {
    entrySearch = value;
    notifyListeners();
  }

  List<XmlStringEntry> get filteredEntries {
    Iterable<XmlStringEntry> list = document.entries;
    switch (filter) {
      case EntryFilter.all:
        break;
      case EntryFilter.untranslated:
        list = list.where((XmlStringEntry e) => e.looksUntranslated);
        break;
      case EntryFilter.edited:
        list = list.where((XmlStringEntry e) => document.isEntryEdited(e));
        break;
      case EntryFilter.empty:
        list = list.where((XmlStringEntry e) => e.isEmptyValue);
        break;
      case EntryFilter.technical:
        list = list.where((XmlStringEntry e) => e.isProbablyTechnical || !e.translatable);
        break;
    }
    final String needle = entrySearch.trim().toLowerCase();
    if (needle.isNotEmpty) {
      list = list.where((XmlStringEntry e) =>
          e.name.toLowerCase().contains(needle) || document.valueOf(e).toLowerCase().contains(needle));
    }
    return list.toList();
  }

  // ---------------------------------------------------------------------------
  // ذخیره
  // ---------------------------------------------------------------------------

  String suggestedFileName() {
    final String base = fileName ?? 'tg_inline_strings.xml';
    final String version = AppInfo.version;
    if (base.toLowerCase().endsWith('.xml')) {
      return '${base.substring(0, base.length - 4)}_$version.xml';
    }
    return '${base}_$version.xml';
  }

  /// ذخیره؛ اگر [asNew] باشد همیشه مسیر پرسیده می‌شود
  Future<bool> save({bool asNew = false, String? explicitPath}) async {
    final String content = document.render();
    busy = true;
    notifyListeners();
    try {
      SavedTextFile? saved;
      if (explicitPath != null && explicitPath.trim().isNotEmpty) {
        saved = await files.writeFileByPath(explicitPath.trim(), content);
      } else if (!asNew && files.isWindows && filePath != null) {
        saved = await files.writeFileByPath(filePath!, content);
      } else if (files.supportsFileDialogs) {
        saved = await files.saveFileAs(
          suggestedName: suggestedFileName(),
          content: content,
          initialDirectory: lastDirectory,
        );
      } else {
        _setStatus(l10n.dialogsUnsupported, isError: true);
        return false;
      }

      if (saved == null) {
        _setStatus(l10n.statusReady);
        return false;
      }

      document.load(document.render());
      if (saved.path == null) {
        // روی اندروید مسیر فیزیکی در دسترس نیست؛ فقط نام فایل را نگه می‌داریم
        fileName = saved.name;
      }
      if (saved.path != null && files.isWindows) {
        filePath = saved.path;
        fileName = saved.name;
        final int cut = saved.path!.lastIndexOf(RegExp(r'[\\/]'));
        if (cut > 0) {
          lastDirectory = saved.path!.substring(0, cut);
          await _settings.write('lastDirectory', lastDirectory);
        }
      }
      isSampleFile = false;
      validate();
      _setStatus('${l10n.statusSavedTo}: ${saved.describe}');
      return true;
    } on FileIoException catch (error) {
      _setStatus('${l10n.errorSaveFile}: ${error.message}', isError: true);
      return false;
    } catch (error) {
      _setStatus('${l10n.errorSaveFile}: $error', isError: true);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // کلیپ‌بورد
  // ---------------------------------------------------------------------------

  Future<void> copyToClipboard(String text, {String? message}) async {
    await Clipboard.setData(ClipboardData(text: text));
    _setStatus(message ?? l10n.statusCopied);
    notifyListeners();
  }

  Future<String?> pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? text = data?.text;
    if (text == null) return null;
    loadText(text, name: 'clipboard.xml');
    _setStatus(l10n.statusLoaded);
    notifyListeners();
    return text;
  }

  // ---------------------------------------------------------------------------
  // بررسی سلامت
  // ---------------------------------------------------------------------------

  ValidationReport validate() {
    final ValidationReport next = const XmlValidator().validate(
      document.render(),
      document.entries,
      baseline: englishBaseline,
    );
    report = next;
    return next;
  }

  Future<void> loadEnglishReference() async {
    try {
      String? text;
      String name = 'English reference';
      if (files.supportsFileDialogs) {
        final OpenedTextFile? opened = await files.openFile(initialDirectory: lastDirectory);
        if (opened == null) return;
        text = opened.text;
        name = opened.name;
      }
      if (text == null) return;
      englishBaseline = valuesByName(text);
      englishBaselineName = name;
      validate();
      _setStatus('${l10n.englishReferenceLoaded}: $name');
      notifyListeners();
    } catch (error) {
      _setStatus('${l10n.errorOpenFile}: $error', isError: true);
      notifyListeners();
    }
  }

  /// فقط برای تست‌ها: بارگذاری مرجع انگلیسی از متن
  void setEnglishReferenceFromText(String text, {String name = 'reference.xml'}) {
    englishBaseline = valuesByName(text);
    englishBaselineName = name;
    validate();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------

  /// نمایش یک پیام در نوار وضعیت (برای استفاده از رابط کاربری)
  void showStatus(String message, {bool isError = false}) {
    _setStatus(message, isError: isError);
    notifyListeners();
  }

  void _setStatus(String message, {bool isError = false}) {
    statusMessage = message;
    statusIsError = isError;
  }

}

/// دسترسی سراسری به وضعیت بدون پکیج بیرونی
class AppScope extends InheritedNotifier<EditorState> {
  const AppScope({super.key, required EditorState state, required super.child}) : super(notifier: state);

  static EditorState of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope در درخت ویجت‌ها پیدا نشد.');
    return scope!.notifier!;
  }
}
