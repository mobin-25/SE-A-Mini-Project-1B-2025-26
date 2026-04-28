import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

String get _wsBase => 'ws://$SERVER_IP:$SERVER_PORT';

class WebSocketService {
  static final WebSocketService _i = WebSocketService._();
  factory WebSocketService() => _i;
  WebSocketService._();

  WebSocketChannel?                              _ch;
  StreamSubscription<dynamic>?                   _sub;
  final StreamController<Map<String, dynamic>>   _ctrl =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _ctrl.stream;

  bool    _connected = false;
  String? _lastUrl;
  Timer?  _ping;
  Timer?  _reconnect;

  bool get isConnected => _connected;

  void connectAdmin(String token) {
    _connect('$_wsBase/ws/admin?token=${Uri.encodeComponent(token)}');
  }

  void connectClient(String username, String token) {
    _connect('$_wsBase/ws/client/$username?token=${Uri.encodeComponent(token)}');
  }

  void _connect(String url) {
    _lastUrl = url;
    _close();
    try {
      _ch        = WebSocketChannel.connect(Uri.parse(url));
      _connected = true;
      _sub = _ch!.stream.listen(
        (dynamic raw) {
          try {
            final d = jsonDecode(raw as String);
            if (d is Map<String, dynamic> && !_ctrl.isClosed) {
              _ctrl.add(d);
            }
          } catch (_) {}
        },
        onDone: () {
          _connected = false;
          if (!_ctrl.isClosed) _ctrl.add(<String, dynamic>{'type': 'disconnected'});
          _scheduleReconnect();
        },
        onError: (Object e) {
          _connected = false;
          if (!_ctrl.isClosed) _ctrl.add(<String, dynamic>{'type': 'error'});
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
      _ping?.cancel();
      _ping = Timer.periodic(const Duration(seconds: 15), (_) {
        if (_connected) sendMsg(<String, dynamic>{'type': 'ping'});
      });
    } catch (_) {
      _connected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnect?.cancel();
    _reconnect = Timer(const Duration(seconds: 3), () {
      if (_lastUrl != null) _connect(_lastUrl!);
    });
  }

  void _close() {
    _ping?.cancel();
    _reconnect?.cancel();
    _sub?.cancel();
    try { _ch?.sink.close(); } catch (_) {}
    _ch        = null;
    _connected = false;
  }

  void sendMsg(Map<String, dynamic> msg) {
    if (_connected && _ch != null) {
      try { _ch!.sink.add(jsonEncode(msg)); } catch (_) {}
    }
  }

  void disconnect() {
    _lastUrl = null;
    _close();
  }
}