/// Backend connection configuration.
///
/// Defaults to the production API (`api.raprast-labs.space`, HTTPS/WSS)
/// everywhere — release builds need zero setup.
///
/// Local development against a backend running on your own machine
/// (`go run main.go` on `localhost:2340`) needs an explicit override,
/// since there's no way to guess "a developer's laptop" from inside the
/// app:
///   - Android emulator: `10.0.2.2` is a stable virtual alias the emulator
///     always maps back to the host machine's `localhost`.
///   - iOS simulator / web / desktop: share the host's own network stack,
///     so `localhost` works directly.
///   - A physical device needs the host machine's actual LAN IP, which
///     can change every time the host reconnects to a network.
///
/// Override at compile time via `--dart-define=API_HOST=...` (scheme-less
/// `host:port`; `http`/`ws` are assumed for any override, since that's
/// always a local dev target) — or
/// `--dart-define-from-file=config/local.json`, see
/// `config/local.json.example` (gitignored, per-machine, never committed,
/// same intent as the backend's own `.env`).
///
/// Example:
///   flutter run --dart-define-from-file=config/local.json
///   flutter run --dart-define=API_HOST=10.0.2.2:2340
class AppConfig {
  AppConfig._();

  static const String _prodHost = 'api.raprast-labs.space';

  /// `host:port` of chatmunication-api, no scheme. Empty when using the
  /// production default (its scheme is fixed to https/wss, see below).
  static String get apiHost => const String.fromEnvironment('API_HOST');

  static bool get _isLocalOverride => apiHost.isNotEmpty;

  static String get httpBaseUrl =>
      _isLocalOverride ? 'http://$apiHost' : 'https://$_prodHost';
  static String get wsBaseUrl =>
      _isLocalOverride ? 'ws://$apiHost' : 'wss://$_prodHost';
  static String get authBaseUrl => '$httpBaseUrl/auth';
  static String get apiBaseUrl => '$httpBaseUrl/api';
}
