import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../models/model.dart';
import 'login_screen.dart';

class ClientDashboard extends StatefulWidget {
  final String username;
  const ClientDashboard({super.key, required this.username});
  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  static const Color _bg      = Color(0xFF071E27);
  static const Color _cardBg  = Color(0xFF0C2F3C);
  static const Color _cyan    = Color(0xFF00E5FF);
  static const Color _btnColor = Color(0xFF00FFEE);

  double _sizeMb       = 5;
  bool   _uploading    = false;
  double _progress     = 0.0;
  int    _eta          = 0;
  Timer? _uploadTimer;

  ClientModel? _client;
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sub = WebSocketService().stream.listen(
        (Map<String, dynamic> d) => _onMsg(d),
      );
    });
  }

  void _onMsg(Map<String, dynamic> msg) {
    if (!mounted) return;
    final type = msg['type'] as String? ?? '';

    if (type == 'pong') return;

    if (type == 'blocked') {
      _uploadTimer?.cancel();
      AuthService().logout();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0C2F3C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.block_rounded, color: Colors.redAccent, size: 44),
          title: const Text('Blocked by Admin',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            msg['message'] as String? ?? 'You have been blocked.',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen()));
                },
                child: const Text('OK',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );

    } else if (type == 'stats') {
      final data = msg['data'] as Map<String, dynamic>? ?? {};
      setState(() => _client = ClientModel.fromJson(data));

    } else if (type == 'clients') {
      final list = msg['clients'] as List<dynamic>? ?? [];
      for (final c in list) {
        final m = c as Map<String, dynamic>;
        if (m['username'] == widget.username) {
          setState(() => _client = ClientModel.fromJson(m));
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  int _calcEta(double mb) {
    if (mb <= 10) return (mb / 4).ceil().clamp(1, 3);
    if (mb <= 50) return (mb / 8).ceil().clamp(3, 8);
    return (mb / 7).ceil().clamp(8, 15);
  }

  void _sendFile() {
    if (_uploading) return;
    _uploadTimer?.cancel();
    final totalSecs  = _calcEta(_sizeMb);
    final totalSteps = totalSecs * 10;
    int steps = 0;

    setState(() {
      _uploading = true;
      _progress  = 0.0;
      _eta       = totalSecs;
    });

    _uploadTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) { t.cancel(); return; }
      steps++;
      final pct = steps / totalSteps;
      setState(() {
        _progress = pct.clamp(0.0, 1.0);
        _eta      = ((1.0 - pct) * totalSecs).ceil().clamp(0, totalSecs);
      });
      if (steps >= totalSteps) {
        t.cancel();
        _doUpload();
      }
    });
  }

  Future<void> _doUpload() async {
    final res = await ApiService().uploadFile(_sizeMb);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() { _uploading = false; _progress = 0.0; _eta = 0; });
    } else {
      setState(() { _uploading = false; _progress = 0.0; });
      if (res['error'] != 'BLOCKED') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: ${res['error']}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _logout() {
    _uploadTimer?.cancel();
    AuthService().logout();
    Navigator.pushReplacement(context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c       = _client;
    final blocked = c?.isBlocked ?? false;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(widget.username,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              )),
              GestureDetector(
                onTap: _logout,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cyan.withOpacity(0.1),
                    border: Border.all(
                        color: _cyan.withOpacity(0.5), width: 1.5),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: _cyan, size: 20),
                ),
              ),
            ]),
          ),

          if (blocked)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: const Row(children: [
                Icon(Icons.block_rounded, color: Colors.redAccent, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('Your account has been blocked',
                    style: TextStyle(
                        color: Colors.redAccent, fontSize: 13))),
              ]),
            ),

          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _StatCard(
                icon: Icons.language_rounded,
                label: 'IP Address',
                value: (c?.ip != null && c!.ip.isNotEmpty)
                    ? c.ip : 'Connecting...',
                colors: const [Color(0xFF1976D2), Color(0xFF00B4D8)],
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.speed_rounded,
                label: 'Ping',
                value: '${c?.ping ?? 0} ms',
                colors: const [Color(0xFF0288D1), Color(0xFF26C6DA)],
                warn: (c?.ping ?? 0) > 100,
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.folder_rounded,
                label: 'Files Sent',
                value: '${c?.filesSent ?? 0}',
                colors: const [Color(0xFF01579B), Color(0xFF039BE5)],
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.sync_rounded,
                label: 'Packets',
                value: '${c?.packets ?? 0}',
                colors: const [Color(0xFF006064), Color(0xFF00ACC1)],
              ),
              const SizedBox(height: 20),

              // Upload card
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _cyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.upload_rounded,
                            color: _cyan, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text('File Upload',
                          style: TextStyle(color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _cyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${_sizeMb.round()} MB',
                            style: const TextStyle(
                                color: _cyan,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor:   _cyan,
                        inactiveTrackColor: Colors.white10,
                        thumbColor:         _cyan,
                        overlayColor:       _cyan.withOpacity(0.1),
                        trackHeight:        3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 9),
                      ),
                      child: Slider(
                        value: _sizeMb, min: 1, max: 100, divisions: 99,
                        onChanged: _uploading
                            ? null
                            : (v) => setState(() => _sizeMb = v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1 MB',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 11)),
                        Row(children: [
                          Icon(Icons.timer_outlined,
                              color: _cyan.withOpacity(0.8), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _uploading
                                ? 'ETA: ${_eta}s'
                                : 'Est. ~${_calcEta(_sizeMb)}s',
                            style: TextStyle(
                                color: _uploading
                                    ? _cyan
                                    : _cyan.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                        Text('100 MB',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _uploading ? _progress : 0.0,
                        backgroundColor: Colors.white.withOpacity(0.07),
                        valueColor: const AlwaysStoppedAnimation<Color>(_cyan),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Send button
              SizedBox(
                width: double.infinity, height: 58,
                child: ElevatedButton.icon(
                  onPressed: (blocked || _uploading) ? null : _sendFile,
                  icon: _uploading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2.5))
                      : const Icon(Icons.cloud_upload_rounded, size: 22),
                  label: Text(_uploading ? 'Uploading...' : 'Send File',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _btnColor,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: _btnColor.withOpacity(0.2),
                    disabledForegroundColor: Colors.black38,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          )),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData    icon;
  final String      label;
  final String      value;
  final List<Color> colors;
  final bool        warn;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2F3C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: warn
              ? Colors.orange.withOpacity(0.45)
              : Colors.white.withOpacity(0.05),
          width: warn ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            boxShadow: [
              BoxShadow(
                  color: colors.last.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: warn ? Colors.orange : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ],
        )),
        if (warn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('HIGH',
                style: TextStyle(color: Colors.orange,
                    fontSize: 10, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }
}