// Tel — «ویرایشگر متن تلگرام»
//
// هستهٔ منطق برنامه: خواندن فایل‌های strings.xml تلگرام (مثل tg_inline_strings.xml)،
// استخراج رشته‌ها، رمزگشایی کاراکترهای escape و نوشتن مقادیر جدید در همان متن
// بدون دست‌زدن به بقیهٔ فایل (کامنت‌ها، ترتیب، فاصله‌ها و ...).
//
// پارسر عمداً «متحمل» (tolerant) است تا فایل‌های واقعی تلگرام را دقیقاً همان‌طور
// که هستند بخواند. هیچ وابستگی بیرونی‌ای وجود ندارد.

/// یک رشته (string) از فایل strings.xml
class XmlStringEntry {
  XmlStringEntry({
    required this.name,
    required this.rawValue,
    required this.translatable,
    required this.line,
    required this.outerStart,
    required this.outerEnd,
    required this.valueStart,
    required this.valueEnd,
    required this.selfClosing,
    required this.rawAttributes,
    required this.isDuplicate,
  });

  /// نام منبع، مثل `VoipGroupDisableAutoDelete`
  final String name;

  /// مقدار خام همان‌طور که در فایل نوشته شده (`&amp;`، `\n` و ...)
  final String rawValue;

  /// آیا قابل ترجمه است (یعنی `translatable="false"` ندارد)
  final bool translatable;

  /// شمارهٔ خط در متن (از ۱)
  final int line;

  /// ابتدای کل تگ `<string ...>...</string>`
  final int outerStart;

  /// انتهای کل تگ
  final int outerEnd;

  /// ابتدای متن داخل تگ
  final int valueStart;

  /// انتهای متن داخل تگ
  final int valueEnd;

  /// آیا تگ خودبسته است؟ `<string name="X"/>`
  final bool selfClosing;

  /// ویژگی‌های خام تگ، مثل `name="X" translatable="false"`
  final String rawAttributes;

  /// آیا نام این منبع تکراری است؟
  final bool isDuplicate;

  /// مقدار رمزگشایی‌شده (برای نمایش و ویرایش)
  late final String value = unescapeXmlValue(rawValue);

  bool get isEmptyValue => value.trim().isEmpty;

  bool get isTranslatable => translatable;

  /// قالب‌های جای‌گذاری موجود در متن (`%1$s`، `%d`، `{0}` و ...)
  List<String> get placeholders => extractPlaceholders(value);

  static const Set<String> _technicalNames = <String>{
    'AppName',
    'AppNameBeta',
    'AppNameDev',
    'AppNameSuffix',
    'AppHash',
    'AppVersion',
    'Telegram',
    'DebugMenu',
  };

  bool get isProbablyTechnical => _technicalNames.contains(name);

  /// حدس اینکه مقدار هنوز ترجمه نشده است (حرف فارسی/عربی ندارد ولی حرف لاتین دارد)
  bool get looksUntranslated {
    if (isProbablyTechnical || isEmptyValue) return false;
    final bool hasRtl = RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(value);
    final bool hasLatin = RegExp('[A-Za-z]').hasMatch(value);
    return !hasRtl && hasLatin;
  }

  /// پیش‌نمایش خوانا: تلگرام `\n` و `\t` را تفسیر می‌کند
  String get preview => value
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\t', '\t')
      .replaceAll(r'\"', '"');
}

/// سند XML (فایل strings) به‌همراه ویرایش‌های در انتظار ذخیره
class XmlDocument {
  XmlDocument({String source = ''}) : _fingerprint = _fp(source) {
    this.source = source;
    _parse();
  }

  final TelegramStringsParser _parser = const TelegramStringsParser();

  /// متن فعلی فایل
  String source = '';

  /// متن هنگام بارگذاری (برای تشخیص تغییرات ذخیره‌نشده)
  String originalSource = '';

  String _fingerprint;

  /// رشته‌های پارس‌شده از [source]
  List<XmlStringEntry> entries = <XmlStringEntry>[];

  /// ویرایش‌های در انتظار ذخیره: نام منبع ← مقدار جدید
  final Map<String, String> _edits = <String, String>{};

  static String _fp(String s) => s;

  void _parse() {
    entries = _parser.parse(source);
    _fingerprint = _fp(source);
  }

  /// بارگذاری متن جدید
  void load(String text) {
    source = text;
    originalSource = text;
    _edits.clear();
    _parse();
  }

  /// تغییر متن خام ویرایشگر (بدون پاک‌کردن ویرایش‌های رشته‌ای)
  void updateSource(String text) {
    source = text;
    _parse();
  }

  /// تعداد تغییرات ذخیره‌نشده
  int get pendingEditCount => _edits.length;

  bool get hasPendingEdits => _edits.isNotEmpty;

  bool get isDirty => _edits.isNotEmpty || source != originalSource;

