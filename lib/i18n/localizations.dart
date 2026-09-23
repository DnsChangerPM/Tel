// Tel — «ویرایشگر متن تلگرام»
//
// متن‌های پیش‌فرض ویجت‌های Material برای زبان فارسی.
//
// چرا لازم است؟ در Flutter، تنها زبان انگلیسی متن‌های آمادهٔ Material را دارد
// (`DefaultMaterialLocalizations`) و delegate پیش‌فرض فقط برای زبان «en»
// پشتیبانی می‌کند (`isSupported => locale.languageCode == 'en'`). اگر
// برنامه locale را روی «fa» بگذارد و هیچ delegateی برای آن نداشته باشد،
// ویجت‌هایی مثل TextField، Tooltip و PopupMenu با خطای
// «No MaterialLocalizations found» از کار می‌افتند.
//
// برای همین یک delegate سبک در خود برنامه داریم: برای فارسی متن‌های ترجمه‌شده
// و برای بقیهٔ زبان‌ها متن‌های پیش‌فرض انگلیسی. بنابراین برنامه همچنان هیچ
// وابستگی بیرونی (پکیج pub.dev) ندارد و کاملاً آفلاین ساخته می‌شود.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// متن‌های ویجت‌های Material برای زبان فارسی
///
/// بقیهٔ متن‌ها (تاریخ‌ها، نام ماه‌ها و ...) از پیش‌فرض انگلیسی به ارث می‌رسند؛
/// برنامه از آن‌ها استفاده نمی‌کند و متن‌های خودِ Tel از جدول ترجمهٔ داخلی
/// (`lib/i18n/l10n.dart`) می‌آید.
class PersianMaterialLocalizations extends DefaultMaterialLocalizations {
  const PersianMaterialLocalizations();

  @override
  String get okButtonLabel => 'تأیید';
  @override
  String get cancelButtonLabel => 'انصراف';
  @override
  String get closeButtonLabel => 'بستن';
  @override
  String get closeButtonTooltip => 'بستن';
  @override
  String get backButtonTooltip => 'بازگشت';
  @override
  String get deleteButtonTooltip => 'حذف';
  @override
  String get cutButtonLabel => 'برش';
  @override
  String get copyButtonLabel => 'کپی';
  @override
  String get pasteButtonLabel => 'چسباندن';
  @override
  String get selectAllButtonLabel => 'انتخاب همه';
  @override
  String get saveButtonLabel => 'ذخیره';
  @override
  String get searchFieldLabel => 'جست‌وجو';
  @override
  String get showMenuTooltip => 'نمایش منو';
  @override
  String get moreButtonTooltip => 'بیشتر';
  @override
  String get modalBarrierDismissLabel => 'بستن';
  @override
  String get refreshIndicatorSemanticLabel => 'به‌روزرسانی';
  @override
  String get dialogLabel => 'پنجره';
  @override
  String get alertDialogLabel => 'هشدار';
  @override
  String get drawerLabel => 'منوی کنار';
  @override
  String get openAppDrawerTooltip => 'باز کردن منو';
  @override
  String get popupMenuLabel => 'منوی بازشو';
  @override
  String get scrimLabel => 'پرده';
  @override
  String get firstPageTooltip => 'صفحهٔ اول';
  @override
  String get lastPageTooltip => 'صفحهٔ آخر';
  @override
  String get nextPageTooltip => 'صفحهٔ بعد';
  @override
  String get previousPageTooltip => 'صفحهٔ قبل';
  @override
  String get rowsPerPageTitle => 'تعداد ردیف در صفحه';
}

/// متن‌های پیش‌فرض Cupertino برای همهٔ زبان‌ها
///
/// `CupertinoLocalizations` هم فقط زبان انگلیسی را پشتیبانی می‌کند؛ نبودِ delegate
/// برای فارسی باعث هشدار (و در تست‌ها خطای) «locale is not supported by all of its
/// localization delegates» می‌شود. متن‌های Cupertino در Tel استفاده نمی‌شوند، ولی
/// باید delegate آن وجود داشته باشد تا پنجرهٔ «تحلیل»/ابزارها و تست‌ها سالم بمانند.
class AppCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const AppCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) => DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<CupertinoLocalizations> old) => false;
}

/// delegate متن‌های Material برای همهٔ زبان‌ها
///
/// برای «fa» از [PersianMaterialLocalizations] و برای بقیه از پیش‌فرض انگلیسی
/// استفاده می‌شود؛ چون `MaterialApp` پیش‌فرض فقط زبان «en» را پشتیبانی می‌کند.
class AppMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const AppMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
      locale.languageCode == 'fa'
          ? const PersianMaterialLocalizations()
          : const DefaultMaterialLocalizations(),
    );
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}
