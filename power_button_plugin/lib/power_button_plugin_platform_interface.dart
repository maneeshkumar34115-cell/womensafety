import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'power_button_plugin_method_channel.dart';

abstract class PowerButtonPluginPlatform extends PlatformInterface {
  /// Constructs a PowerButtonPluginPlatform.
  PowerButtonPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static PowerButtonPluginPlatform _instance = MethodChannelPowerButtonPlugin();

  /// The default instance of [PowerButtonPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelPowerButtonPlugin].
  static PowerButtonPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PowerButtonPluginPlatform] when
  /// they register themselves.
  static set instance(PowerButtonPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
