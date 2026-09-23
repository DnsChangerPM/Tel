// تست‌های هستهٔ پارسر و ویرایشگر
//
// اجرا:  flutter test

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tel/core/xml_document.dart';

const String sample = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="Greeting">سلام</string>
    <string name="TwoLines">خط اول\\nخط دوم</string>
    <string name="Markup">&lt;b&gt;بولد&lt;/b&gt; &amp; بیشتر</string>
    <string name="KeepAsIs" translatable="false">tg://settings</string>
    <string name="SelfClosingEmpty"/>
    <string name="EmptyPair"></string>
    <!-- <string name="CommentedOut">نباید خوانده شود</string> -->
    <string name="WithPlaceholder">%1\$s پیام داد</string>
</resources>
''';

/// خواندن فایل نمونهٔ همراه برنامه (پوشهٔ جاری در تست‌ها ریشهٔ پروژه است)
String readSampleFile(String name) => File('assets/samples/$name').readAsStringSync();

void main() {
  group('TelegramStringsParser', () {
    test('همهٔ رشته‌ها خوانده می‌شوند و کامنت‌ها نادیده گرفته می‌شوند', () {
      final List<XmlStringEntry> entries = const TelegramStringsParser().parse(sample);
      expect(entries.length, 7);
      expect(
        entries.map((XmlStringEntry e) => e.name).toList(),
        <String>[
          'Greeting',
          'TwoLines',
          'Markup',
          'KeepAsIs',
          'SelfClosingEmpty',
          'EmptyPair',
          'WithPlaceholder',
        ],
      );
      expect(entries.any((XmlStringEntry e) => e.name == 'CommentedOut'), isFalse);
    });

    test('شمارهٔ خط‌ها درست است', () {
      final List<XmlStringEntry> entries = const TelegramStringsParser().parse(sample);
      expect(entries[0].line, 3);
      expect(entries[1].line, 4);
      expect(entries[6].line, 10);
    });

    test('مقادیر رمزگشایی می‌شوند ولی \\n دست‌نخورده می‌ماند', () {
      final List<XmlStringEntry> entries = const TelegramStringsParser().parse(sample);
      final XmlStringEntry twoLines = entries.firstWhere((XmlStringEntry e) => e.name == 'TwoLines');
      expect(twoLines.value, 'خط اول\\nخط دوم');
      expect(twoLines.preview, 'خط اول\nخط دوم');

      final XmlStringEntry markup = entries.firstWhere((XmlStringEntry e) => e.name == 'Markup');
      expect(markup.value, '<b>بولد</b> & بیشتر');
    });

    test('translatable=false و تگ خودبسته تشخیص داده می‌شوند', () {
      final List<XmlStringEntry> entries = const TelegramStringsParser().parse(sample);
      expect(entries.firstWhere((XmlStringEntry e) => e.name == 'KeepAsIs').translatable, isFalse);
      expect(entries.firstWhere((XmlStringEntry e) => e.name == 'SelfClosingEmpty').selfClosing, isTrue);
      expect(entries.firstWhere((XmlStringEntry e) => e.name == 'EmptyPair').selfClosing, isFalse);
      expect(entries.firstWhere((XmlStringEntry e) => e.name == 'EmptyPair').isEmptyValue, isTrue);
    });

    test('قالب‌های جای‌گذاری پیدا می‌شوند', () {
      expect(extractPlaceholders('a %1\$s b %d c {0} {name}'), <String>['%1\$s', '%d', '{0}', '{name}']);
      expect(extractPlaceholders('بدون قالب'), isEmpty);
    });

    test('تشخیص ترجمه‌نشده', () {
      final List<XmlStringEntry> entries = const TelegramStringsParser().parse(
        '<resources><string name="X">Delete for all members</string>'
        '<string name="Y">حذف برای همه</string>'
        '<string name="AppName">Telegram</string></resources>',
      );
      expect(entries[0].looksUntranslated, isTrue);
      expect(entries[1].looksUntranslated, isFalse);
      expect(entries[2].looksUntranslated, isFalse, reason: 'کلیدهای فنی نادیده گرفته می‌شوند');
    });
  });

  group('XmlDocument', () {
    test('ویرایش یک رشته فقط همان خط را تغییر می‌دهد', () {
      final XmlDocument doc = XmlDocument(source: sample);
      doc.setValue(doc.entries.first, 'درود');

      final String rendered = doc.render();
      expect(rendered, contains('<string name="Greeting">درود</string>'));
      expect(
        rendered.replaceFirst(
          '<string name="Greeting">درود</string>',
          '<string name="Greeting">سلام</string>',
        ),
        sample,
        reason: 'بقیهٔ فایل باید بی‌کم‌وکاست دست‌نخورده بماند',
      );
      expect(doc.source, sample, reason: 'source تا زمان commit تغییر نمی‌کند');
      expect(doc.isDirty, isTrue);
      expect(doc.changedCount, 1);
    });

    test('مقادیر جدید به‌درستی escape می‌شوند', () {
      final XmlDocument doc = XmlDocument(source: sample);
      final XmlStringEntry markup = doc.entries.firstWhere((XmlStringEntry e) => e.name == 'Markup');
      doc.setValue(markup, '<i>تست</i> & «نقل‌قول»');
      expect(doc.render(), contains('&lt;i&gt;تست&lt;/i&gt; &amp; «نقل‌قول»'));
    });

    test('تگ خودبسته هنگام ویرایش به تگ زوج تبدیل می‌شود', () {
      final XmlDocument doc = XmlDocument(source: sample);
      final XmlStringEntry selfClosing =
          doc.entries.firstWhere((XmlStringEntry e) => e.name == 'SelfClosingEmpty');
      doc.setValue(selfClosing, 'مقدار تازه');
      expect(doc.render(), contains('<string name="SelfClosingEmpty">مقدار تازه</string>'));
    });

    test('برگشت ویرایش‌ها', () {
      final XmlDocument doc = XmlDocument(source: sample);
      doc.setValue(doc.entries.first, 'چیز دیگری');
      expect(doc.hasPendingEdits, isTrue);
      doc.revertAllEdits();
      expect(doc.hasPendingEdits, isFalse);
      expect(doc.render(), sample);
      expect(doc.isDirty, isFalse);
    });

    test('commit تغییرات را تثبیت می‌کند', () {
      final XmlDocument doc = XmlDocument(source: sample);
      doc.setValue(doc.entries.first, 'درود');
      doc.commit();
      expect(doc.hasPendingEdits, isFalse);
      expect(doc.isDirty, isFalse);
      expect(doc.entries.first.value, 'درود');
      expect(doc.source, contains('درود'));
    });

    test('نام‌های تکراری تشخیص داده می‌شوند و همه با هم ویرایش می‌شوند', () {
      const String dup = '<resources><string name="A">یک</string><string name="A">دو</string></resources>';
      final XmlDocument doc = XmlDocument(source: dup);
      expect(doc.entries.length, 2);
      expect(doc.entries[1].isDuplicate, isTrue);
      expect(doc.duplicates.length, 1);

      doc.setValue(doc.entries.first, 'سه');
      expect(
        doc.render(),
        '<resources><string name="A">سه</string><string name="A">سه</string></resources>',
      );
    });

    test('فایل نمونهٔ همراه برنامه بدون خطا خوانده می‌شود', () {
      final String text = readSampleFile('tg_inline_strings_sample.xml');
      final XmlDocument doc = XmlDocument(source: text);
      expect(doc.entries.length, greaterThan(30));
      expect(doc.duplicates, isEmpty);
      expect(doc.untranslatedCount, greaterThan(0));
      expect(doc.render(), text, reason: 'بدون ویرایش، خروجی باید عیناً همان ورودی باشد');
    });
  });

  group('escape و unescape', () {
    test('رفت و برگشت درست انجام می‌شود', () {
      expect(unescapeXmlValue('&amp;lt;'), '&lt;');
      expect(unescapeXmlValue('&amp;'), '&');
      expect(unescapeXmlValue('&#39;'), "'");
      expect(unescapeXmlValue('&#x27;'), "'");
      expect(escapeXmlValue('a & b < c > d'), 'a &amp; b &lt; c &gt; d');
      expect(unescapeXmlValue(escapeXmlValue('۵ & ۶ < ۷')), '۵ & ۶ < ۷');
    });
  });
}
