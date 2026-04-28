import 'api_service.dart';
import 'websocket_service.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  String? _username;
  bool    _isAdmin = false;

  String? get username => _username;
  bool    get isAdmin  => _isAdmin;

  void login(String username, bool isAdmin, String token) {
    _username = username;
    _isAdmin  = isAdmin;
    ApiService().setToken(token);
  }

  void logout() {
    _username = null;
    _isAdmin  = false;
    ApiService().clearToken();
    WebSocketService().disconnect();
  }
}