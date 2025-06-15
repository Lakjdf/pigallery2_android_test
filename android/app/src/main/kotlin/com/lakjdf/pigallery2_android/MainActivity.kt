package com.lakjdf.pigallery2_android

import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hideSystemBars" -> {
                    hideSystemBars()
                    result.success(null)
                }

                "showSystemBars" -> {
                    showSystemBars()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun showSystemBars() {
        WindowCompat.getInsetsController(window, window.decorView).show(WindowInsetsCompat.Type.systemBars())
    }

    private fun hideSystemBars() {
        WindowCompat.getInsetsController(window, window.decorView).hide(WindowInsetsCompat.Type.systemBars())
    }

    companion object {
        private const val CHANNEL = "com.lakjdf.pigallery_android/statusBar"
    }
}
