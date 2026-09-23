// تست‌های لایهٔ فایل (بدون نیاز به دیالوگ واقعی)
//
// اجرا:  flutter test

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tel/services/file_io_service.dart';

void main() {
  group('decodeText', () {
    test('UTF-8 خوانده می‌شود', () {
      expect(FileIoService.decodeText(utf8.encode('سلام دنیا')), 'سلام دنیا');
    });

    test('UTF-8 با BOM خوانده و BOM حذف می‌شود', () {
      final List<int> bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode('<resources/>')];
      expect(FileIoService.stripBom(FileIoService.decodeText(bytes)), '<resources/>');
    });

    test('UTF-16 LE خوانده می‌شود', () {
      final List<int> body = <int>[];
      for (final int unit in 'تل'.codeUnits) {
        body.add(unit & 0xFF);
        body.add((unit >> 8) & 0xFF);
      }
      final String text = FileIoService.stripBom(FileIoService.decodeText(<int>[0xFF, 0xFE, ...body]));
      expect(text, 'تل');
    });
  });

  group('ابزارهای متنی', () {
    test('stripBom فقط در صورت وجود BOM عمل می‌کند', () {
      expect(FileIoService.stripBom('\uFEFF<resources/>'), '<resources/>');
      expect(FileIoService.stripBom('<resources/>'), '<resources/>');
      expect(FileIoService.stripBom(''), '');
    });

    test('خط جدید انتهایی تضمین می‌شود', () {
      expect(FileIoService.ensureTrailingNewline('a'), 'a\n');
      expect(FileIoService.ensureTrailingNewline('a\n'), 'a\n');
    });
  });

  group('نوشتن و خواندن مستقیم روی دیسک', () {
    test('فایل با UTF-8 بدون BOM نوشته می‌شود', () async {
      final Directory dir = await Directory.systemTemp.createTemp('tel_test');
      addTearDown(() => dir.delete(recursive: true));
      final String path = '${dir.path}/tg_inline_strings.xml';

      final FileIoService service = FileIoService();
      final SavedTextFile saved = await service.writeFileByPath(
        path,
        '<?xml version="1.0" encoding="utf-8"?>\n<resources/>',
      );
      expect(saved.path, path);

      final List<int> raw = await File(path).readAsBytes();
      expect(raw.sublist(0, 3), isNot(<int>[0xEF, 0xBB, 0xBF]), reason: 'نباید BOM داشته باشد');
      expect(await File(path).readAsString(), endsWith('</resources/>\n'));

      final OpenedTextFile opened = await service.readFileByPath(path);
      expect(opened.name, 'tg_inline_strings.xml');
      expect(opened.text, contains('<resources/>'));
    });

    test('فایل ناموجود خطای خوانا می‌دهد', () async {
      final FileIoService service = FileIoService();
      await expectLater(
        service.readFileByPath('/tmp/این-فایل-وجود-ندارد-${DateTime.now().microsecondsSinceEpoch}.xml'),
        throwsA(isA<FileIoException>()),
      );
    });
  });

  group('اسکریپت‌های PowerShell دیالوگ فایل', () {
    test('اسکریپت باز کردن فایل، اجزای لازم را دارد', () {
      final String script = FileIoService.openFileScriptDebug;
      expect(script, contains('OpenFileDialog'));
      expect(script, contains(r'[Console]::Out.Write'));
      expect(script, contains('System.Windows.Forms'));
      expect(_isBalanced(script, '{', '}'), isTrue, reason: 'آکولادها باید متوازن باشند');
      expect(script.contains(r'$owner'), isTrue, reason: 'پنجرهٔ مالک برای جلوگیری از پنهان‌ماندن دیالوگ');
    });

    test('اسکریپت ذخیرهٔ فایل، اجزای لازم را دارد', () {
      final String script = FileIoService.saveFileScriptDebug;
      expect(script, contains('SaveFileDialog'));
      expect(script, contains(r'$suggestedName'));
      expect(_isBalanced(script, '{', '}'), isTrue);
      expect(_isBalanced(script, '(', ')'), isTrue);
    });
  });

  group('پشتیبانی پلتفرم', () {
    test('روی ویندوز دیالوگ‌ها فعال‌اند', () {
      final FileIoService service = FileIoService();
      if (Platform.isWindows) {
        expect(service.supportsFileDialogs, isTrue);
        expect(service.isWindows, isTrue);
      } else {
        expect(service.supportsFileDialogs, isFalse);
      }
    });
  });
}

bool _isBalanced(String text, String open, String close) {
  int depth = 0;
  for (int i = 0; i < text.length; i++) {
    if (text[i] == open) depth++;
    if (text[i] == close) depth--;
    if (depth < 0) return false;
  }
  return depth == 0;
}
