package com.betitoglez.mypoodle

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Copia un PNG del álbum privado a la galería del sistema (Pictures/My Poodle).
 * Android 10+ usa MediaStore sin permisos; Android 7–9 pide
 * WRITE_EXTERNAL_STORAGE (declarado con maxSdkVersion=28). No lee la galería.
 */
class PhotoGalleryChannel(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        const val REQUEST_CODE = 0x5047 // "PG"
        private const val ALBUM = "My Poodle"
    }

    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pending: (() -> Unit)? = null
    private var pendingResult: MethodChannel.Result? = null

    init {
        MethodChannel(messenger, "my_poodle/photos").setMethodCallHandler { call, result ->
            if (call.method != "saveToGallery") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val bytes = call.argument<ByteArray>("bytes")
            val name = call.argument<String>("name")?.replace(Regex("[^A-Za-z0-9_-]"), "_")
            if (bytes == null || bytes.isEmpty() || name.isNullOrEmpty()) {
                result.error("invalid", null, null)
                return@setMethodCallHandler
            }
            val save = { write(bytes, "$name.png", result) }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q ||
                activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
            ) {
                save()
            } else if (pendingResult != null) {
                result.error("busy", null, null)
            } else {
                pending = save
                pendingResult = result
                activity.requestPermissions(
                    arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), REQUEST_CODE
                )
            }
        }
    }

    /** Llamado desde MainActivity.onRequestPermissionsResult. */
    fun onPermissionResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val save = pending
        val result = pendingResult
        pending = null
        pendingResult = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            save?.invoke()
        } else {
            result?.success("denied")
        }
        return true
    }

    private fun write(bytes: ByteArray, fileName: String, result: MethodChannel.Result) {
        io.execute {
            val outcome = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) writeMediaStore(bytes, fileName)
                else writeLegacy(bytes, fileName)
                "saved"
            } catch (e: Exception) {
                null
            }
            main.post {
                if (outcome != null) result.success(outcome)
                else result.error("failed", null, null)
            }
        }
    }

    private fun writeMediaStore(bytes: ByteArray, fileName: String) {
        val resolver = activity.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(
                MediaStore.Images.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_PICTURES}/$ALBUM"
            )
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = resolver.insert(collection, values) ?: error("insert")
        try {
            resolver.openOutputStream(uri)?.use { it.write(bytes) } ?: error("stream")
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
    }

    @Suppress("DEPRECATION")
    private fun writeLegacy(bytes: ByteArray, fileName: String) {
        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), ALBUM
        )
        if (!dir.exists() && !dir.mkdirs()) error("mkdirs")
        val file = File(dir, fileName)
        file.writeBytes(bytes)
        MediaScannerConnection.scanFile(activity, arrayOf(file.absolutePath), arrayOf("image/png"), null)
    }
}
