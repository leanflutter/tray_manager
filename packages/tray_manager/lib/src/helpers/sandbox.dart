import 'dart:io';

/// Returns `true` if the app is running in a sandbox, eg. Flatpak, Snap, Linglong, Docker, Podman.
bool runningInSandbox() {
  return Platform.environment.containsKey('FLATPAK_ID') ||
      Platform.environment.containsKey('SNAP') ||
      Platform.environment.containsKey('LINGLONG_APPID') ||
      (Platform.environment['container']?.isNotEmpty == true) ||
      FileSystemEntity.isFileSync('/.dockerenv');
}
