// Tel — «ویرایشگر متن تلگرام»
//
// اطلاعات برنامه. مقادیر نسخه در زمان ساخت (ورکفلو GitHub Actions) به‌صورت
// --dart-define به برنامه تزریق می‌شوند تا همان نسخهٔ پرسیده‌شده در نام فایل
// انتشار، در داخل برنامه هم نمایش داده شود.

class AppInfo {
  const AppInfo._();

  static const String appName = 'Tel';

  static const String titleFa = 'تل — ویرایشگر متن تلگرام';

  static const String titleEn = 'Tel — Telegram strings editor';

  /// نسخه، از ورک‌فلو: TEL_APP_VERSION
  static const String version = String.fromEnvironment('TEL_APP_VERSION', defaultValue: '1.0.0');

  /// Build number از pubspec
  static const String buildNumber = String.fromEnvironment('TEL_BUILD_NUMBER', defaultValue: '1');

  /// زمان ساخت
  static const String buildTime = String.fromEnvironment('TEL_BUILD_TIME', defaultValue: 'dev');

  /// کانال ساخت (مثلاً build-local)
  static const String buildChannel = String.fromEnvironment('TEL_BUILD_CHANNEL', defaultValue: 'local');

  /// مخزن گیت‌هاب
  static const String repository =
      String.fromEnvironment('TEL_REPO', defaultValue: 'https://github.com/DnsChangerPM/Tel');

  /// شناسهٔ نسخهٔ کامل
  static String get fullVersion => '$version+$buildNumber';

  /// فایل‌های ترجمهٔ تلگرام که این برنامه برای ویرایش آن‌ها ساخته شده است
  static const List<String> telegramTargets = <String>[
    'tg_inline_strings.xml',
    'tg_strings.xml',
    'strings.xml',
  ];

  static const String aboutFa = '''
Tel یک ویرایشگر متن برای فایل‌های XML ترجمهٔ تلگرام است.

قابلیت‌ها:
• باز کردن فایل strings.xml (متن تلگرام)
• دیدن همهٔ رشته‌ها به‌صورت فهرست‌شده و ویرایش تک‌تک آن‌ها
• جست‌وجو و جایگزینی (حتی با Regular Expression)
• بررسی سلامت فایل: تگ‌های نامتوازن، نام تکراری، مقدار خالی، رشته‌های ترجمه‌نشده و قالب‌های ناسازگار
• ذخیرهٔ فایل بدون تغییر بقیهٔ خطوط (کامنت‌ها، ترتیب و فاصله‌ها دست‌نخورده می‌مانند)
• تأیید اعتبار XML و خروجی UTF-8 بدون BOM
''';

  static const String aboutEn = '''
Tel is a text editor for Telegram translation XML files.

Highlights:
• Open a Telegram strings.xml file (tg_inline_strings.xml)
• See every string as a list and edit them one by one
• Search and replace (regular expressions supported)
• Validate the file: unbalanced tags, duplicate names, empty values,
  untranslated entries and placeholder mismatches
• Save without touching the rest of the file (comments, order and spacing
  are preserved) and always write UTF-8 without BOM
''';
}
