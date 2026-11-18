package com.prronclick.prronclick

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

// Vibrates on the beat, screen off too: a thread asks the engine how long until
// the next beat that sounds and fires the motor just before it. Runs while
// PlaybackService does; Dart sets the mode.
object Haptics {
    @Volatile
    var mode = 0 // 0 off, 1 every beat, 2 only the bar's first beat

    // The motor takes about this long to be felt. shortcut: fixed, measured on
    // one Samsung; make it a setting if other phones feel early or late.
    private const val LEAD_MICROS = 10_000L
    private val millis = longArrayOf(55, 35, 30) // by accent: strong, medium, plain
    private val strength = intArrayOf(255, 210, 170) // plain at 100 was barely felt

    private var thread: Thread? = null

    // The library Dart opened: loading it again returns that same instance.
    private external fun nextFeltBeat(downbeatOnly: Boolean): Long

    fun supported(context: Context) = vibrator(context)?.hasVibrator() == true

    @Synchronized
    fun start(context: Context) {
        if (thread != null) return
        val vibrator = vibrator(context) ?: return
        if (!vibrator.hasVibrator()) return
        System.loadLibrary("prronclick_engine")
        thread = Thread({ run(vibrator) }, "prronclick-haptics").apply {
            priority = Thread.MAX_PRIORITY
            start()
        }
    }

    @Synchronized
    fun stop() {
        thread?.interrupt()
        thread = null
    }

    private fun vibrator(context: Context): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator?
        }

    private fun run(vibrator: Vibrator) {
        try {
            while (!Thread.currentThread().isInterrupted) {
                val m = mode
                val next = if (m == 0) -1L else nextFeltBeat(m == 2)
                if (next < 0) {
                    Thread.sleep(50) // stopped or off
                    continue
                }
                val micros = next / 4
                val wait = micros - LEAD_MICROS
                if (wait > 2_000) {
                    // Wake up again before it: tempo or song may change meanwhile.
                    sleepMicros(minOf(wait, 20_000))
                    continue
                }
                buzz(vibrator, (next % 4).toInt())
                sleepMicros(micros + 5_000) // past this beat, then ask for the next
            }
        } catch (e: InterruptedException) {
            // stopped
        }
    }

    private fun sleepMicros(micros: Long) {
        if (micros > 0) Thread.sleep(micros / 1000, ((micros % 1000) * 1000).toInt())
    }

    private fun buzz(vibrator: Vibrator, level: Int) {
        val ms = millis[level.coerceIn(0, 2)]
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            vibrator.vibrate(ms)
            return
        }
        val amplitude =
            if (vibrator.hasAmplitudeControl()) strength[level.coerceIn(0, 2)]
            else VibrationEffect.DEFAULT_AMPLITUDE
        val effect = VibrationEffect.createOneShot(ms, amplitude)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            vibrator.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_MEDIA))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(
                effect,
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).build()
            )
        }
    }
}
