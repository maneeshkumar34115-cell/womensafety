import 'dart:async';
import 'package:flutter/services.dart';

class PowerButtonPlugin {
  static const MethodChannel _channel = MethodChannel('power_button_plugin');

  // Callback that will be invoked when SOS is triggered
  static Function()? _onSosCallback;

  /// Initialize the plugin and set the SOS callback.
  /// Call this once in your background service's onStart.
  static void initialize({required Function() onSosTriggered}) {
    _onSosCallback = onSosTriggered;

    // Set up the handler so native Kotlin can invoke 'onSosTriggered' on this channel
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onSosTriggered') {
        _onSosCallback?.call();
      }
    });
  }

  /// Starts the background screen listener (also auto-starts on plugin attach)
  static Future<void> startService() async {
    await _channel.invokeMethod('startService');
  }

  /// Stops the background screen listener
  static Future<void> stopService() async {
    await _channel.invokeMethod('stopService');
  }
}
