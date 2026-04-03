package com.example.power_button_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.util.Log

class PowerButtonPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var isListening = false

    // Tracking variables for screen toggles
    private var pressCount = 0
    private var lastPressTime: Long = 0
    private val TIME_WINDOW = 8000L // 8 seconds window for presses
    private val mainHandler = Handler(Looper.getMainLooper())

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            if (action == Intent.ACTION_SCREEN_ON || action == Intent.ACTION_SCREEN_OFF) {
                val now = System.currentTimeMillis()

                if (now - lastPressTime > TIME_WINDOW) {
                    // Too slow, reset counter
                    pressCount = 1
                } else {
                    pressCount++
                }

                lastPressTime = now
                Log.d("PowerButtonPlugin", "Screen toggle detected. Count = $pressCount")

                if (pressCount >= 3) {
                    pressCount = 0
                    Log.d("PowerButtonPlugin", ">>> SOS TRIGGERED! 3 rapid presses detected <<<")
                    // Invoke Dart callback on the main thread
                    mainHandler.post {
                        try {
                            channel.invokeMethod("onSosTriggered", null)
                        } catch (e: Exception) {
                            Log.e("PowerButtonPlugin", "Failed to invoke Dart: " + e.message)
                        }
                    }
                }
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "power_button_plugin")
        channel.setMethodCallHandler(this)

        // AUTO-REGISTER the screen receiver immediately when the plugin attaches
        // This works for BOTH the main FlutterEngine AND the background service FlutterEngine
        startListening()
    }

    private fun startListening() {
        if (isListening) return
        try {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            }
            context?.registerReceiver(screenReceiver, filter)
            isListening = true
            Log.d("PowerButtonPlugin", "Screen receiver registered successfully")
        } catch (e: Exception) {
            Log.e("PowerButtonPlugin", "Failed to register screen receiver: " + e.message)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startService" -> {
                startListening()
                result.success(true)
            }
            "stopService" -> {
                try {
                    context?.unregisterReceiver(screenReceiver)
                    isListening = false
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        try {
            context?.unregisterReceiver(screenReceiver)
            isListening = false
        } catch (_: Exception) {}
    }
}
