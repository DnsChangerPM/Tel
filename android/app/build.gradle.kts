// Tel — «ویرایشگر متن تلگرام»
// فایل تنظیمات ماژول اپلیکیشن اندروید (بر پایهٔ قالب رسمی Flutter 3.47.5)
//
// نکات مهم:
//  * minSdk = 24  →  اندروید ۷.۰ (Nougat) و همهٔ نسخههای بالاتر؛ یعنی خواستهٔ
//    «نصب روی اندروید ۷ تا آخرین نسخهٔ اندروید» برآورده میشود.
//    (۲۴ کمترین نسخهٔ پشتیبانیشده توسط خود Flutter است؛ اگر اندروید ۵/۶ لازم
//     دارید باید از Flutter 3.19 و minSdk 21 استفاده کنید.)
//  * versionName / versionCode از روی pubspec.yaml خوانده میشود؛ پس همان نسخهای
//    که در ورکفلو گیتهاب وارد میکنید داخل APK و داخل نام فایل انتشار میآید.
//  * اگر فایل android/key.properties وجود داشته باشد، APK با کلید خودتان امضا
//    میشود؛ در غیر این صورت با کلید دیباگ امضا میشود تا ساخت همیشه موفق باشد.

import java.util.Properties

plugins {
    id("com.android.application")
    // پلاگین کاتلین (نسخه‌اش در android/settings.gradle.kts تعیین شده است)؛
    // لازم است چون android.builtInKotlin=false است و MainActivity.kt کاتلین است.
    id("kotlin-android")
    // پلاگین Flutter باید بعد از پلاگین‌های اندروید و کاتلین اعمال شود.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.dnschanger.tel"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.dnschanger.tel"
        // اندروید ۷.۰ (API 24) و بالاتر
        minSdk = 24
        // آخرین نسخهٔ SDK (۳۶ = اندروید ۱۶) — روی همهٔ نسخههای جدید نصب میشود
        targetSdk = flutter.targetSdkVersion
        // نسخهٔ اپ از pubspec.yaml خوانده میشود (workflow آن را ست میکند)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (hasReleaseKeystore) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    // پشتیبانی از `flutter run --release` روی دستگاه واقعی
                    signingConfigs.getByName("debug")
                }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        resources {
            excludes += setOf("META-INF/*.kotlin_module", "META-INF/DEPENDENCIES")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
