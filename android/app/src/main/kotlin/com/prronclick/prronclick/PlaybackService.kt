package com.prronclick.prronclick

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

// Keeps the click going with the screen off: a foreground service stops Android from
// freezing the app, the wake lock keeps the CPU (Dart timers, Link) running and the
// Wi-Fi lock keeps the radio from dozing so Link and the bar broadcast stay on time.
class PlaybackService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        running = true
        val notification = notification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(ID, notification)
        }
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "prronclick:playback")
            .apply { setReferenceCounted(false); acquire() }
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        @Suppress("DEPRECATION")
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            WifiManager.WIFI_MODE_FULL_LOW_LATENCY
        } else {
            WifiManager.WIFI_MODE_FULL_HIGH_PERF
        }
        wifiLock = wifi.createWifiLock(mode, "prronclick:link")
            .apply { setReferenceCounted(false); acquire() }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == STOP) {
            onStop?.invoke()
        } else {
            // Shows it again in case notifications were allowed after it was posted.
            getSystemService(NotificationManager::class.java).notify(ID, notification())
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        running = false
        wakeLock?.release()
        wifiLock?.release()
        super.onDestroy()
    }

    private fun notification(): Notification {
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL, getString(R.string.playback_channel), NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
            Notification.Builder(this, CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val stop = PendingIntent.getService(
            this, 1, Intent(this, PlaybackService::class.java).setAction(STOP),
            PendingIntent.FLAG_IMMUTABLE
        )
        val stopAction = Notification.Action.Builder(
            Icon.createWithResource(this, android.R.drawable.ic_media_pause), getString(R.string.playback_stop), stop
        ).build()
        return builder
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("PrronClick")
            .setContentText(getString(R.string.playback_running))
            .setContentIntent(open)
            .addAction(stopAction)
            .setVisibility(Notification.VISIBILITY_PUBLIC) // usable from the lock screen
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val ID = 1
        private const val CHANNEL = "playback"
        private const val STOP = "stop"

        // The notification's Parar button; the activity forwards it to Dart.
        var onStop: (() -> Unit)? = null
        var running = false
            private set

        // Only works while the app is in the foreground (Android 12+); the app asks
        // for it when the user presses play or joins a session, so that is fine.
        fun set(context: Context, on: Boolean) {
            val intent = Intent(context, PlaybackService::class.java)
            if (!on) {
                context.stopService(intent)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
}