  /// مقدار فعلی یک رشته (با احتساب ویرایش در انتظار)
  String valueOf(XmlStringEntry entry) => _edits[entry.name] ?? entry.value;

  bool isEntryEdited(XmlStringEntry entry) => _edits.containsKey(entry.name);

  /// ثبت مقدار جدید برای یک منبع
  void setValue(XmlStringEntry entry, String newValue) {
    if (newValue == entry.value) {
      _edits.remove(entry.name);
    } else {
      _edits[entry.name] = newValue;
    }
  }

  /// برگشت یک منبع به مقدار اصلی فایل
  void revertEntry(XmlStringEntry entry) => _edits.remove(entry.name);

  /// برگشت همهٔ ویرایش‌های رشته‌ای
  void revertAllEdits() => _edits.clear();

  /// متن نهایی با اعمال ویرایش‌ها (بدون تغییر [source])
  String render() {
    if (_edits.isEmpty) return source;
    final XmlDocument fresh = XmlDocument(source: source);
    final List<XmlStringEntry> targets =
        fresh.entries.where((XmlStringEntry e) => _edits.containsKey(e.name)).toList()
          ..sort((XmlStringEntry a, XmlStringEntry b) => b.outerStart.compareTo(a.outerStart));

    String out = source;
    for (final XmlStringEntry e in targets) {
      final String escaped = escapeXmlValue(_edits[e.name]!);
      if (e.selfClosing) {
        // <string name="X"/>  →  <string name="X">مقدار</string>
        out = out.replaceRange(e.outerStart, e.outerEnd, '<string ${e.rawAttributes}>$escaped</string>');
      } else {
        out = out.replaceRange(e.valueStart, e.valueEnd, escaped);
      }
    }
    return out;
  }

  /// تغییرات را تثبیت می‌کند (بعد از ذخیره روی دیسک یا کلیک روی «اعمال»)
  String commit() {
    source = render();
    originalSource = source;
    _edits.clear();
    _parse();
    return source;
  }

  /// آیا متن از آخرین پارس تغییر کرده است؟ (تشخیص دستکاری دستی)
  bool get sourceChangedSinceParse => source != _fingerprint;

  int get length => entries.length;

  int get changedCount => _edits.length;

  int get untranslatedCount => entries.where((XmlStringEntry e) => e.looksUntranslated).length;

  List<XmlStringEntry> get duplicates => entries.where((XmlStringEntry e) => e.isDuplicate).toList();
}

/// پارسر فایل strings.xml
class TelegramStringsParser {
  const TelegramStringsParser();

  static final RegExp _stringTag = RegExp(
    r'<string\b([^<>]*?)(?:\/>|>([\s\S]*?)<\/string\s*>)',
    multiLine: true,
  );

  static final RegExp _doubleQuotedName = RegExp(r'name\s*=\s*"([^"]*)"');
  static final RegExp _singleQuotedName = RegExp(r"name\s*=\s*'([^']*)'");
  static final RegExp _translatable = RegExp('''translatable\\s*=\\s*["']([^"']*)["']''');

  List<XmlStringEntry> parse(String source) {
    final String masked = _maskComments(source);

    // فهرست مکان خط‌های جدید یک‌بار ساخته می‌شود تا شمارهٔ خط هر رشته با
    // جست‌وجوی دودویی و در زمان کوتاه به‌دست بیاید (فایل‌های تلگرام ده‌ها هزار
    // خط دارند و روش ساده O(n²) می‌شد).
    final List<int> newlines = <int>[];
    for (int i = 0; i < source.length; i++) {
      if (source.codeUnitAt(i) == 0x0A) newlines.add(i);
    }

    final List<RegExpMatch> matches = _stringTag.allMatches(masked).toList(growable: false);

    // پاس اول: استخراج نام‌ها و شمردن آن‌ها. هر رشته‌ای که نامش بیش از یک بار
    // در فایل آمده باشد «تکراری» است؛ یعنی همهٔ ردیف‌های هم‌نام علامت می‌خورند
    // (نه فقط ردیف‌های بعدی) تا کاربر در فهرست، همهٔ آن‌ها را ببیند.
    final Map<String, int> counters = <String, int>{};
    final List<String?> names = <String?>[];
    for (final RegExpMatch m in matches) {
      final String attrs = (m.group(1) ?? '').trim();
      final String? name = _nameOf(attrs);
      names.add(name);
      if (name != null) counters[name] = (counters[name] ?? 0) + 1;
    }

    // پاس دوم: ساخت ردیف‌ها با آفست‌های دقیق در متن اصلی
    final List<XmlStringEntry> entries = <XmlStringEntry>[];
    for (int i = 0; i < matches.length; i++) {
      final String? name = names[i];
      if (name == null) continue;
      final RegExpMatch m = matches[i];
      final String attrs = (m.group(1) ?? '').trim();
      final String? inner = m.group(2);

      final RegExpMatch? t = _translatable.firstMatch(attrs);
      final bool translatable = t == null || t.group(1)!.toLowerCase() != 'false';

      final bool selfClosing = inner == null;
      final int valueStart = selfClosing ? m.end : (m.end(2) - inner.length);
      final int valueEnd = selfClosing ? m.end : m.end(2);

      // مقدار از متن اصلی (بدون ماسک) خوانده می‌شود
      final String rawValue = selfClosing
          ? ''
          : source.substring(valueStart.clamp(0, source.length), valueEnd.clamp(0, source.length));

      entries.add(
        XmlStringEntry(
          name: name,
          rawValue: rawValue,
          translatable: translatable,
          line: _lineOf(newlines, m.start),
          outerStart: m.start,
          outerEnd: m.end,
          valueStart: valueStart,
          valueEnd: valueEnd,
          selfClosing: selfClosing,
          rawAttributes: attrs,
          isDuplicate: (counters[name] ?? 1) > 1,
        ),
      );
    }
    return entries;
  }

