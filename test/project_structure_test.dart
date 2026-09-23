// تست‌های ساختار پروژه: فایل‌های لازم برای ساخت APK و EXE وجود دارند؟

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('فایل pubspec.yaml و دارایی‌ها (assets) درست اعلام شده‌اند', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('name: tel'));
    expect(pubspec, contains('uses-material-design: true'));
    expect(pubspec, contains('assets/samples/'));
    expect(pubspec, contains('assets/fonts/Vazirmatn-Regular.ttf'));
    // هیچ وابستگی بیرونی (pub.dev) نباید وجود داشته باشد
    expect(
      RegExp(r'^\s{2}[a-z_]+:\s*\^', multiLine: true).hasMatch(pubspec),
      isFalse,
      reason: 'برنامه نباید وابستگی نسخه‌دار بیرونی داشته باشد',
    );
  });

  test('فایل‌های فونت و نمونه‌ها موجود و غیرخالی هستند', () {
    const List<String> files = <String>[
      'assets/fonts/Vazirmatn-Regular.ttf',
      'assets/fonts/Vazirmatn-Medium.ttf',
      'assets/fonts/Vazirmatn-Bold.ttf',
      'assets/samples/tg_inline_strings_sample.xml',
      'assets/samples/tg_inline_strings_en_sample.xml',
      'assets/icon/icon.png',
      'assets/icon/icon-512.png',
      'windows/runner/resources/app_icon.ico',
    ];
    for (final String path in files) {
      final File file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path پیدا نشد');
      expect(file.lengthSync(), greaterThan(100), reason: '$path خالی است');
    }
  });

  test('فایل‌های ساخت اندروید کامل هستند', () {
    const List<String> files = <String>[
      'android/settings.gradle.kts',
      'android/build.gradle.kts',
      'android/gradle.properties',
      'android/gradlew',
      'android/gradle/wrapper/gradle-wrapper.jar',
      'android/gradle/wrapper/gradle-wrapper.properties',
      'android/app/build.gradle.kts',
      'android/app/src/main/AndroidManifest.xml',
      'android/app/src/main/kotlin/com/dnschanger/tel/MainActivity.kt',
      'android/app/src/main/res/values/styles.xml',
      'android/app/src/main/res/values-night/styles.xml',
      'android/app/src/main/res/values/strings.xml',
      'android/app/src/main/res/values/ic_launcher_background.xml',
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      'android/app/src/main/res/drawable/launch_background.xml',
      'android/app/src/main/res/drawable-v21/launch_background.xml',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png',
      'android/app/src/main/res/drawable-xxxhdpi/launch_icon.png',
    ];
    for (final String path in files) {
      expect(File(path).existsSync(), isTrue, reason: '$path پیدا نشد');
    }
  });

  test('نسخهٔ اندروید از ۷.۰ به بالا و نسخهٔ ویندوز ۸.۱ به بالا هدف‌گذاری شده است', () {
    final String gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('minSdk = 24'), reason: 'minSdk 24 = اندروید ۷.۰');
    expect(gradle, contains('versionName = flutter.versionName'));
    expect(gradle, contains('versionCode = flutter.versionCode'));

    final String manifest = File('windows/runner/runner.exe.manifest').readAsStringSync();
    expect(manifest, contains('{1f676c76-80e1-4239-95bb-83d0f6d0da78}'), reason: 'Windows 8.1');
    expect(manifest, contains('{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}'), reason: 'Windows 10/11');
    expect(manifest, contains('dpiAware'), reason: 'وضوح تصویر روی ویندوز ۸.۱');
  });

  test('فایل‌های ساخت ویندوز کامل هستند', () {
    const List<String> files = <String>[
      'windows/CMakeLists.txt',
      'windows/flutter/CMakeLists.txt',
      'windows/flutter/generated_plugins.cmake',
      'windows/flutter/generated_plugin_registrant.cc',
      'windows/flutter/generated_plugin_registrant.h',
      'windows/runner/CMakeLists.txt',
      'windows/runner/main.cpp',
      'windows/runner/Runner.rc',
      'windows/runner/runner.exe.manifest',
      'windows/runner/utils.cpp',
      'windows/runner/win32_window.cpp',
      'windows/runner/flutter_window.cpp',
    ];
    for (final String path in files) {
      expect(File(path).existsSync(), isTrue, reason: '$path پیدا نشد');
    }
    // هیچ جای‌نگهدار قالب (mustache) نباید باقی مانده باشد
    for (final String path in files) {
      if (!path.endsWith('.txt') && !path.endsWith('.cpp') && !path.endsWith('.rc')) continue;
      expect(File(path).readAsStringSync(), isNot(contains('{{')),
          reason: 'جای‌نگهدار قالب در $path باقی مانده است');
    }
  });

  test('ورک‌فلوی انتشار APK و EXE را می‌سازد', () {
    final File workflow = File('.github/workflows/release.yml');
    expect(workflow.existsSync(), isTrue, reason: 'فایل ورک‌فلو پیدا نشد');
    final String yml = workflow.readAsStringSync();
    expect(yml, contains('workflow_dispatch'));
    expect(yml, contains('flutter build apk'));
    expect(yml, contains('flutter build windows'));
    expect(yml, contains('softprops/action-gh-release'));
    expect(yml, contains("FLUTTER_VERSION_WINDOWS: '3.19.6'"),
        reason: 'نسخهٔ ویندوز باید ۳.۱۹.۶ باشد (آخرین نسخهٔ پشتیبان ویندوز ۸.۱)');
    expect(yml, contains('flutter-version: \${{ env.FLUTTER_VERSION_WINDOWS }}'));
    expect(yml, contains('flutter-version: \${{ env.FLUTTER_VERSION_ANDROID }}'));
  });
}
