// تست‌های رابط کاربری: بالا آمدن برنامه، تب‌ها، ویرایش رشته‌ها و ذخیرهٔ فایل.
//
// اجرا:  flutter test
//
// توجه: روی همهٔ پلتفرم‌ها (لینوکس/ویندوز/مک) اجرا می‌شود و به دیالوگ فایل
// وابسته نیست؛ ذخیره‌سازی با مسیر مستقیم انجام می‌شود.

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

Future<EditorState> pumpApp(WidgetTester tester, {String? source}) async {
  final EditorState state = EditorState();
  await state.bootstrap();
  await state.setLanguage(AppLanguage.fa);
  if (source != null) {
    state.loadText(source, name: 'tg_inline_strings.xml');
  }
  await tester.pumpWidget(TelApp(state: state));
  await tester.pumpAndSettle();
  return state;
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
    await tester.pumpAndSettle();

    expect(state.filteredEntries.length, 1, reason: 'فقط یک رشته ترجمه‌نشده است');
    expect(state.filteredEntries.first.name, 'Untranslated');
  });

  testWidgets('ویرایش یک رشته در متن نهایی XML نوشته می‌شود', (WidgetTester tester) async {
    final EditorState state = await pumpApp(tester, source: sample);

    state.setEntryValue(state.document.entries.first, 'درود بر همه');
    await tester.pumpAndSettle();

    expect(state.isDirty, isTrue);
    expect(state.document.hasPendingEdits, isTrue);
    expect(state.document.render(), contains('<string name="Greeting">درود بر همه</string>'));
    expect(state.document.render(), contains('<string name="Untranslated">'), reason: 'بقیهٔ فایل دست‌نخورده');
  });

  testWidgets('ذخیره روی دیسک بدون دست‌زدن به بقیهٔ فایل انجام می‌شود',
      (WidgetTester tester) async {
    final EditorState state = await pumpApp(tester, source: sample);
    state.setEntryValue(state.document.entries[1], 'حذف برای همه');

    final Directory dir = await Directory.systemTemp.createTemp('tel_widget_test');
    addTearDown(() => dir.delete(recursive: true));
    final String path = '${dir.path}/tg_inline_strings.xml';

    final bool ok = await state.save(explicitPath: path);
    await tester.pumpAndSettle();

    expect(ok, isTrue);
    final String written = File(path).readAsStringSync();
    expect(written, contains('<string name="Untranslated">حذف برای همه</string>'));
    expect(written, contains('<string name="Greeting">سلام</string>'), reason: 'رشته‌های دیگر تغییر نکرده‌اند');
    expect(written, contains('<string name="SelfClosing"/>'), reason: 'تگ خودبسته حفظ شده است');
    expect(state.isDirty, isFalse, reason: 'بعد از ذخیره دیگر تغییری در انتظار نیست');
  });

  testWidgets('تغییر زبان، متن رابط کاربری را انگلیسی می‌کند', (WidgetTester tester) async {
    final EditorState state = await pumpApp(tester, source: sample);
    expect(state.l10n.tabEntries, 'رشته‌ها');

    await state.setLanguage(AppLanguage.en);
    await tester.pumpAndSettle();

    expect(find.text('Strings'), findsWidgets);
    expect(find.text('Validation'), findsWidgets);
  });
}
