# راهنمای ورک‌فلوی ساخت و انتشار (APK + EXE)

فایل ورک‌فلو: [`.github/workflows/release.yml`](../.github/workflows/release.yml)

---

## ۱) ورودی‌های ورک‌فلو

وقتی از تب **Actions → Build & Release (APK + EXE) → Run workflow** اجرا می‌کنید،
این مقادیر پرسیده می‌شوند:

| ورودی | اجباری | پیش‌فرض | توضیح |
| --- | --- | --- | --- |
| `version` | ✅ | `1.0.0` | نسخهٔ برنامه. قالب: `1.2.0` یا `1.2.0+7` |
| `build_number` | ❌ | خالی | اگر خالی باشد = شمارهٔ اجرای ورک‌فلو (`github.run_number`) |
| `release_title` | ❌ | خالی | عنوان انتشار (خالی = `Tel <نسخه>`) |
| `release_notes` | ❌ | خالی | توضیحات انتشار |
| `create_release` | ✅ | `true` | ساخت انتشار در بخش Releases |
| `prerelease` | ✅ | `false` | انتشار به‌عنوان پیش‌نسخه |

همچنین اگر تگ نسخه push کنید (`git push origin v1.2.0`) ورک‌فلو خودکار با همان
نسخه اجرا می‌شود و فایل‌ها را در همان تگ منتشر می‌کند.

---

## ۲) مراحل (Jobs)

| Job | رانر | کار |
| --- | --- | --- |
| `prepare` | ubuntu | خواندن و اعتبارسنجی نسخه، ساخت تگ و عنوان |
| `android` | ubuntu | Flutter 3.47.5 → `flutter build apk --release` → `Tel-<نسخه>-android.apk` |
| `windows` | windows-latest | Flutter 3.19.6 → `flutter build windows --release` → exe + zip (+ setup با Inno Setup) |
| `release` | ubuntu | دانلود خروجی‌ها و ساخت انتشار گیت‌هاب با `softprops/action-gh-release` |

در هر دو جاب ساخت (اندروید و ویندوز)، پیش از ساخت این‌ها اجرا می‌شود:

```bash
python3 tools/set_version.py "<نسخه>"     # نوشتن نسخه در pubspec.yaml
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

و نسخه به داخل برنامه با `--dart-define`ها تزریق می‌شود:

```
TEL_APP_VERSION, TEL_BUILD_NUMBER, TEL_BUILD_TIME, TEL_BUILD_CHANNEL, TEL_REPO
```

پس همان نسخه‌ای که در ورودی می‌دهید، در این جاها دیده می‌شود:
نام فایل‌های انتشار، `versionName` و `versionCode` اندروید، خواص فایل EXE،
عنوان پنجرهٔ «درباره» و نام پیشنهادی فایل هنگام ذخیره در برنامه.

---

## ۳) چرا دو نسخهٔ Flutter؟

| پلتفرم | نسخهٔ Flutter | دلیل |
| --- | --- | --- |
| اندروید | `3.47.5` | جدیدترین ابزارها؛ `minSdk 24` = اندروید ۷.۰ و `targetSdk 36` = آخرین اندروید |
| ویندوز | `3.19.6` | آخرین نسخه‌ای که خروجی آن روی ویندوز ۸.۱ اجرا می‌شود |

برای اینکه یک کد برای هر دو نسخه کار کند:

* در `pubspec.yaml` محدودهٔ `sdk: ">=3.3.0 <4.0.0"` و `flutter: ">=3.19.0"` است.
* در کد از API های جدیدتر از Flutter 3.19 استفاده نشده است
  (مثلاً `Color.withValues` یا `ColorScheme.surfaceContainerHighest`).
* در `analysis_options.yaml` هیچ لینت سختگیرانه‌ای که با Flutter 3.19 ناسازگار باشد
  فعال نشده و پروژه هیچ وابستگی بیرونی (pub.dev) ندارد.

اگر فقط نسخهٔ جدید را هدف بگیرید می‌توانید نسخهٔ ویندوز را در
`env.FLUTTER_VERSION_WINDOWS` به `3.47.5` تغییر دهید — ولی آن‌وقت خروجی روی
ویندوز ۸.۱ اجرا **نمی‌شود**.

---

## ۴) خروجی‌ها (Artifacts و Releases)

پس از هر اجرا، فایل‌ها هم به‌صورت Artifact در همان اجرا و هم (اگر
`create_release` روشن باشد) در **Releases** قرار می‌گیرند:

```
Tel-<نسخه>-android.apk                ← APK یونیورسال (نصب روی اندروید ۷ تا آخرین نسخه)
Tel-<نسخه>-windows-x64.exe            ← exe پرتابل (نیاز به dll و data کنارش)
Tel-<نسخه>-windows-x64.zip            ← بستهٔ کامل ویندوز (توصیه‌شده)
Tel-<نسخه>-setup-x64.exe              ← فایل نصب ویندوز (اگر Inno Setup روی رانر باشد)
```

---

## ۵) امضای APK با کلید خودتان در CI (اختیاری)

ورک‌فلو از قبل این کار را انجام می‌دهد؛ فقط Secretها را تعریف کنید:

1. روی کامپیوتر خود کلید بسازید:

   ```bash
   keytool -genkey -v -keystore tel-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tel
   base64 -w0 tel-release.jks > keystore.b64
   ```

   (در ویندوز: `certutil -encodehex -f tel-release.jks keystore.b64 0x40000001` یا از
   PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("tel-release.jks")) | Set-Content keystore.b64`)

