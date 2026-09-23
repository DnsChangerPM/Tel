// Tel — «ویرایشگر متن تلگرام»
//
// این فایل تنها کد بومی (native) برنامه است و بدون هیچ پلاگین بیرونی،
// کار «باز کردن فایل» و «ذخیرهٔ فایل» را روی اندروید انجام می‌دهد.
//
// از Storage Access Framework استفاده می‌شود:
//   * ACTION_OPEN_DOCUMENT   → انتخاب فایل از هرجای گوشی (بدون مجوز حافظه)
//   * ACTION_CREATE_DOCUMENT → ذخیرهٔ خروجی در مکانی که کاربر انتخاب می‌کند
//
// همین روش روی اندروید ۷.۰ (API 24) تا آخرین نسخهٔ اندروید کار می‌کند، چون
// برای دسترسی به فایل به هیچ مجوزی نیاز ندارد.

package com.dnschanger.tel

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "tel/file_io"
        private const val REQUEST_OPEN = 4021
        private const val REQUEST_SAVE = 4022

        private const val MIME_XML = "text/xml"
        private const val MIME_JSON = "application/json"
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingContents: String? = null
    private var pendingFileName: String = "strings.xml"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "pickStringsFile" -> openPicker(result)
                    "saveStringsFile" -> saveDocument(call, result)
                    "platformVersion" -> result.success("Android " + android.os.Build.VERSION.RELEASE)
                    else -> result.notImplemented()
                }
            }
    }

    // -----------------------------------------------------------------------
    // انتخاب فایل برای خواندن
    // -----------------------------------------------------------------------
    private fun openPicker(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "یک پنجرهٔ انتخاب فایل دیگر باز است.", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(MIME_XML, "application/xml", "text/plain", MIME_JSON)
            )
        }
        try {
            startActivityForResult(intent, REQUEST_OPEN)
        } catch (error: Exception) {
            pendingResult = null
            result.error("open_failed", error.message ?: "باز کردن پنجرهٔ فایل ناموفق بود", null)
        }
    }

    // -----------------------------------------------------------------------
    // ذخیرهٔ فایل
    // -----------------------------------------------------------------------
    private fun saveDocument(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "یک پنجرهٔ انتخاب فایل دیگر باز است.", null)
            return
        }
        val contents = call.argument<String>("text") ?: ""
        val name = call.argument<String>("name") ?: "tg_inline_strings.xml"

        pendingResult = result
        pendingContents = contents
        pendingFileName = name

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = MIME_XML
            putExtra(Intent.EXTRA_TITLE, name)
        }
        try {
            startActivityForResult(intent, REQUEST_SAVE)
        } catch (error: Exception) {
            pendingResult = null
            pendingContents = null
            result.error("save_failed", error.message ?: "باز کردن پنجرهٔ ذخیره ناموفق بود", null)
        }
    }

    // -----------------------------------------------------------------------
    // نتیجهٔ پنجره‌ها
    // -----------------------------------------------------------------------
    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)

        val result = pendingResult ?: return
        val uri: Uri? = data?.data

        if (resultCode != Activity.RESULT_OK || uri == null) {
            // کاربر لغو کرد
            clearPending()
            result.success(null)
            return
        }

        when (requestCode) {
            REQUEST_OPEN -> {
                try {
                    val text = readText(uri)
                    val displayName = queryDisplayName(uri)
                    clearPending()
                    result.success(
                        mapOf(
                            "name" to displayName,
                            "text" to text,
                            "displayPath" to displayName
                        )
                    )
                } catch (error: Exception) {
                    clearPending()
                    result.error("read_failed", error.message ?: "خواندن فایل ناموفق بود", null)
                }
            }

            REQUEST_SAVE -> {
                try {
                    val contents = pendingContents ?: ""
                    writeText(uri, contents)
                    val displayName = queryDisplayName(uri) ?: pendingFileName
                    clearPending()
                    result.success(
                        mapOf(
                            "name" to displayName,
                            "displayPath" to displayName
                        )
                    )
                } catch (error: Exception) {
                    clearPending()
                    result.error("write_failed", error.message ?: "نوشتن فایل ناموفق بود", null)
                }
            }

            else -> {
                clearPending()
                result.success(null)
            }
        }
    }

    private fun clearPending() {
        pendingResult = null
        pendingContents = null
    }

    // -----------------------------------------------------------------------
    // خواندن و نوشتن محتوا (UTF-8)
    // -----------------------------------------------------------------------
    private fun readText(uri: Uri): String {
        val resolver: ContentResolver = contentResolver
        val stream = resolver.openInputStream(uri)
            ?: throw IllegalStateException("امکان باز کردن فایل وجود ندارد")
        stream.use { input ->
            val reader = BufferedReader(InputStreamReader(input, Charsets.UTF_8))
            val builder = StringBuilder()
            val buffer = CharArray(8192)
            while (true) {
                val count = reader.read(buffer)
                if (count <= 0) break
                builder.append(buffer, 0, count)
            }
            // حذف BOM در ابتدای فایل (اگر وجود داشته باشد)
            return if (builder.isNotEmpty() && builder[0] == '\uFEFF') {
                builder.substring(1)
            } else {
                builder.toString()
            }
        }
    }

    private fun writeText(uri: Uri, contents: String) {
        val resolver: ContentResolver = contentResolver
        val stream = resolver.openOutputStream(uri, "wt")
            ?: throw IllegalStateException("امکان نوشتن در مقصد وجود ندارد")
        stream.use { output ->
            val writer = OutputStreamWriter(output, Charsets.UTF_8)
            writer.write(contents)
            writer.flush()
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0 && cursor.moveToFirst()) cursor.getString(index) else null
            }
        } catch (error: Exception) {
            uri.lastPathSegment
        }
    }
}
