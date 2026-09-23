// Tel — «ویرایشگر متن تلگرام»
//
// چندزبانگی سادهٔ برنامه (فارسی + انگلیسی) بدون هیچ پکیج بیرونی.
// زبان پیش‌فرض فارسی است و چیدمان برنامه راست‌به‌چپ می‌شود.

import 'package:flutter/widgets.dart';

enum AppLanguage {
  fa('fa', 'فارسی', TextDirection.rtl),
  en('en', 'English', TextDirection.ltr);

  const AppLanguage(this.code, this.label, this.direction);

  final String code;
  final String label;
  final TextDirection direction;

  static AppLanguage fromCode(String? code) {
    for (final AppLanguage lang in AppLanguage.values) {
      if (lang.code == code) return lang;
    }
    return AppLanguage.fa;
  }
}

class L10n {
  const L10n(this.language);

  final AppLanguage language;

  bool get isRtl => language.direction == TextDirection.rtl;

  TextDirection get direction => language.direction;

  String _t(String key) => (table[language.code] ?? table['fa']!)[key] ?? key;

  // --- سرصفحه و تب‌ها ---
  String get appTitle => _t('appTitle');

  String get appSubtitle => _t('appSubtitle');

  String get tabEditor => _t('tabEditor');

  String get tabEntries => _t('tabEntries');

  String get tabIssues => _t('tabIssues');

  String get tabHelp => _t('tabHelp');

  // --- دکمه‌ها ---
  String get openFile => _t('openFile');

  String get openSample => _t('openSample');

  String get save => _t('save');

  String get saveAs => _t('saveAs');

  String get copyAll => _t('copyAll');

  String get pasteFromClipboard => _t('pasteFromClipboard');

  String get clear => _t('clear');

  String get revertAll => _t('revertAll');

  String get revert => _t('revert');

  String get copy => _t('copy');

  String get close => _t('close');

  String get cancel => _t('cancel');

  String get applyEdits => _t('applyEdits');

  String get refreshList => _t('refreshList');

  String get undo => _t('undo');

  // --- جست‌وجو ---
  String get searchHint => _t('searchHint');

  String get replaceHint => _t('replaceHint');

  String get replace => _t('replace');

  String get replaceAll => _t('replaceAll');

  String get useRegex => _t('useRegex');

  String get caseSensitive => _t('caseSensitive');

  String get matchesFound => _t('matchesFound');

  String get goToNext => _t('goToNext');

  // --- فهرست رشته‌ها ---
  String get filterAll => _t('filterAll');

  String get filterUntranslated => _t('filterUntranslated');

  String get filterEdited => _t('filterEdited');

  String get filterEmpty => _t('filterEmpty');

  String get filterTechnical => _t('filterTechnical');

  String get keyLabel => _t('keyLabel');

  String get valueLabel => _t('valueLabel');

  String get lineLabel => _t('lineLabel');

  String get charLabel => _t('charLabel');

  String get placeholders => _t('placeholders');

  String get notTranslatable => _t('notTranslatable');

  String get edited => _t('edited');

  String get duplicate => _t('duplicate');

  String get noEntries => _t('noEntries');

  String get nothingFound => _t('nothingFound');

  String get entryCount => _t('entryCount');

  // --- وضعیت ---
  String get statusReady => _t('statusReady');

  String get statusNoFile => _t('statusNoFile');

  String get statusDirty => _t('statusDirty');

  String get statusSaved => _t('statusSaved');

  /// پرسش هنگام دور ریختن تغییرات ذخیره‌نشده
  String get discardQuestion => _t('discardQuestion');

  String get statusSavedTo => _t('statusSavedTo');

  String get statusLoaded => _t('statusLoaded');

  String get statusCopied => _t('statusCopied');

  String get statusError => _t('statusError');

  String get statusEditsApplied => _t('statusEditsApplied');

  // --- بررسی سلامت ---
  String get severityError => _t('severityError');

  String get severityWarning => _t('severityWarning');

  String get severityInfo => _t('severityInfo');

  String get noIssues => _t('noIssues');

  String get validateNow => _t('validateNow');

