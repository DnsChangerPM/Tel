// تست رابط کاربری: برنامه بالا می‌آید، تب‌ها کار می‌کنند و زبان عوض می‌شود.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tel/i18n/l10n.dart';
import 'package:tel/main.dart';
import 'package:tel/state/editor_state.dart';

String sampleText() => File('assets/samples/tg_inline_strings_sample.xml').readAsStringSync();

void main() {
  testWidgets('برنامه بالا می‌آید و فایل نمونه را نشان می‌دهد', (WidgetTester tester) async {
    final EditorState state = EditorState();
    await state.bootstrap();
    state.loadText(sampleText(), name: 'tg_inline_strings.xml');

    await tester.pumpWidget(TelApp(state: state));
    await tester.pumpAndSettle();

    expect(find.textContaining('تل — ویرایشگر متن تلگرام'), findsWidgets);
    expect(find.text('متن فایل'), findsOneWidget, reason: 'تب ویرایشگر');
    expect(find.text('رشته‌ها'), findsOneWidget, reason: 'تب فهرست رشته‌ها');

    await tester.tap(find.text('رشته‌ها'));
    await tester.pumpAndSettle();

    expect(find.textContaining('AppName'), findsWidgets, reason: 'فهرست رشته‌ها باید دیده شود');
  });

  testWidgets('صفحهٔ خوش‌آمد وقتی فایلی باز نشده است', (WidgetTester tester) async {
    final EditorState state = EditorState();
    await state.bootstrap();

    await tester.pumpWidget(TelApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('باز کردن فایل'), findsWidgets);
    expect(find.text('نمونه'), findsWidgets);
  });

  testWidgets('تغییر زبان به انگلیسی، متن‌ها را عوض می‌کند', (WidgetTester tester) async {
    final EditorState state = EditorState();
    await state.bootstrap();
    state.loadText('<resources><string name="A">سلام</string></resources>', name: 'a.xml');

    await tester.pumpWidget(TelApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('رشته‌ها'), findsOneWidget);

    await state.setLanguage(AppLanguage.en);
    await tester.pumpAndSettle();

    expect(find.text('Strings'), findsOneWidget);
    expect(find.text('Raw XML'), findsOneWidget);
  });

  testWidgets('ویرایش یک رشته در فهرست، متن XML را تغییر می‌دهد', (WidgetTester tester) async {
    final EditorState state = EditorState();
    await state.bootstrap();
    state.loadText('<resources>\n    <string name="A">سلام</string>\n</resources>', name: 'a.xml');

    await tester.pumpWidget(TelApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('رشته‌ها'));
    await tester.pumpAndSettle();

    final Finder field = find.byType(TextField).last;
    await tester.enterText(field, 'درود بر همه');
    await tester.pumpAndSettle();

    expect(state.document.hasPendingEdits, isTrue);
    expect(state.document.render(), contains('<string name="A">درود بر همه</string>'));
  });
}
