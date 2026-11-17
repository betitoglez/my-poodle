package dev.mypoodle.my_poodle

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Directorio privado excluido de Auto Backup y transferencia entre dispositivos.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "my_poodle/storage")
            .setMethodCallHandler { call, result ->
                if (call.method == "saveDirectory") {
                    try {
                        val dir = File(noBackupFilesDir, "MyPoodle")
                        if (!dir.exists() && !dir.mkdirs()) {
                            result.error("storage", "No se pudo crear el directorio", null)
                        } else {
                            result.success(dir.absolutePath)
                        }
                    } catch (e: Exception) {
                        result.error("storage", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
