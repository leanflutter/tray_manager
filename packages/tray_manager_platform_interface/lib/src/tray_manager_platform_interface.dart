import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tray_manager_platform_interface/src/tray_manager_method_channel.dart';

abstract class TrayManagerPlatform extends PlatformInterface {
  /// Constructs a TrayManagerPlatform.
  TrayManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static TrayManagerPlatform _instance = MethodChannelTrayManager();

  /// The default instance of [TrayManagerPlatform] to use.
  ///
  /// Defaults to [MethodChannelTrayManager].
  static TrayManagerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TrayManagerPlatform] when
  /// they register themselves.
  static set instance(TrayManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
