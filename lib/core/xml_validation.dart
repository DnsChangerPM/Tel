// Tel — «ویرایشگر متن تلگرام»
//
// بررسی سلامت فایل ترجمه: ساختار XML، نام‌های تکراری، مقادیر خالی،
// رشته‌های ترجمه‌نشده و ناسازگاری قالب‌های جای‌گذاری (%s و ...)

import 'xml_document.dart';

enum IssueSeverity { error, warning, info }

class ValidationIssue {
  const ValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.line,
    this.name,
  });

  final IssueSeverity severity;

  /// کد ثابت برای تست‌ها، مثل `duplicate-name`
  final String code;

  final String message;
  final int? line;
  final String? name;

  @override
  String toString() => '${severity.name}: $code ${line == null ? '' : '(خط $line) '}$message';
}

class ValidationReport {
  ValidationReport(this.issues);

  final List<ValidationIssue> issues;

  bool get hasErrors => issues.any((ValidationIssue i) => i.severity == IssueSeverity.error);

  bool get hasWarnings => issues.any((ValidationIssue i) => i.severity == IssueSeverity.warning);

  int count(IssueSeverity severity) => issues.where((ValidationIssue i) => i.severity == severity).length;

  int get errorCount => count(IssueSeverity.error);

  int get warningCount => count(IssueSeverity.warning);

  int get infoCount => count(IssueSeverity.info);

  List<ValidationIssue> bySeverity(IssueSeverity severity) =>
      issues.where((ValidationIssue i) => i.severity == severity).toList();
}

class XmlValidator {
  const XmlValidator();

  static final RegExp _validEntity = RegExp(
    r'&(amp|lt|gt|quot|apos|nbsp|rlm|lrm|#\d+|#x[0-9A-Fa-f]+);',
  );

  /// [baseline] اختیاری: مقادیر فایل انگلیسی (کلید ← مقدار) برای مقایسهٔ قالب‌ها
  ValidationReport validate(
    String source,
    List<XmlStringEntry> entries, {
    Map<String, String> baseline = const <String, String>{},
  }) {
    final List<ValidationIssue> issues = <ValidationIssue>[];

    if (source.trim().isEmpty) {
      issues.add(const ValidationIssue(
        severity: IssueSeverity.error,
        code: 'empty-file',
        message: 'فایل خالی است؛ ابتدا یک فایل strings.xml تلگرام را باز کنید.',
      ));
      return ValidationReport(issues);
    }

    if (!source.contains('<resources')) {
      issues.add(const ValidationIssue(
        severity: IssueSeverity.warning,
        code: 'missing-resources-root',
        message: 'تگ ریشهٔ <resources> پیدا نشد؛ مطمئن شوید فایل strings.xml درست است.',
      ));
    }

    if (entries.isEmpty) {
      issues.add(const ValidationIssue(
        severity: IssueSeverity.error,
        code: 'no-strings',
        message: 'هیچ تگ <string> در فایل پیدا نشد.',
      ));
    }

    // ۱) تعادل تگ‌های string
    final int openTags = RegExp(r'<string\b').allMatches(source).length;
    final int closeTags = RegExp(r'</string\s*>').allMatches(source).length;
    final int selfClosing = RegExp(r'<string\b[^<>]*?/>').allMatches(source).length;
    if (openTags != closeTags + selfClosing) {
      issues.add(ValidationIssue(
        severity: IssueSeverity.error,
        code: 'unbalanced-tags',
        message: 'تعداد تگ‌های <string> ($openTags) با تگ‌های بسته ($closeTags + $selfClosing خودبسته) برابر نیست.',
      ));
    }

    // ۲) کاراکتر & که موجودیت معتبری را شروع نمی‌کند
    int line = 1;
    bool reportedEntity = false;
    for (int i = 0; i < source.length && !reportedEntity; i++) {
      if (source.codeUnitAt(i) == 0x0A) line++;
      if (source[i] != '&') continue;
      final String slice = source.substring(i);
      if (_validEntity.matchAsPrefix(slice) == null) {
        issues.add(ValidationIssue(
          severity: IssueSeverity.error,
          code: 'invalid-entity',
          message: 'کاراکتر & بدون escape معتبر در متن هست (باید &amp; باشد).',
          line: line,
        ));
        reportedEntity = true;
      }
    }

    // ۳) نام‌های تکراری
    for (final XmlStringEntry e in entries.where((XmlStringEntry e) => e.isDuplicate)) {
      issues.add(ValidationIssue(
        severity: IssueSeverity.warning,
        code: 'duplicate-name',
        message: 'نام «${e.name}» تکراری است.',
        line: e.line,
        name: e.name,
      ));
    }

    // ۴) مقادیر خالی
    final List<XmlStringEntry> empties =
        entries.where((XmlStringEntry e) => e.isEmptyValue && e.translatable).toList();
    for (final XmlStringEntry e in empties.take(50)) {
      issues.add(ValidationIssue(
        severity: IssueSeverity.warning,
        code: 'empty-value',
        message: 'مقدار «${e.name}» خالی است.',
        line: e.line,
        name: e.name,
      ));
    }

    // ۵) ترجمه‌نشده‌ها (فقط شمارش کلی)
    final List<XmlStringEntry> untranslated =
        entries.where((XmlStringEntry e) => e.looksUntranslated).toList();
    if (untranslated.isNotEmpty) {
      issues.add(ValidationIssue(
        severity: IssueSeverity.info,
        code: 'untranslated',
        message: '${untranslated.length} رشته به نظر ترجمه‌نشده است (متن لاتین دارد).',
      ));
    }

    // ۶) مقایسهٔ قالب‌های جای‌گذاری با فایل مرجع (در صورت وجود)
    if (baseline.isNotEmpty) {
      int mismatches = 0;
      for (final XmlStringEntry e in entries) {
        final String? ref = baseline[e.name];
        if (ref == null) continue;
        final List<String> a = extractPlaceholders(ref);
        final List<String> b = e.placeholders;
        if (a.join(',') != b.join(',')) {
          mismatches++;
          if (mismatches <= 30) {
            issues.add(ValidationIssue(
              severity: IssueSeverity.warning,
              code: 'placeholder-mismatch',
              message: 'قالب‌های «${e.name}» با متن انگلیسی یکسان نیست '
                  '(انگلیسی: ${a.isEmpty ? '—' : a.join(' ')} / فارسی: ${b.isEmpty ? '—' : b.join(' ')})',
              line: e.line,
              name: e.name,
            ));
          }
        }
      }
      if (mismatches > 30) {
        issues.add(ValidationIssue(
          severity: IssueSeverity.warning,
          code: 'placeholder-mismatch-more',
          message: '${mismatches - 30} مورد دیگر ناسازگاری قالب وجود دارد.',
        ));
      }
    }

    return ValidationReport(issues);
  }
}

/// استخراج نگاشت «نام ← مقدار» از یک متن XML (برای ساخت فایل مرجع انگلیسی)
Map<String, String> valuesByName(String xml) {
  final Map<String, String> map = <String, String>{};
  for (final XmlStringEntry e in const TelegramStringsParser().parse(xml)) {
    map.putIfAbsent(e.name, () => e.value);
  }
  return map;
}
