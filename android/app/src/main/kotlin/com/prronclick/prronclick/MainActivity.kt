package com.prronclick.prronclick

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Android drops incoming multicast without this lock, and Link discovers peers via multicast.
    private var multicastLock: WifiManager.MulticastLock? = null
    private var micResult: MethodChannel.Result? = null
    private var askedNotifications = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        multicastLock = wifi.createMulticastLock("prronclick-link").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    // "request": asks for the microphone (latency calibration); replies granted or not.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "prronclick/mic")
            .setMethodCallHandler { call, result ->
                if (call.method != "request") {
                    result.notImplemented()
                } else if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                    PackageManager.PERMISSION_GRANTED
                ) {
                    result.success(true)
                } else {
                    micResult?.success(false)
                    micResult = result
                    requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), MIC_REQUEST)
                }
            }
        // "supported": whether the phone can vibrate. "mode" (int): see Haptics.mode.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "prronclick/haptics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "supported" -> result.success(Haptics.supported(this))
                    "mode" -> {
                        Haptics.mode = call.arguments as Int
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // "keepAlive" (bool): runs PlaybackService while the click plays or is shared.
        // Calls "stop" on Dart when the notification's Parar is pressed.
        val background = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "prronclick/background")
        PlaybackService.onStop = { background.invokeMethod("stop", null) }
        background
            .setMethodCallHandler { call, result ->
                if (call.method != "keepAlive") return@setMethodCallHandler result.notImplemented()
                try {
                    val on = call.arguments as Boolean
                    PlaybackService.set(this, on)
                    if (on && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                        PackageManager.PERMISSION_GRANTED && !askedNotifications
                    ) {
                        askedNotifications = true // once per launch, not on every play
                        requestPermissions(
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFY_REQUEST
                        )
                    }
                    result.success(true)
                } catch (e: IllegalStateException) {
                    // Android 12+ refuses to start it from the background.
                    result.success(false)
                }
            }
    }

    override fun onDestroy() {
        PlaybackService.onStop = null
        PlaybackService.set(this, false)
        multicastLock?.release()
        super.onDestroy() // Dart is gone after this
        // Swiped away from the recent apps: the process can live on, and the click with
        // it, with no screen left to stop it. It goes with the app (Link peers play on).
        if (isFinishing) {
            Haptics.stop() // it reads the engine
            System.loadLibrary("prronclick_engine") // the one Dart opened
            shutdownEngine()
        }
    }

    private external fun shutdownEngine()

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFY_REQUEST) {
            // Re-post the notification if the service is still running.
            if (PlaybackService.running) PlaybackService.set(this, true)
            return
        }
        if (requestCode != MIC_REQUEST) return
        micResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        micResult = null
    }

    private companion object {
        const val MIC_REQUEST = 1
        const val NOTIFY_REQUEST = 2
    }
}
