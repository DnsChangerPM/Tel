// تست‌های چندزبانگی

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tel/i18n/l10n.dart';
import 'package:tel/i18n/localizations.dart';

/// همهٔ کلیدهای ترجمه برای بررسی هم‌ارزی دو زبان
const List<String> allKeys = <String>[
  'appTitle',
  'appSubtitle',
  'tabEditor',
  'tabEntries',
  'tabIssues',
  'tabHelp',
  'openFile',
  'openSample',
  'save',
  'saveAs',
  'copyAll',
  'pasteFromClipboard',
  'clear',
  'revertAll',
  'revert',
  'copy',
  'close',
  'cancel',
  'applyEdits',
  'refreshList',
  'undo',
  'searchHint',
  'replaceHint',
  'replace',
  'replaceAll',
  'useRegex',
  'caseSensitive',
  'matchesFound',
  'goToNext',
  'filterAll',
  'filterUntranslated',
  'filterEdited',
  'filterEmpty',
  'filterTechnical',
  'keyLabel',
  'valueLabel',
  'lineLabel',
  'charLabel',
  'placeholders',
  'notTranslatable',
  'edited',
  'duplicate',
  'noEntries',
  'nothingFound',
  'entryCount',
  'statusReady',
  'statusNoFile',
  'statusDirty',
  'statusSaved',
  'statusSavedTo',
  'statusLoaded',
  'statusCopied',
  'statusError',
  'statusEditsApplied',
  'severityError',
  'severityWarning',
  'severityInfo',
  'noIssues',
  'validateNow',
  'loadEnglishReference',
  'englishReferenceLoaded',
  'englishReferenceHint',
  'languageLabel',
  'theme',
  'themeLight',
  'themeDark',
  'themeSystem',
  'about',
  'version',
  'buildTime',
  'buildChannel',
  'repository',
  'settings',
  'errorOpenFile',
  'errorSaveFile',
  'dialogsUnsupported',
  'xmlParseWarning',
  'helpBody',
  'sampleNotice',
  'discardQuestion',
  'copyReport',
  'pathLabel',
  'enterPathManually',
  'loadFromPath',
  'saveToPath',
];

void main() {
  test('هر دو زبان همهٔ کلیدها را دارند', () {
    for (final String key in allKeys) {
      for (final AppLanguage lang in AppLanguage.values) {
        final String? value = L10n(lang).tableValue(key);
        expect(value, isNotNull, reason: 'کلید $key در زبان ${lang.code} نیست');
        expect(value!.trim(), isNotEmpty, reason: 'کلید $key در زبان ${lang.code} خالی است');
      }
    }
  });

  test('متن‌های فارسی و انگلیسی متفاوت‌اند', () {
    const L10n fa = L10n(AppLanguage.fa);
    const L10n en = L10n(AppLanguage.en);
    expect(fa.appTitle, isNot(en.appTitle));
    expect(fa.tabEntries, 'رشته‌ها');
    expect(en.tabEntries, 'Strings');
  });

  test('جهت متن بر اساس زبان تعیین می‌شود', () {
    expect(const L10n(AppLanguage.fa).isRtl, isTrue);
    expect(const L10n(AppLanguage.en).isRtl, isFalse);
  });

  test('کد زبان ناشناخته به فارسی برمی‌گردد', () {
    expect(AppLanguage.fromCode('de'), AppLanguage.fa);
    expect(AppLanguage.fromCode(null), AppLanguage.fa);
    expect(AppLanguage.fromCode('en'), AppLanguage.en);
  });

  test('متن‌های آمادهٔ Material برای فارسی ترجمه شده‌اند', () {
    const PersianMaterialLocalizations fa = PersianMaterialLocalizations();
    expect(fa.okButtonLabel, 'تأیید');
    expect(fa.cancelButtonLabel, 'انصراف');
    expect(fa.searchFieldLabel, 'جست‌وجو');
    // متن‌هایی که ترجمه نشده‌اند از پیش‌فرض انگلیسی به ارث می‌رسند.
    expect(fa.aboutListTileTitle('Tel'), 'About Tel');
  });

  test('delegate متن‌های Cupertino همهٔ زبان‌ها را پشتیبانی می‌کند', () {
    const AppCupertinoLocalizationsDelegate cupertino = AppCupertinoLocalizationsDelegate();
    expect(cupertino.isSupported(const Locale('fa')), isTrue);
    expect(cupertino.isSupported(const Locale('en')), isTrue);
    expect(cupertino.shouldReload(cupertino), isFalse);
  });

  test('delegate متن‌های Material همهٔ زبان‌ها را پشتیبانی می‌کند', () {
    const AppMaterialLocalizationsDelegate delegate = AppMaterialLocalizationsDelegate();
    // بدون این delegate، زبان فارسی باعث خطای «No MaterialLocalizations found»
    // در TextField و Tooltip می‌شود.
    expect(delegate.isSupported(const Locale('fa')), isTrue);
    expect(delegate.isSupported(const Locale('en')), isTrue);
    expect(delegate.isSupported(const Locale('de')), isTrue);
    expect(delegate.shouldReload(delegate), isFalse);
  });
}

extension on L10n {
  String? tableValue(String key) => L10n.table[language.code]?[key];
}
