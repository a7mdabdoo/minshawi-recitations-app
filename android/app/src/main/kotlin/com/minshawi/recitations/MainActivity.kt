package com.minshawi.recitations

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.minshawi.recitations/battery_optimization"
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
    }

    private fun enableHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val currentDisplay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display
                } else {
                    @Suppress("DEPRECATION")
                    windowManager.defaultDisplay
                }
                val modes = currentDisplay?.supportedModes
                if (!modes.isNullOrEmpty()) {
                    var maxMode = modes[0]
                    for (mode in modes) {
                        if (mode.refreshRate > maxMode.refreshRate) {
                            maxMode = mode
                        }
                    }
                    val layoutParams = window.attributes
                    layoutParams.preferredDisplayModeId = maxMode.modeId
                    window.attributes = layoutParams
                }
            } catch (_: Exception) {}
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                        powerManager?.isIgnoringBatteryOptimizations(packageName) ?: true
                    } else {
                        true
                    }
                    result.success(isIgnoring)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                startActivity(fallbackIntent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("INTENT_ERROR", e2.localizedMessage, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "acquireLocks" -> {
                    acquireWakeLock()
                    acquireWifiLock()
                    result.success(true)
                }
                "releaseLocks" -> {
                    releaseWakeLock()
                    releaseWifiLock()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun acquireWakeLock() {
        try {
            if (wakeLock == null) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "MinshawiApp:AudioWakeLock")?.apply {
                    setReferenceCounted(false)
                }
            }
            if (wakeLock?.isHeld != true) {
                wakeLock?.acquire(12 * 60 * 60 * 1000L)
            }
        } catch (_: Exception) {}
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
    }

    private fun acquireWifiLock() {
        try {
            if (wifiLock == null) {
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                wifiLock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    wifiManager?.createWifiLock(WifiManager.WIFI_MODE_FULL_LOW_LATENCY, "MinshawiApp:WifiLock")
                } else {
                    @Suppress("DEPRECATION")
                    wifiManager?.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "MinshawiApp:WifiLock")
                }
                wifiLock?.setReferenceCounted(false)
            }
            if (wifiLock?.isHeld != true) {
                wifiLock?.acquire()
            }
        } catch (_: Exception) {}
    }

    private fun releaseWifiLock() {
        try {
            if (wifiLock?.isHeld == true) {
                wifiLock?.release()
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        releaseWakeLock()
        releaseWifiLock()
        super.onDestroy()
    }
}
