package com.prronclick.prronclick

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Android drops incoming multicast without this lock, and Link discovers peers via multicast.
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        multicastLock = wifi.createMulticastLock("prronclick-link").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    override fun onDestroy() {
        multicastLock?.release()
        super.onDestroy()
    }
}
