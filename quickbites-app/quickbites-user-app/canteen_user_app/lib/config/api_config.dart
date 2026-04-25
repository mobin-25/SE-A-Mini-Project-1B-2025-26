class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = 'https://apsit-canteen.onrender.com/api/v1';
  static const String jwtStorageKey = 'jwt_token';
  static const String userIdStorageKey = 'user_id';

  static Uri get _baseUri {
    final uri = Uri.parse(baseUrl);
    return uri;
  }

  static int get _effectivePort {
    if (_baseUri.hasPort) return _baseUri.port;
    return _baseUri.scheme == 'https' ? 443 : 80;
  }

  static String get _normalizedBasePath {
    final path = _baseUri.path;
    if (path.isEmpty || path == '/') return '';
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  static String get websocketStompUrl {
    final wsScheme = _baseUri.scheme == 'https' ? 'wss' : 'ws';
    return '$wsScheme://${_baseUri.host}:${_effectivePort}$_normalizedBasePath/ws/websocket';
  }
}
