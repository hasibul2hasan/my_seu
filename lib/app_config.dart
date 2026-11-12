/// Central place for all compile-time configuration.
///
/// Values are injected at build time via --dart-define (from .env through
/// run.sh / build.sh). They are compiled into the binary — never shipped
/// as a separate file.
///
/// Usage in code:
///   AppConfig.mapsApiKey
///   AppConfig.umsProxyUrl
///   AppConfig.classroomClientId
library app_config;

class AppConfig {
  AppConfig._();

  /// Google Maps Embed API key.
  /// Set MAPS_EMBED_API_KEY in .env
  static const String mapsApiKey = String.fromEnvironment(
    'MAPS_EMBED_API_KEY',
    defaultValue: '',
  );

  /// Cloudflare Worker URL that proxies ums.seu.edu.bd (no trailing slash).
  /// Set UMS_PROXY_URL in .env
  static const String umsProxyUrl = String.fromEnvironment(
    'UMS_PROXY_URL',
    defaultValue: 'https://ums.seu.edu.bd',
  );

  /// Google OAuth 2.0 Web Client ID for the Classroom API.
  /// Set CLASSROOM_CLIENT_ID in .env
  static const String classroomClientId = String.fromEnvironment(
    'CLASSROOM_CLIENT_ID',
    defaultValue: '',
  );

  /// True when the Maps API key has been configured.
  static bool get hasMapsKey => mapsApiKey.isNotEmpty && mapsApiKey != 'YOUR_MAPS_EMBED_API_KEY';

  /// True when the UMS proxy URL has been overridden from the default.
  static bool get hasUmsProxy => umsProxyUrl != 'https://ums.seu.edu.bd';

  /// True when the Classroom client ID has been configured.
  static bool get hasClassroomClient =>
      classroomClientId.isNotEmpty &&
      classroomClientId != 'YOUR_CLIENT_ID.apps.googleusercontent.com';
}