2. در گیت‌هاب → Settings → Secrets and variables → Actions این ۴ Secret را بسازید:

   | Secret | مقدار |
   | --- | --- |
   | `KEYSTORE_BASE64` | محتوای فایل `keystore.b64` (یک خط) |
   | `KEYSTORE_PASSWORD` | رمز کیستور |
   | `KEY_ALIAS` | `tel` |
   | `KEY_PASSWORD` | رمز کلید |

3. همین. در جاب `android`، مرحلهٔ «آماده‌سازی کلید امضای APK» فایل
   `android/tel-release.jks` و `android/key.properties` را می‌سازد و
   `android/app/build.gradle.kts` خودش آن‌ها را برمی‌دارد. اگر این Secretها
   تعریف نشده باشند، APK با کلید دیباگ امضا می‌شود (ساخت شکست نمی‌خورد) و در
   لاگ پیام «Secret مربوط به کیستور تعریف نشده» را می‌بینید.

> اگر کلید خودتان را عوض کنید، کاربرانی که نسخهٔ قبلی را نصب کرده‌اند باید ابتدا
> برنامه را حذف کنند (اندروید اجازهٔ به‌روزرسانی با امضای متفاوت نمی‌دهد).

## ۶) عیب‌یابی

| نشانه | علت/راه‌حل |
| --- | --- |
| خطای `flutter analyze` | چون `--no-fatal-infos` فعال است، فقط **خطاهای واقعی** ساخت را متوقف می‌کنند. متن خطا را بخوانید (فایل و شمارهٔ خط داده می‌شود). |
| خطای Gradle دربارهٔ AGP/Gradle | جاب اندروید باید با Flutter 3.47.x اجرا شود (AGP 9.1.0 + Gradle 9.3.1). نسخهٔ ویندوزی 3.19.6 برای پروژهٔ اندروید استفاده نمی‌شود. |
| دانلود نشدن SDK/NDK | مرحلهٔ «آماده‌سازی اجزای Android SDK» این کار را با `sdkmanager` انجام می‌دهد؛ اگر شکست بخورد AGP خودش دانلود می‌کند. |
| «فایل tel.exe ساخته نشد» در جاب ویندوز | مطمئن شوید جاب ویندوز روی `windows-latest` و با Flutter 3.19.6 اجرا می‌شود و Visual Studio 2022 (بارکاری Desktop development with C++) روی رانر موجود است. |
| Published release نشد | ورودی `create_release` باید `true` باشد و در Settings → Actions → General دسترسی `Read and write permissions` برای Workflow فعال باشد. |
| APK نصب نمی‌شود | اگر نسخه‌ای قبلاً با کلید دیگری نصب شده، ابتدا آن را حذف کنید (امضای متفاوت = نصب‌نشدن). |
