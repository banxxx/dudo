package com.banxxx.dudo

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.KeyEvent
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

/**
 * 必须继承 [AudioServiceActivity]（它本身继承自 FlutterFragmentActivity），
 * 否则 audio_service 插件初始化时会抛
 *   "The Activity class declared in your AndroidManifest.xml is wrong
 *    or has not provided the correct FlutterEngine."
 */
class MainActivity : AudioServiceActivity() {
    private var volumeEventSink: EventChannel.EventSink? = null

    private companion object {
        const val NOTIFICATION_PERMISSION_REQUEST = 1001
    }

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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dudo.system/settings"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openTtsSettings" -> result.success(openTtsSettings())
                "requestNotificationPermission" ->
                    result.success(requestNotificationPermission())
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Android 13+ 不申请 POST_NOTIFICATIONS 就不会显示朗读通知，锁屏上的
     * 播放控制也随之消失；返回 true 表示已经有权限，false 表示刚弹出授权框。
     */
    private fun requestNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        val granted = checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        if (granted) return true
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST
        )
        return false
    }

    /**
     * 打开系统的语音合成设置页，让用户安装/管理语音数据。
     * 不同 ROM 的页面不同，逐个尝试，全部失败时返回 false。
     */
    private fun openTtsSettings(): Boolean {
        val candidates = listOf(
            Intent("com.android.settings.TTS_SETTINGS"),
            Intent(Settings.ACTION_VOICE_INPUT_SETTINGS),
        )
        for (intent in candidates) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
            } catch (_: SecurityException) {
            }
        }
        return false
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
