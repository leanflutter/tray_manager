
import 'tray_manager_macos_platform_interface.dart';

class TrayManagerMacos {
  Future<String?> getPlatformVersion() {
    return TrayManagerMacosPlatform.instance.getPlatformVersion();
  }
}
