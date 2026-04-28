import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const String SERVER_IP   = '192.168.0.104';
const int    SERVER_PORT = 8000;
const String BASE_URL    = 'http://$SERVER_IP:$SERVER_PORT';

class ApiService {
  static final ApiService _i = ApiService._();
  factory ApiService() => _i;
  ApiService._();

  String? _token;
  String? get token => _token;
  void setToken(String t) => _token = t;
  void clearToken()       => _token = null;

  Map<String, String> get _auth => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer ${_token ?? ""}',
  };

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final r = await http.post(
        Uri.parse('$BASE_URL/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        _token = d['token'] as String?;
        return {'success': true, ...d};
      }
      if (r.statusCode == 403) return {'success': false, 'error': 'BLOCKED'};
      final b = jsonDecode(r.body) as Map<String, dynamic>;
      return {'success': false, 'error': b['detail'] ?? 'Login failed'};
    } catch (_) {
      return {'success': false, 'error': 'Cannot connect to server'};
    }
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      final r = await http.post(
        Uri.parse('$BASE_URL/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) return {'success': true};
      final b = jsonDecode(r.body) as Map<String, dynamic>;
      return {'success': false, 'error': b['detail'] ?? 'Register failed'};
    } catch (_) {
      return {'success': false, 'error': 'Cannot connect to server'};
    }
  }

  Future<Map<String, dynamic>> uploadFile(double sizeMb) async {
    try {
      final uri     = Uri.parse('$BASE_URL/client/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${_token ?? ""}';
      final bytes    = List<int>.filled((sizeMb * 1024 * 1024).round(), 0);
      final filename = 'upload_${DateTime.now().millisecondsSinceEpoch}.bin';
      request.files.add(http.MultipartFile.fromBytes(
        'file', bytes,
        filename: filename,
        contentType: MediaType('application', 'octet-stream'),
      ));
      final s = await request.send().timeout(const Duration(seconds: 30));
      final b = await s.stream.bytesToString();
      if (s.statusCode == 200) {
        return {'success': true, ...(jsonDecode(b) as Map<String, dynamic>)};
      }
      if (s.statusCode == 403) return {'success': false, 'error': 'BLOCKED'};
      return {'success': false, 'error': 'Upload failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> blockUser(String username) async {
    try {
      final r = await http.post(
        Uri.parse('$BASE_URL/admin/block/$username'),
        headers: _auth,
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unblockUser(String username) async {
    try {
      final r = await http.post(
        Uri.parse('$BASE_URL/admin/unblock/$username'),
        headers: _auth,
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}