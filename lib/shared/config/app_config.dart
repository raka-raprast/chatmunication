import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend connection configuration.
///
/// Emulators/simulators/web need zero setup — the default already points
/// at the right place for each:
///   - Android emulator: `10.0.2.2` is a stable virtual alias the emulator
///     always maps back to the host machine's `localhost`, regardless of
///     whatever Wi-Fi network the host is on.
///   - iOS simulator / web / desktop: these share the host's own network
///     stack, so `localhost` just works directly.
///
/// A **physical device** is the only case with no such alias back to the
/// host — it needs the host machine's actual LAN IP, which can change
/// every time the host reconnects to a network. Override it at compile
/// time via `--dart-define=API_HOST=...` (or
/// `--dart-define-from-file=config/local.json`, see
/// `config/local.json.example` — gitignored, so it's per-machine and never
/// committed, same intent as the backend's own `.env`).
///
/// Example:
///   flutter run --dart-define-from-file=config/local.json
///   flutter run --dart-define=API_HOST=192.168.1.50:2340
class AppConfig {
  AppConfig._();

  static String get _platformDefault {
    if (kIsWeb) return 'localhost:2340';
    if (Platform.isAndroid) return '10.0.2.2:2340';
    return 'localhost:2340';
  }

  /// `host:port` of chatmunication-api, no scheme.
  static String get apiHost {
    const override = String.fromEnvironment('API_HOST');
    return override.isEmpty ? _platformDefault : override;
  }

  static String get httpBaseUrl => 'http://$apiHost';
  static String get wsBaseUrl => 'ws://$apiHost';
  static String get authBaseUrl => '$httpBaseUrl/auth';
  static String get apiBaseUrl => '$httpBaseUrl/api';
}
