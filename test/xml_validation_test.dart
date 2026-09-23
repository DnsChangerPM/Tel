// تست‌های اعتبارسنجی فایل ترجمه
//
// اجرا:  flutter test

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tel/core/xml_document.dart';
import 'package:tel/core/xml_validation.dart';

ValidationReport validate(String xml, {Map<String, String> baseline = const <String, String>{}}) {
  return const XmlValidator().validate(xml, const TelegramStringsParser().parse(xml), baseline: baseline);
}

void main() {
  group('XmlValidator', () {
    test('فایل سالم بدون خطا است', () {
      final ValidationReport report = validate(
        '<resources><string name="A">سلام</string><string name="B">%1\$s خوب</string></resources>',
      );
      expect(report.hasErrors, isFalse);
      expect(report.errorCount, 0);
    });

    test('فایل خالی خطا می‌دهد', () {
      final ValidationReport report = validate('   ');
      expect(report.hasErrors, isTrue);
      expect(report.issues.first.code, 'empty-file');
    });

    test('نبود تگ <string> خطا است', () {
      final ValidationReport report = validate('<resources></resources>');
      expect(report.issues.any((ValidationIssue i) => i.code == 'no-strings'), isTrue);
    });

    test('تگ‌های نامتوازن تشخیص داده می‌شوند', () {
      final ValidationReport report = validate(
        '<resources><string name="A">سلام</string><string name="B">بدون پایان</resources>',
      );
      expect(report.issues.any((ValidationIssue i) => i.code == 'unbalanced-tags'), isTrue);
      expect(report.hasErrors, isTrue);
    });

    test('کاراکتر & بدون escape خطا است', () {
      final ValidationReport report = validate(
        '<resources><string name="A">سلام & خداحافظ</string></resources>',
      );
      expect(report.issues.any((ValidationIssue i) => i.code == 'invalid-entity'), isTrue);
    });

    test('&amp; معتبر خطا حساب نمی‌شود', () {
      final ValidationReport report = validate(
        '<resources><string name="A">سلام &amp; خداحافظ</string></resources>',
      );
      expect(report.issues.any((ValidationIssue i) => i.code == 'invalid-entity'), isFalse);
    });

    test('نام تکراری و مقدار خالی هشدار می‌دهند', () {
      final ValidationReport report = validate(
        '<resources><string name="A">یک</string><string name="A">دو</string>'
        '<string name="B"></string></resources>',
      );
      expect(report.issues.any((ValidationIssue i) => i.code == 'duplicate-name'), isTrue);
      expect(report.issues.any((ValidationIssue i) => i.code == 'empty-value'), isTrue);
      expect(report.warningCount, greaterThanOrEqualTo(2));
      expect(report.hasErrors, isFalse);
    });

    test('رشته‌های ترجمه‌نشده گزارش می‌شوند', () {
      final ValidationReport report = validate(
        '<resources><string name="A">Delete for all</string><string name="B">حذف</string></resources>',
      );
      expect(report.issues.any((ValidationIssue i) => i.code == 'untranslated'), isTrue);
    });

    test('با فایل مرجع، ناسازگاری قالب‌ها پیدا می‌شود', () {
      final Map<String, String> baseline = valuesByName(
        '<resources><string name="A">Sent to %1\$s</string><string name="B">Done</string></resources>',
      );
      final ValidationReport report = validate(
        '<resources><string name="A">فرستاده شد به شما</string><string name="B">انجام شد</string></resources>',
        baseline: baseline,
      );
      final Iterable<ValidationIssue> mismatches =
          report.issues.where((ValidationIssue i) => i.code == 'placeholder-mismatch');
      expect(mismatches.length, 1);
      expect(mismatches.first.name, 'A');
    });

    test('قالب‌های یکسان هشدار نمی‌دهند', () {
      final Map<String, String> baseline = valuesByName(
        '<resources><string name="A">Sent to %1\$s</string></resources>',
      );
      final ValidationReport report = validate(
        '<resources><string name="A">فرستاده شد به %1\$s</string></resources>',
        baseline: baseline,
      );
      expect(report.issues.any((ValidationIssue i) => i.code == 'placeholder-mismatch'), isFalse);
    });

    test('فایل‌های نمونهٔ همراه برنامه با هم سازگارند', () {
      final String fa = File('assets/samples/tg_inline_strings_sample.xml').readAsStringSync();
      final String en = File('assets/samples/tg_inline_strings_en_sample.xml').readAsStringSync();

      final ValidationReport report =
          const XmlValidator().validate(fa, const TelegramStringsParser().parse(fa), baseline: valuesByName(en));
      expect(report.hasErrors, isFalse, reason: 'فایل نمونه نباید خطای ساختاری داشته باشد');

      // نمونهٔ عمداً ناسازگار: PremiumDescription قالب یکسانی دارد، پس فقط
      // رشته‌های عمداً دست‌نخورده باید گزارش شوند.
      expect(report.issues.any((ValidationIssue i) => i.code == 'untranslated'), isTrue);
      expect(report.issues.any((ValidationIssue i) => i.code == 'duplicate-name'), isFalse);
    });
  });

  group('valuesByName', () {
    test('نگاشت نام ← مقدار ساخته می‌شود', () {
      final Map<String, String> map = valuesByName(
        '<resources><string name="A">یک</string><string name="B">دو</string></resources>',
      );
      expect(map, <String, String>{'A': 'یک', 'B': 'دو'});
    });
  });
}
