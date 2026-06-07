package com.banxxx.dudo

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import com.ryanheise.audioservice.AudioServiceActivity

/**
 * 必须继承 [AudioServiceActivity]（它本身继承自 FlutterFragmentActivity），
 * 否则 audio_service 插件初始化时会抛
 *   "The Activity class declared in your AndroidManifest.xml is wrong
 *    or has not provided the correct FlutterEngine."
 */
class MainActivity : AudioServiceActivity() {
    private var volumeEventSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        configureEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dudo.reader/volume_page_turn"
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    volumeEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    volumeEventSink = null
                }
            }
        )
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val sink = volumeEventSink
        if (
            sink != null &&
            event.action == KeyEvent.ACTION_DOWN &&
            event.repeatCount == 0
        ) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    sink.success("volumeUp")
                    return true
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    sink.success("volumeDown")
                    return true
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun configureEdgeToEdge() {
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.decorView.setOnApplyWindowInsetsListener { view, insets ->
                view.onApplyWindowInsets(insets)
                insets
            }
        }
    }
}
