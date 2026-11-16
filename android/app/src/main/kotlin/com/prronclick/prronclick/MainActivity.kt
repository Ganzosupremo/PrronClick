package com.prronclick.prronclick

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Android drops incoming multicast without this lock, and Link discovers peers via multicast.
    private var multicastLock: WifiManager.MulticastLock? = null
    private var micResult: MethodChannel.Result? = null

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
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != MIC_REQUEST) return
        micResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        micResult = null
    }

    override fun onDestroy() {
        multicastLock?.release()
        super.onDestroy()
    }

    private companion object {
        const val MIC_REQUEST = 1
    }
}
