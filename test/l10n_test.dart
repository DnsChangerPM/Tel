// تست‌های چندزبانگی

import 'package:flutter_test/flutter_test.dart';
import 'package:tel/i18n/l10n.dart';

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
  'language',
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
}

extension on L10n {
  String? tableValue(String key) => L10n.table[key]?[language.code];
}