  /// نام منبع از رشتهٔ ویژگی‌ها؛ اگر نام معتبر نبود `null`
  static String? _nameOf(String attrs) {
    final RegExpMatch? nameMatch =
        _doubleQuotedName.firstMatch(attrs) ?? _singleQuotedName.firstMatch(attrs);
    if (nameMatch == null) return null;
    final String name = nameMatch.group(1)!.trim();
    return name.isEmpty ? null : name;
  }

  /// جایگزینی کامنت‌های XML با فاصله (طول متن حفظ می‌شود)
  static String _maskComments(String source) {
    if (!source.contains('<!--')) return source;
    final List<int> units = source.codeUnits.toList();
    for (final RegExpMatch m in RegExp(r'<!--[\s\S]*?-->').allMatches(source)) {
      for (int i = m.start; i < m.end && i < units.length; i++) {
        if (units[i] != 0x0A) units[i] = 0x20;
      }
    }
    return String.fromCharCodes(units);
  }

  /// شمارهٔ خط (از ۱) برای یک آفست، با جست‌وجوی دودویی روی فهرست خط‌های جدید
  static int _lineOf(List<int> newlines, int offset) {
    int low = 0;
    int high = newlines.length;
    while (low < high) {
      final int mid = (low + high) >> 1;
      if (newlines[mid] < offset) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low + 1;
  }
}

/// استخراج قالب‌های جای‌گذاری: `%1$s`، `%s`، `%d`، `{0}`، `{name}`
List<String> extractPlaceholders(String text) {
  final Set<String> found = <String>{};
  for (final RegExpMatch m
      in RegExp(r'%\d+\$[sd]|%[sd]|\{\d+\}|\{[A-Za-z_][A-Za-z0-9_]*\}').allMatches(text)) {
    found.add(m.group(0)!);
  }
  return found.toList()..sort();
}

/// متن XML → متن قابل نمایش
///
/// یک‌بار و در یک پاس انجام می‌شود؛ بنابراین `&amp;lt;` درست به `&lt;` تبدیل
/// می‌شود و دوباره رمزگشایی نمی‌شود.
String unescapeXmlValue(String raw) {
  final RegExp entity = RegExp(r'&(amp|lt|gt|quot|apos|nbsp|rlm|lrm|#\d+|#x[0-9A-Fa-f]+);');
  return raw.replaceAllMapped(entity, (RegExpMatch m) {
    final String token = m.group(1)!;
    switch (token) {
      case 'amp':
        return '&';
      case 'lt':
        return '<';
      case 'gt':
        return '>';
      case 'quot':
        return '"';
      case 'apos':
        return "'";
      case 'nbsp':
        return '\u00A0';
      case 'rlm':
        return '\u200F';
      case 'lrm':
        return '\u200E';
    }
    if (token.startsWith('#x') || token.startsWith('#X')) {
      final int? code = int.tryParse(token.substring(2), radix: 16);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    }
    if (token.startsWith('#')) {
      final int? code = int.tryParse(token.substring(1));
      return code == null ? m.group(0)! : String.fromCharCode(code);
    }
    return m.group(0)!;
  });
}

/// متن ویرایش‌شده → مقدار معتبر برای داخل تگ XML
///
/// فقط کاراکترهای لازم escape می‌شوند تا خروجی، شبیه فایل اصلی تلگرام بماند.
String escapeXmlValue(String value) {
  final StringBuffer sb = StringBuffer();
  for (final int rune in value.runes) {
    switch (rune) {
      case 0x26: // &
        sb.write('&amp;');
        break;
      case 0x3C: // <
        sb.write('&lt;');
        break;
      case 0x3E: // >
        sb.write('&gt;');
        break;
      case 0x00A0: // فضای بی‌شکست
        sb.write('&nbsp;');
        break;
      case 0x200F: // RLM
        sb.write('&rlm;');
        break;
      case 0x200E: // LRM
        sb.write('&lrm;');
        break;
      default:
        sb.writeCharCode(rune);
    }
  }
  return sb.toString();
}
