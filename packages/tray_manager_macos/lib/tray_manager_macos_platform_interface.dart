import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tray_manager_macos_method_channel.dart';

abstract class TrayManagerMacosPlatform extends PlatformInterface {
  /// Constructs a TrayManagerMacosPlatform.
  TrayManagerMacosPlatform() : super(token: _token);

  static final Object _token = Object();

  static TrayManagerMacosPlatform _instance = MethodChannelTrayManagerMacos();

  /// The default instance of [TrayManagerMacosPlatform] to use.
  ///
  /// Defaults to [MethodChannelTrayManagerMacos].
  static TrayManagerMacosPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TrayManagerMacosPlatform] when
  /// they register themselves.
  static set instance(TrayManagerMacosPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
