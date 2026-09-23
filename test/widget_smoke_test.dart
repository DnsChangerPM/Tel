// تست‌های رابط کاربری: بالا آمدن برنامه، تب‌ها، ویرایش رشته‌ها و ذخیرهٔ فایل.
//
// اجرا:  flutter test
//
// نکته‌های مهم این فایل:
//   * کارهای واقعی (خواندن/نوشتن فایل، bootstrap و setLanguage) داخل
//     tester.runAsync انجام می‌شوند؛ در محیط تست ویجت، I/O واقعی بیرون از
//     runAsync تمام نمی‌شود.
//   * به‌جای pumpAndSettle از چند pump با زمان محدود استفاده می‌کنیم تا اگر
//     ویجتی در حال انیمیشن بود، تست بی‌نهایت منتظر نماند.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tel/i18n/l10n.dart';
import 'package:tel/main.dart';
import 'package:tel/state/editor_state.dart';

/// یک فایل نمونهٔ کوچک با حالت‌های مختلف (عادی، ترجمه‌نشده، خودبسته)
const String sample = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="Greeting">سلام</string>
    <string name="Untranslated">Delete for all members</string>
    <string name="WithPlaceholder">%1\$s پیام داد</string>
    <string name="SelfClosing"/>
</resources>
''';

/// برنامه را با یک وضعیت آماده بالا می‌آورد
Future<EditorState> pumpApp(WidgetTester tester, {String? source}) async {
  final EditorState state = EditorState();
  // کارهای واقعی (خواندن تنظیمات و نوشتن زبان) بیرون از محیط fake انجام می‌شوند
  await tester.runAsync(() async {
    await state.bootstrap();
    await state.setLanguage(AppLanguage.fa);
  });
  if (source != null) {
    state.loadText(source, name: 'tg_inline_strings.xml');
  }
  await tester.pumpWidget(TelApp(state: state));
  await settle(tester);
  return state;
}

/// چند فریم می‌پمپ می‌کند (بدون انتظار بی‌پایان)
Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('برنامه بالا می‌آید و چهار تب را نشان می‌دهد', (WidgetTester tester) async {
    await pumpApp(tester, source: sample);

    expect(find.text('رشته‌ها'), findsWidgets, reason: 'تب «رشته‌ها»');
    expect(find.text('بررسی سلامت'), findsWidgets, reason: 'تب «بررسی سلامت»');
    expect(find.text('راهنما'), findsWidgets, reason: 'تب «راهنما»');
  });

  testWidgets('وقتی فایلی باز نشده، صفحهٔ خوش‌آمد و دکمه‌های شروع دیده می‌شود',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('باز کردن فایل'), findsWidgets);
    expect(find.text('نمونه'), findsWidgets);
  });

  testWidgets('رشته‌های فایل پارس می‌شوند و فیلتر «ترجمه‌نشده» کار می‌کند',
      (WidgetTester tester) async {
    final EditorState state = await pumpApp(tester, source: sample);

    expect(state.document.entries.length, 4);
    expect(state.filteredEntries.length, 4);

    state.setFilter(EntryFilter.untranslated);
    await settle(tester);

    expect(state.filteredEntries.length, 1, reason: 'فقط یک رشته ترجمه‌نشده است');
    expect(state.filteredEntries.first.name, 'Untranslated');
  });

  testWidgets('ویرایش یک رشته در متن نهایی XML نوشته می‌شود', (WidgetTester tester) async {
    final EditorState state = await pumpApp(tester, source: sample);

    state.setEntryValue(state.document.entries.first, 'درود بر همه');
    await settle(tester);

    expect(state.isDirty, isTrue);
    expect(state.document.hasPendingEdits, isTrue);
    expect(state.document.render(), contains('<string name="Greeting">درود بر همه</string>'));
    expect(state.document.render(), contains('<string name="Untranslated">'),
        reason: 'بقیهٔ فایل دست‌نخورده');
  });

  testWidgets('ذخیره روی دیسک بدون دست‌زدن به بقیهٔ فایل انجام می‌شود',
      (WidgetTester tester) async {
    final EditorState state = await pumpApp(tester, source: sample);
    state.setEntryValue(state.document.entries[1], 'حذف برای همه');

    final Directory? dir =
        await tester.runAsync(() => Directory.systemTemp.createTemp('tel_widget_test'));
    expect(dir, isNotNull);
    final String path = '${dir!.path}/tg_inline_strings.xml';
    addTearDown(() => dir.deleteSync(recursive: true));

    final bool? ok = await tester.runAsync(() => state.save(explicitPath: path));
    await settle(tester);

    expect(ok, isTrue);
    final String written = File(path).readAsStringSync();
    expect(written, contains('<string name="Untranslated">حذف برای همه</string>'));
    expect(written, contains('<string name="Greeting">سلام</string>'),
        reason: 'رشته‌های دیگر تغییر نکرده‌اند');
    expect(written, contains('<string name="SelfClosing"/>'), reason: 'تگ خودبسته حفظ شده است');
    expect(state.isDirty, isFalse, reason: 'بعد از ذخیره دیگر تغییری در انتظار نیست');
  });

  testWidgets('تغییر زبان، متن رابط کاربری را انگلیسی می‌کند', (WidgetTester tester) async {
    final EditorState state = await pumpApp(tester, source: sample);
    expect(state.l10n.tabEntries, 'رشته‌ها');

    await tester.runAsync(() => state.setLanguage(AppLanguage.en));
    await settle(tester);

    expect(find.text('Strings'), findsWidgets);
    expect(find.text('Validation'), findsWidgets);
  });
}
