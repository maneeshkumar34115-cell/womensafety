import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'power_button_plugin_platform_interface.dart';

/// An implementation of [PowerButtonPluginPlatform] that uses method channels.
class MethodChannelPowerButtonPlugin extends PowerButtonPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('power_button_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
