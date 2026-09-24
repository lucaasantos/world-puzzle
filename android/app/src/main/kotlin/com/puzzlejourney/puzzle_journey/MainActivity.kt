package com.puzzlejourney.puzzle_journey

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.PlayGamesSdk

class MainActivity : FlutterActivity() {
    private val wallpaperChannel = "mosaico/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "puzzle_world/play_games")
            .setMethodCallHandler { call, result ->
                if (call.method != "serverAuthCode") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val clientId = call.argument<String>("clientId")
                if (clientId.isNullOrBlank() || getString(R.string.game_services_project_id) == "0") {
                    result.error("NOT_CONFIGURED", "Play Games não configurado.", null)
                    return@setMethodCallHandler
                }
                PlayGamesSdk.initialize(applicationContext)
                val client = PlayGames.getGamesSignInClient(this)
                client.signIn().addOnSuccessListener { authentication ->
                    if (!authentication.isAuthenticated) {
                        result.error("CANCELLED", "Login cancelado.", null)
                    } else {
                        client.requestServerSideAccess(clientId, false)
                            .addOnSuccessListener { code -> result.success(code) }
                            .addOnFailureListener { error -> result.error("AUTH_FAILED", error.message, null) }
                    }
                }.addOnFailureListener { error -> result.error("AUTH_FAILED", error.message, null) }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wallpaperChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveWallpaper") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val name = call.argument<String>("name")
                if (bytes == null || name == null) {
                    result.error("INVALID_ARGUMENT", "Wallpaper bytes and name are required.", null)
                    return@setMethodCallHandler
                }
                Thread {
                    try {
                        saveWallpaper(bytes, name)
                        runOnUiThread { result.success(true) }
                    } catch (error: Exception) {
                        runOnUiThread {
                            result.error("SAVE_FAILED", error.message ?: "Unable to save wallpaper.", null)
                        }
                    }
                }.start()
            }
    }

    private fun saveWallpaper(bytes: ByteArray, name: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, "$name.webp")
                put(MediaStore.Images.Media.MIME_TYPE, "image/webp")
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/Puzzle World")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: error("MediaStore did not create the image.")
            try {
                resolver.openOutputStream(uri)?.use { it.write(bytes) }
                    ?: error("Unable to open the image output stream.")
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            } catch (error: Exception) {
                resolver.delete(uri, null, null)
                throw error
            }
            return
        }

        val pictures = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
        val folder = File(pictures, "Puzzle World").apply { mkdirs() }
        val file = File(folder, "$name.webp")
        file.writeBytes(bytes)
        MediaScannerConnection.scanFile(this, arrayOf(file.absolutePath), arrayOf("image/webp"), null)
    }
}
