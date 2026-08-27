package com.example.piliplus

import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.WindowManager.LayoutParams
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var tvKeyChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (BuildConfig.IS_TV) {
            tvKeyChannel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "PiliPlus.tv",
            )
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (BuildConfig.IS_TV) {
            val key = when (event.keyCode) {
                KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_VOLUME_UP -> "arrowUp"
                KeyEvent.KEYCODE_DPAD_DOWN, KeyEvent.KEYCODE_VOLUME_DOWN -> "arrowDown"
                else -> null
            }
            if (key != null) {
                val action = when (event.action) {
                    KeyEvent.ACTION_DOWN -> "down"
                    KeyEvent.ACTION_UP -> "up"
                    else -> return true
                }
                tvKeyChannel?.invokeMethod(
                    "tvKey",
                    mapOf(
                        "key" to key,
                        "action" to action,
                        "isRepeat" to (event.repeatCount > 0),
                    ),
                )
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (AndroidHelper.isFoldable) {
            AndroidHelper.ToDart.onConfigurationChanged?.run()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    override fun onDestroy() {
        stopService(Intent(this, com.ryanheise.audioservice.AudioService::class.java))
        super.onDestroy()
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        AndroidHelper.ToDart.onUserLeaveHint?.run()
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration?) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        AndroidHelper.isPipMode = isInPictureInPictureMode
    }
}
