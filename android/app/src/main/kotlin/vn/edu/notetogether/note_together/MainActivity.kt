package vn.edu.notetogether.note_together

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var saveResult: MethodChannel.Result? = null
    private var saveBytes: ByteArray? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "notetogether/documents").setMethodCallHandler { call, result ->
            if (call.method != "save") { result.notImplemented(); return@setMethodCallHandler }
            if (saveResult != null) { result.error("busy", "A save dialog is already open", null); return@setMethodCallHandler }
            val bytes = call.argument<ByteArray>("bytes")
            val name = call.argument<String>("name")
            if (bytes == null || bytes.size > 20 * 1024 * 1024 || name == null) {
                result.error("invalid", "Invalid file", null); return@setMethodCallHandler
            }
            saveResult = result; saveBytes = bytes
            try {
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = call.argument<String>("mime") ?: "application/octet-stream"
                    putExtra(Intent.EXTRA_TITLE, name)
                }
                startActivityForResult(intent, 5401)
            } catch (e: Exception) {
                saveResult = null; saveBytes = null
                result.error("picker", "Cannot open save dialog", null)
            }
        }
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != 5401) { super.onActivityResult(requestCode, resultCode, data); return }
        val result = saveResult; val bytes = saveBytes; val uri = data?.data
        saveResult = null; saveBytes = null
        if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) { result?.success(false); return }
        Thread {
            try {
                contentResolver.openOutputStream(uri, "w").use { stream -> requireNotNull(stream); stream.write(bytes) }
                runOnUiThread { result?.success(true) }
            } catch (e: Exception) { runOnUiThread { result?.error("write", "Cannot save selected document", null) } }
        }.start()
    }
}