  String get loadEnglishReference => _t('loadEnglishReference');

  String get englishReferenceLoaded => _t('englishReferenceLoaded');

  String get englishReferenceHint => _t('englishReferenceHint');

  // --- تنظیمات و درباره ---
  String get language => _t('language');

  String get theme => _t('theme');

  String get themeLight => _t('themeLight');

  String get themeDark => _t('themeDark');

  String get themeSystem => _t('themeSystem');

  String get about => _t('about');

  String get version => _t('version');

  String get buildTime => _t('buildTime');

  String get buildChannel => _t('buildChannel');

  String get repository => _t('repository');

  String get settings => _t('settings');

  // --- پیام‌ها ---
  String get errorOpenFile => _t('errorOpenFile');

  String get errorSaveFile => _t('errorSaveFile');

  String get dialogsUnsupported => _t('dialogsUnsupported');

  String get xmlParseWarning => _t('xmlParseWarning');

  String get helpBody => _t('helpBody');

  String get sampleNotice => _t('sampleNotice');

  String get copyReport => _t('copyReport');

  String get pathLabel => _t('pathLabel');

  String get enterPathManually => _t('enterPathManually');

  String get loadFromPath => _t('loadFromPath');

  String get saveToPath => _t('saveToPath');

  /// جدول ترجمه‌ها: کد زبان ← (کلید ← متن)
  /// عمومی است تا تست‌ها بتوانند کامل بودن هر دو زبان را بررسی کنند.
  static const Map<String, Map<String, String>> table = <String, Map<String, String>>{
    'fa': <String, String>{
      'appTitle': 'تل — ویرایشگر متن تلگرام',
      'appSubtitle': 'ویرایش فایل‌های XML ترجمهٔ تلگرام (tg_inline_strings.xml)',
      'tabEditor': 'متن فایل',
      'tabEntries': 'رشته‌ها',
      'tabIssues': 'بررسی سلامت',
      'tabHelp': 'راهنما',
      'openFile': 'باز کردن فایل',
      'openSample': 'نمونه',
      'save': 'ذخیره',
      'saveAs': 'ذخیره با نام جدید',
      'copyAll': 'کپی همه',
      'pasteFromClipboard': 'چسباندن از کلیپ‌بورد',
      'clear': 'پاک کردن',
      'revertAll': 'برگشت همهٔ ویرایش‌ها',
      'revert': 'برگشت',
      'copy': 'کپی',
      'close': 'بستن',
      'cancel': 'لغو',
      'applyEdits': 'اعمال روی متن',
      'refreshList': 'بازخوانی فهرست',
      'undo': 'واگرد',
      'searchHint': 'جست‌وجو در متن…',
      'replaceHint': 'جایگزین با…',
      'replace': 'جایگزین',
      'replaceAll': 'جایگزینی همه',
      'useRegex': 'عبارت باقاعده',
      'caseSensitive': 'حساس به بزرگی/کوچکی',
      'matchesFound': 'مورد پیدا شد',
      'goToNext': 'بعدی',
      'filterAll': 'همه',
      'filterUntranslated': 'ترجمه‌نشده‌ها',
      'filterEdited': 'ویرایش‌شده‌ها',
      'filterEmpty': 'خالی‌ها',
      'filterTechnical': 'فنی/غیرقابل‌ترجمه',
      'keyLabel': 'نام',
      'valueLabel': 'متن',
      'lineLabel': 'خط',
      'charLabel': 'کاراکتر',
      'placeholders': 'قالب‌ها',
      'notTranslatable': 'ترجمه‌نشدنی',
      'edited': 'ویرایش‌شده',
      'duplicate': 'تکراری',
      'noEntries': 'هنوز فایلی باز نشده است. از دکمهٔ «باز کردن فایل» یا «نمونه» استفاده کنید.',
      'nothingFound': 'چیزی پیدا نشد.',
      'entryCount': 'تعداد رشته‌ها',
      'statusReady': 'آماده',
      'statusNoFile': 'فایلی باز نشده',
      'statusDirty': 'تغییرات ذخیره‌نشده',
      'statusSaved': 'ذخیره شد',
      'statusSavedTo': 'ذخیره شد در',
      'statusLoaded': 'بارگذاری شد',
      'statusCopied': 'در کلیپ‌بورد کپی شد',
      'statusError': 'خطا',
      'statusEditsApplied': 'ویرایش‌ها روی متن اعمال شد',
      'severityError': 'خطا',
      'severityWarning': 'هشدار',
      'severityInfo': 'اطلاع',
      'noIssues': 'مشکلی پیدا نشد؛ فایل سالم است.',
      'validateNow': 'بررسی کن',
      'loadEnglishReference': 'بارگذاری فایل انگلیسی (مرجع)',
      'englishReferenceLoaded': 'فایل مرجع انگلیسی بارگذاری شد',
      'englishReferenceHint': 'برای مقایسهٔ قالب‌های %s با متن اصلی انگلیسی',
      'language': 'زبان',
      'theme': 'پوسته',
      'themeLight': 'روشن',
      'themeDark': 'تیره',
      'themeSystem': 'سیستم',
      'about': 'درباره',
      'version': 'نسخه',
      'buildTime': 'زمان ساخت',
      'buildChannel': 'کانال ساخت',
      'repository': 'مخزن',
      'settings': 'تنظیمات',
      'errorOpenFile': 'باز کردن فایل ناموفق بود',
      'errorSaveFile': 'ذخیرهٔ فایل ناموفق بود',
      'dialogsUnsupported': 'روی این سیستم‌عامل دیالوگ فایل پشتیبانی نمی‌شود؛ متن را مستقیم بچسبانید یا مسیر را دستی وارد کنید.',
      'xmlParseWarning': 'هیچ تگ string پیدا نشد؛ شاید فایل XML استاندارد تلگرام نیست.',
      'discardQuestion': 'تغییرات ذخیره‌نشده دارید. آن‌ها را نادیده بگیرم؟',
      'copyReport': 'کپی گزارش',
      'sampleNotice': 'این یک فایل نمونه است؛ برای ترجمهٔ واقعی فایل tg_inline_strings.xml خود را باز کنید.',
      'pathLabel': 'مسیر فایل',
      'enterPathManually': 'وارد کردن مسیر به‌صورت دستی',
      'loadFromPath': 'خواندن از این مسیر',
      'saveToPath': 'ذخیره در این مسیر',
      'helpBody': '''
۱) فایل ترجمهٔ تلگرام را از مخزن گیت‌هاب تلگرام (پوشهٔ TMessagesProj/src/main/res/values-xx) بردارید؛
   فایل اصلی متن‌های اینلاین، tg_inline_strings.xml نام دارد.

۲) دکمهٔ «باز کردن فایل» را بزنید و فایل را انتخاب کنید.
   روی اندروید از پنجرهٔ خود سیستم (SAF) استفاده می‌شود و به مجوز خاصی نیاز نیست.

۳) در تب «رشته‌ها» هر متن را ویرایش کنید، یا در تب «متن فایل» کل XML را دستی تغییر دهید
   و از جست‌وجو/جایگزینی استفاده کنید.

۴) در تب «بررسی سلامت» فایل را بررسی کنید: تگ‌های نامتوازن، نام تکراری،
   مقدار خالی، رشته‌های ترجمه‌نشده و ناسازگاری قالب‌های %s.

۵) «ذخیره» را بزنید. خروجی UTF-8 و بدون BOM است و همهٔ کامنت‌ها، ترتیب و
   فاصله‌های فایل اصلی دست‌نخورده می‌مانند.

نکته‌های مهم:
• تلگرام کاراکترهای \\n را به‌عنوان خط جدید تفسیر می‌کند؛ آن‌ها را خراب نکنید.
• قالب‌هایی مثل %1$s و %d باید در متن ترجمه هم باقی بمانند وگرنه برنامه کرش می‌کند.
• برای مقایسهٔ خودکار قالب‌ها، فایل انگلیسی همان بخش را از «بررسی سلامت»
  به‌عنوان مرجع بارگذاری کنید.
''',
    },
    'en': <String, String>{
      'appTitle': 'Tel — Telegram strings editor',
      'appSubtitle': 'Edit Telegram translation XML files (tg_inline_strings.xml)',
      'tabEditor': 'Raw XML',
      'tabEntries': 'Strings',
      'tabIssues': 'Validation',
      'tabHelp': 'Help',
      'openFile': 'Open file',
      'openSample': 'Sample',
      'save': 'Save',
      'saveAs': 'Save as…',
      'copyAll': 'Copy all',
      'pasteFromClipboard': 'Paste from clipboard',
      'clear': 'Clear',
      'revertAll': 'Revert all edits',
      'revert': 'Revert',
      'copy': 'Copy',
      'close': 'Close',
      'cancel': 'Cancel',
      'applyEdits': 'Apply to text',
      'refreshList': 'Refresh list',
      'undo': 'Undo',
      'searchHint': 'Search…',
      'replaceHint': 'Replace with…',
      'replace': 'Replace',
      'replaceAll': 'Replace all',
      'useRegex': 'Regular expression',
      'caseSensitive': 'Case sensitive',
      'matchesFound': 'matches',
      'goToNext': 'Next',
      'filterAll': 'All',
      'filterUntranslated': 'Untranslated',
      'filterEdited': 'Edited',
      'filterEmpty': 'Empty',
      'filterTechnical': 'Technical',
      'keyLabel': 'Key',
      'valueLabel': 'Text',
      'lineLabel': 'Line',
      'charLabel': 'characters',
      'placeholders': 'Placeholders',
      'notTranslatable': 'not translatable',
      'edited': 'edited',
      'duplicate': 'duplicate',
      'noEntries': 'No file loaded yet. Use “Open file” or “Sample”.',
      'nothingFound': 'Nothing found.',
      'entryCount': 'Strings',
      'statusReady': 'Ready',
      'statusNoFile': 'No file',
      'statusDirty': 'Unsaved changes',
      'statusSaved': 'Saved',
      'statusSavedTo': 'Saved to',
      'statusLoaded': 'Loaded',
      'statusCopied': 'Copied to clipboard',
      'statusError': 'Error',
      'statusEditsApplied': 'Edits applied to text',
      'severityError': 'Error',
      'severityWarning': 'Warning',
      'severityInfo': 'Info',
      'noIssues': 'No problems found.',
      'validateNow': 'Validate',
      'loadEnglishReference': 'Load English reference',
      'englishReferenceLoaded': 'English reference loaded',
      'englishReferenceHint': 'Compare %s placeholders with the original English text',
      'language': 'Language',
      'theme': 'Theme',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'themeSystem': 'System',
      'about': 'About',
      'version': 'Version',
      'buildTime': 'Built',
      'buildChannel': 'Channel',
      'repository': 'Repository',
      'settings': 'Settings',
      'errorOpenFile': 'Could not open the file',
      'errorSaveFile': 'Could not save the file',
      'dialogsUnsupported': 'File dialogs are not supported here; paste the text or type a path.',
      'xmlParseWarning': 'No <string> tag found; is this a Telegram strings XML?',
      'discardQuestion': 'There are unsaved changes. Discard them?',
      'copyReport': 'Copy report',
      'sampleNotice': 'This is a sample file; open your own tg_inline_strings.xml for real work.',
      'pathLabel': 'File path',
      'enterPathManually': 'Enter a path manually',
      'loadFromPath': 'Load from this path',
      'saveToPath': 'Save to this path',
      'helpBody': '''
1) Get the Telegram translation file (TMessagesProj/src/main/res/values-xx);
   the inline strings live in tg_inline_strings.xml.

2) Press “Open file”. On Android the system file picker (SAF) is used,
   so no storage permission is required.

3) Edit texts in the “Strings” tab, or edit the raw XML in the “Raw XML” tab
   and use search & replace.

4) Run “Validate” to detect unbalanced tags, duplicate keys, empty values,
   untranslated entries and %s placeholder mismatches.

5) Press “Save”. The output is UTF-8 without BOM and keeps every comment,
   ordering and blank line of the original file.
''',
    },
  };
}
