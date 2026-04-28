import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';
import '../models/model.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  Map<String, ClientModel> _clients    = {};
  List<LogEntry>           _logs       = [];
  List<double>             _latency    = [];
  double                   _serverLoad = 0.15;
  bool                     _wsOk       = false;
  int                      _netRecv    = 0;
  int                      _netSent    = 0;
  int                      _netPkt     = 0;

  final List<Map<String, dynamic>> _notifs = [];
  int  _unread          = 0;
  bool _showNotifPanel  = false;

  StreamSubscription<Map<String, dynamic>>? _sub;

  static const Color _cyan   = Color(0xFF00E5FF);
  static const Color _bg     = Color(0xFF0D1F2D);
  static const Color _card   = Color(0xFF152535);
  static const Color _appBar = Color(0xFF0A1929);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sub = WebSocketService().stream.listen(
        (Map<String, dynamic> d) => _onMsg(d),
      );
      if (mounted) setState(() => _wsOk = WebSocketService().isConnected);
    });
  }

  void _onMsg(Map<String, dynamic> msg) {
    if (!mounted) return;
    final type = msg['type'] as String? ?? '';

    if (type == 'clients') {
      final list = msg['clients'] as List<dynamic>? ?? [];
      final map  = <String, ClientModel>{};
      for (final c in list) {
        final m = ClientModel.fromJson(c as Map<String, dynamic>);
        map[m.username] = m;
      }
      final lat = msg['latency'] as List<dynamic>? ?? [];
      final net = msg['net']     as Map<String, dynamic>? ?? {};
      setState(() {
        _clients    = map;
        _serverLoad = (msg['load'] as num?)?.toDouble() ?? 0.15;
        _latency    = lat.map((e) => (e as num).toDouble()).toList();
        _wsOk       = true;
        _netRecv    = (net['recv_ps']     as num?)?.toInt() ?? 0;
        _netSent    = (net['sent_ps']     as num?)?.toInt() ?? 0;
        _netPkt     = ((net['pkt_recv_ps'] as num?)?.toInt() ?? 0) +
                      ((net['pkt_sent_ps'] as num?)?.toInt() ?? 0);
      });

    } else if (type == 'packet') {
      final p = msg['packet'] as Map<String, dynamic>? ?? {};
      setState(() {
        _logs.insert(0, LogEntry.fromJson(p));
        if (_logs.length > 300) _logs.removeLast();
      });

    } else if (type == 'logs') {
      final list = msg['logs'] as List<dynamic>? ?? [];
      setState(() {
        _logs = list
            .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      });

    } else if (type == 'notification') {
      final notif = {
        'level':    msg['level']    ?? 'info',
        'title':    msg['title']    ?? '',
        'message':  msg['message']  ?? '',
        'username': msg['username'] ?? '',
        'rate':     (msg['rate'] as num?)?.toInt() ?? 0,
        'time':     DateTime.now().toString().substring(11, 19),
      };
      setState(() {
        _notifs.insert(0, notif);
        if (_notifs.length > 50) _notifs.removeLast();
        if (!_showNotifPanel) _unread++;
      });

      // Real phone notification
      final uname = msg['username'] as String? ?? '';
      final rate  = (msg['rate'] as num?)?.toInt() ?? 0;
      if (msg['level'] == 'critical') {
        NotificationService().showAutoBlocked(uname, rate, 500);
      } else if (msg['level'] == 'warning') {
        NotificationService().showFloodWarning(uname, rate);
      }

      // In-app snackbar
      if (mounted) {
        final isCrit = msg['level'] == 'critical';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: isCrit ? Colors.red.shade900 : const Color(0xFF7B3F00),
          duration: Duration(seconds: isCrit ? 5 : 3),
          content: Row(children: [
            Icon(isCrit ? Icons.block_rounded : Icons.warning_amber_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(notif['message'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 12))),
          ]),
        ));
      }

    } else if (type == 'disconnected' || type == 'error') {
      setState(() => _wsOk = false);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _sub?.cancel();
    super.dispose();
  }

  String _fmtBytes(int b) {
    if (b >= 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    if (b >= 1024)        return '${(b / 1024).toStringAsFixed(1)} KB/s';
    return '$b B/s';
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _appBar,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          const Text('SECURITY OPERATIONS CENTER',
              style: TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Container(width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: _wsOk ? Colors.greenAccent : Colors.redAccent)),
        ]),
        actions: [
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded, color: Colors.white),
              onPressed: () => setState(() {
                _showNotifPanel = !_showNotifPanel;
                if (_showNotifPanel) _unread = 0;
              }),
            ),
            if (_unread > 0)
              Positioned(right: 8, top: 8,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Center(child: Text('$_unread',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.bold))),
                )),
          ]),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () {
              AuthService().logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _cyan, indicatorWeight: 3,
          labelColor: _cyan, unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Wireshark'),
            Tab(text: 'Downloads'),
          ],
        ),
      ),
      body: Stack(children: [
        TabBarView(controller: _tab,
            children: [_buildDashboard(), _buildWireshark(), _buildDownloads()]),
        if (_showNotifPanel) _buildNotifPanel(),
      ]),
    );
  }

  // ── Notification panel ─────────────────────────────────────────────────────
  Widget _buildNotifPanel() {
    return Positioned(
      top: 0, right: 0, bottom: 0, width: 300,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A1929),
            border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F)))),
              child: Row(children: [
                const Icon(Icons.notifications_rounded, color: _cyan, size: 18),
                const SizedBox(width: 8),
                const Expanded(child: Text('Alerts',
                    style: TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.bold))),
                if (_notifs.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _notifs.clear()),
                    child: const Text('Clear',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: () => setState(() => _showNotifPanel = false),
                ),
              ]),
            ),
            Expanded(
              child: _notifs.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            color: Colors.white.withOpacity(0.2), size: 44),
                        const SizedBox(height: 10),
                        Text('No alerts',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3))),
                      ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _notifs.length,
                      itemBuilder: (_, i) {
                        final n      = _notifs[i];
                        final isCrit = n['level'] == 'critical';
                        final isWarn = n['level'] == 'warning';
                        final color  = isCrit ? Colors.redAccent
                                     : isWarn  ? Colors.amber
                                     :           _cyan;
                        final icon   = isCrit ? Icons.block_rounded
                                     : isWarn  ? Icons.warning_amber_rounded
                                     :           Icons.info_rounded;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(icon, color: color, size: 14),
                                const SizedBox(width: 6),
                                Expanded(child: Text(n['title'] as String,
                                    style: TextStyle(color: color,
                                        fontSize: 12, fontWeight: FontWeight.bold))),
                                Text(n['time'] as String,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 9)),
                              ]),
                              const SizedBox(height: 5),
                              Text(n['message'] as String,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                              if ((n['rate'] as int) > 0) ...[
                                const SizedBox(height: 3),
                                Text('${n['rate']} pkt/s',
                                    style: TextStyle(color: color.withOpacity(0.8),
                                        fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                              if (isCrit) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final u = n['username'] as String;
                                      if (u.isNotEmpty) ApiService().unblockUser(u);
                                      setState(() => _notifs.removeAt(i));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.withOpacity(0.25),
                                      foregroundColor: Colors.greenAccent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Unblock',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Dashboard tab ──────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final online  = _clients.values.where((c) => c.isOnline).length;
    final blocked = _clients.values.where((c) => c.isBlocked).length;
    final flood   = _clients.values
        .where((c) => c.isFlooder && !c.isBlocked && c.isOnline).length;

    return ListView(padding: const EdgeInsets.all(14), children: [
      if (!_wsOk)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withOpacity(0.4))),
          child: const Row(children: [
            Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 16),
            SizedBox(width: 8),
            Text('Reconnecting...', style: TextStyle(color: Colors.orange, fontSize: 13)),
          ]),
        ),

      // Quick stats
      Row(children: [
        _QStat('Online',  '$online',  Colors.greenAccent),
        const SizedBox(width: 8),
        _QStat('Blocked', '$blocked', Colors.redAccent),
        const SizedBox(width: 8),
        _QStat('Flood',   '$flood',   Colors.amber),
      ]),
      const SizedBox(height: 14),

      // Server load
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.speed_rounded, color: _cyan, size: 20),
            SizedBox(width: 8),
            Text('Server Load', style: TextStyle(color: Colors.white,
                fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _serverLoad),
            duration: const Duration(milliseconds: 700),
            builder: (_, v, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: v, backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        v > 0.7 ? Colors.red : v > 0.4 ? Colors.orange : Colors.green),
                    minHeight: 16),
                ),
                const SizedBox(height: 6),
                Text('${(v * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: v > 0.7 ? Colors.red : v > 0.4 ? Colors.orange : Colors.white54,
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),

     

      // Latency graph
      Container(
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Icon(Icons.show_chart_rounded, color: _cyan, size: 20),
              SizedBox(width: 8),
              Text('Network Latency Graph',
                  style: TextStyle(color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 200, child: _Graph(data: _latency, color: _cyan)),
        ]),
      ),
      const SizedBox(height: 18),

      Row(children: [
        const Text('Connected Clients',
            style: TextStyle(color: Colors.white, fontSize: 17,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Text('($online online / ${_clients.length} total)',
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ]),
      const SizedBox(height: 12),

      if (_clients.isEmpty)
        Center(child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(children: [
            Icon(Icons.people_outline_rounded,
                color: Colors.white.withOpacity(0.2), size: 48),
            const SizedBox(height: 12),
            Text('Waiting for clients...',
                style: TextStyle(color: Colors.white.withOpacity(0.3))),
          ]),
        ))
      else
        for (final c in _clients.values) _clientCard(c),
    ]);
  }

  Widget _clientCard(ClientModel c) {
    final fl = c.isFlooder && !c.isBlocked && c.isOnline;
    final bg = fl          ? const Color(0xFFB71C1C)
             : c.isBlocked  ? const Color(0xFF1A1A2E)
             : c.isOnline   ? const Color(0xFF1C3A47)
             :                 const Color(0xFF141E26);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fl ? Colors.red.withOpacity(0.6) : Colors.white.withOpacity(0.05),
          width: fl ? 1.5 : 1)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Wrap(spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(c.username, style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.isOnline
                      ? Colors.greenAccent.withOpacity(0.15)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(
                  c.isBlocked ? 'BLOCKED' : c.isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: c.isBlocked ? Colors.redAccent
                         : c.isOnline  ? Colors.greenAccent
                         :               Colors.white38,
                    fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              if (fl)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                  child: const Text('⚠️ FLOODER',
                      style: TextStyle(color: Colors.amber,
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ])),
            if (fl)         const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24)
            else if (c.isBlocked) const Icon(Icons.block_rounded, color: Colors.white38, size: 22)
            else if (c.isOnline)  const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 24)
            else                  const Icon(Icons.person_off_rounded, color: Colors.white24, size: 22),
          ]),
          const SizedBox(height: 10),
          _IRow(Icons.language_rounded,   'IP:',      c.ip,             fl),
          _IRow(Icons.upload_file_rounded, 'Files:',  '${c.filesSent}', fl),
          _IRow(Icons.wifi_rounded,        'Packets:', '${c.packets}',  fl),
          _IRow(Icons.speed_rounded,       'Ping:',   '${c.ping} ms',   fl),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: c.isBlocked
                  ? () => ApiService().unblockUser(c.username)
                  : () => ApiService().blockUser(c.username),
              icon: Icon(c.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                  size: 16),
              label: Text(c.isBlocked ? 'Unblock' : 'Block',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.isBlocked ? Colors.green
                    : fl ? const Color(0xFF7B0000) : Colors.red,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Wireshark tab ──────────────────────────────────────────────────────────
  Widget _buildWireshark() {
    return Column(children: [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF1B3A20),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14), topRight: Radius.circular(14))),
        child: Row(children: [
          const Icon(Icons.wifi_tethering_rounded, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 8),
          const Text('Wireshark Packet Analyzer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const Spacer(),
          _PulseDot(active: _wsOk),
          const SizedBox(width: 6),
          Text('${_logs.length} pkts',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _open('http://192.168.0.104:8000/admin/logs/download/all?key=admin123'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.4))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.download_rounded, color: Colors.greenAccent, size: 14),
                SizedBox(width: 4),
                Text('CSV', style: TextStyle(color: Colors.greenAccent,
                    fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ]),
      ),
      Expanded(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F0A),
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14)),
            border: Border.all(color: Colors.green.withOpacity(0.2))),
          child: _logs.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded,
                        color: Colors.white.withOpacity(0.15), size: 40),
                    const SizedBox(height: 12),
                    Text('Waiting for packets...',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3), fontSize: 13)),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _logs.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(_logs[i].toString(),
                        style: TextStyle(
                            color: _logs[i].isHighTraffic
                                ? const Color(0xFFFF5252)
                                : const Color(0xFF69F0AE),
                            fontSize: 11)),
                  )),
        ),
      ),
    ]);
  }

  // ── Downloads tab ──────────────────────────────────────────────────────────
  Widget _buildDownloads() {
    const base = 'http://192.168.0.104:8000';
    const k    = '?key=admin123';
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 8),
      const Row(children: [
        Icon(Icons.cloud_download_rounded, color: _cyan, size: 22),
        SizedBox(width: 10),
        Text('Export & Download',
            style: TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 6),
      Text('Tap any card — browser opens and CSV downloads',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
      const SizedBox(height: 20),

      // ML Dataset
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.dataset_rounded, color: Colors.purpleAccent, size: 20),
            SizedBox(width: 8),
            Text('ML Dataset Export',
                style: TextStyle(color: Colors.purpleAccent,
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text('24 columns + label (0=Normal, 1=Flooder)',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _DlBtn('📊 Full',
                '$base/admin/dataset/download?key=admin123&label_mode=all',
                Colors.purpleAccent, _open)),
            const SizedBox(width: 8),
            Expanded(child: _DlBtn('🌊 Flooder',
                '$base/admin/dataset/download?key=admin123&label_mode=flooder',
                Colors.redAccent, _open)),
            const SizedBox(width: 8),
            Expanded(child: _DlBtn('📱 Client',
                '$base/admin/dataset/download?key=admin123&label_mode=client',
                Colors.greenAccent, _open)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),

      _DlCard(Icons.list_alt_rounded, 'All Logs',
          'Every event — connections, uploads, floods',
          _cyan, '$base/admin/logs/download/all$k', _open),
      const SizedBox(height: 14),
      _DlCard(Icons.warning_amber_rounded, 'Flooder Logs',
          'Only flood attack packets — label=1',
          Colors.redAccent, '$base/admin/logs/download/flooder$k', _open),
      const SizedBox(height: 14),
      _DlCard(Icons.upload_file_rounded, 'Client Logs',
          'Normal client activity — label=0',
          Colors.greenAccent, '$base/admin/logs/download/clients$k', _open),
      const SizedBox(height: 14),
      _DlCard(Icons.analytics_rounded, 'Stats Summary',
          'All clients with packets, files, ping',
          Colors.amber, '$base/admin/stats/summary$k', _open),
      const SizedBox(height: 24),

      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.white.withOpacity(0.4), size: 16),
            const SizedBox(width: 8),
            const Text('Laptop browser URLs:',
                style: TextStyle(color: Colors.white60,
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          _UrlRow('All',     '$base/admin/logs/download/all$k'),
          _UrlRow('Flooder', '$base/admin/logs/download/flooder$k'),
          _UrlRow('Clients', '$base/admin/logs/download/clients$k'),
          _UrlRow('Summary', '$base/admin/stats/summary$k'),
          _UrlRow('Dataset', '$base/admin/dataset/download?key=admin123&label_mode=all'),
        ]),
      ),
    ]);
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────
class _QStat extends StatelessWidget {
  final String l, v; final Color c;
  const _QStat(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Column(children: [
        Text(v, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(l, style: TextStyle(color: c.withOpacity(0.7), fontSize: 11)),
      ]),
    ),
  );
}

class _IRow extends StatelessWidget {
  final IconData i; final String l, v; final bool r;
  const _IRow(this.i, this.l, this.v, this.r);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Icon(i, color: r ? Colors.white70 : const Color(0xFF00E5FF), size: 16),
      const SizedBox(width: 8),
      Text('$l ', style: TextStyle(
          color: Colors.white.withOpacity(r ? 0.85 : 0.6), fontSize: 14)),
      Text(v, style: const TextStyle(color: Colors.white,
          fontSize: 14, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _NetTile extends StatelessWidget {
  final IconData i; final String l, v; final Color c;
  const _NetTile({required this.i,required this.l,required this.v,required this.c});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Column(children: [
        Icon(i, color: c, size: 18),
        const SizedBox(height: 4),
        Text(v, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(l, style: TextStyle(color: c.withOpacity(0.6), fontSize: 10)),
      ]),
    ),
  );
}

class _PulseDot extends StatefulWidget {
  final bool active;
  const _PulseDot({this.active = true});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double>   _a;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(_ac);
  }
  @override void dispose() { _ac.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(width: 8, height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle,
            color: widget.active ? Colors.greenAccent : Colors.grey)),
  );
}

class _DlCard extends StatelessWidget {
  final IconData i; final String title, sub, url; final Color c;
  final Future<void> Function(String) open;
  const _DlCard(this.i,this.title,this.sub,this.c,this.url,this.open);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => open(url),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF152535), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(0.25))),
      child: Row(children: [
        Container(width: 48, height: 48,
            decoration: BoxDecoration(color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(i, color: c, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: c, fontSize: 15,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(sub, style: TextStyle(
              color: Colors.white.withOpacity(0.45), fontSize: 12)),
        ])),
        Icon(Icons.download_rounded, color: c, size: 22),
      ]),
    ),
  );
}

class _DlBtn extends StatelessWidget {
  final String l, url; final Color c;
  final Future<void> Function(String) open;
  const _DlBtn(this.l, this.url, this.c, this.open);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => open(url),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.35))),
      child: Column(children: [
        Icon(Icons.download_rounded, color: c, size: 18),
        const SizedBox(height: 4),
        Text(l, style: TextStyle(color: c, fontSize: 11,
            fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _UrlRow extends StatelessWidget {
  final String l, url;
  const _UrlRow(this.l, this.url);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 60, child: Text('$l:', style: TextStyle(
          color: Colors.white.withOpacity(0.5), fontSize: 11))),
      Expanded(child: Text(url,
          style: const TextStyle(color: Color(0xFF00E5FF),
              fontSize: 9, fontFamily: 'monospace'),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}

// ── Graph ─────────────────────────────────────────────────────────────────────
class _Graph extends StatefulWidget {
  final List<double> data; final Color color;
  const _Graph({required this.data, required this.color});
  @override State<_Graph> createState() => _GraphState();
}
class _GraphState extends State<_Graph> {
  int? _idx; Offset? _pos;
  void _move(Offset l, Size s) {
    if (widget.data.length < 2) return;
    final i = ((l.dx / s.width) * (widget.data.length - 1))
        .round().clamp(0, widget.data.length - 1);
    setState(() { _idx = i; _pos = l; });
  }
  void _exit() => setState(() { _idx = null; _pos = null; });
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, bc) {
    final sz = Size(bc.maxWidth, bc.maxHeight);
    return MouseRegion(
      onHover: (e) => _move(e.localPosition, sz),
      onExit:  (_) => _exit(),
      child: GestureDetector(
        onPanUpdate: (d) => _move(d.localPosition, sz),
        onPanEnd:    (_) => _exit(),
        child: Stack(children: [
          CustomPaint(size: sz,
              painter: _GP(data: widget.data, color: widget.color, hi: _idx)),
          if (_idx != null && _pos != null && _idx! < widget.data.length)
            Positioned(
              left: (_pos!.dx + 12).clamp(0.0, sz.width - 80),
              top:  (_pos!.dy - 50).clamp(0.0, sz.height - 50),
              child: IgnorePointer(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF001E2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.color, width: 1.2),
                  boxShadow: [BoxShadow(
                      color: widget.color.withOpacity(0.3), blurRadius: 10)]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${widget.data[_idx!].round()} ms',
                      style: TextStyle(color: widget.color,
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('pt ${_idx! + 1}',
                      style: TextStyle(
                          color: widget.color.withOpacity(0.55), fontSize: 10)),
                ]),
              )),
            ),
        ]),
      ),
    );
  });
}

class _GP extends CustomPainter {
  final List<double> data; final Color color; final int? hi;
  const _GP({required this.data, required this.color, this.hi});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) {
      final tp = TextPainter(
        text: TextSpan(text: 'Collecting data...',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width/2-tp.width/2, size.height/2-tp.height/2));
      return;
    }
    double mx=data[0], mn=data[0];
    for (final d in data) { if(d>mx) mx=d; if(d<mn) mn=d; }
    final rng = (mx-mn)<10 ? 60.0 : mx-mn;
    const tp=22.0; const bp=14.0;
    final h = size.height-tp-bp;
    double fy(double v) => tp+(1-(v-mn)/rng)*h;
    final pts = [for(int i=0;i<data.length;i++)
      Offset(i/(data.length-1)*size.width, fy(data[i]))];
    final grid=Paint()..color=Colors.white.withOpacity(0.07)..strokeWidth=0.8;
    for(int i=1;i<=4;i++)
      canvas.drawLine(Offset(0,size.height/5*i),Offset(size.width,size.height/5*i),grid);
    final fill=Path()..moveTo(pts.first.dx,pts.first.dy);
    for(int i=1;i<pts.length;i++) fill.lineTo(pts[i].dx,pts[i].dy);
    fill..lineTo(size.width,size.height)..lineTo(0,size.height)..close();
    canvas.drawPath(fill,Paint()
      ..shader=LinearGradient(colors:[color.withOpacity(0.35),color.withOpacity(0)],
          begin:Alignment.topCenter,end:Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0,0,size.width,size.height))
      ..style=PaintingStyle.fill);
    final line=Path()..moveTo(pts.first.dx,pts.first.dy);
    for(int i=1;i<pts.length;i++) line.lineTo(pts[i].dx,pts[i].dy);
    canvas.drawPath(line,Paint()..color=color..strokeWidth=2.5
        ..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round);
    if(hi!=null&&hi!<pts.length){
      final hp=pts[hi!];
      canvas.drawLine(Offset(hp.dx,0),Offset(hp.dx,size.height),
          Paint()..color=color.withOpacity(0.35)..strokeWidth=1);
      canvas.drawCircle(hp,8,Paint()..color=color.withOpacity(0.2));
      canvas.drawCircle(hp,5,Paint()..color=Colors.black);
      canvas.drawCircle(hp,4,Paint()..color=color);
    }
    for(int i=0;i<pts.length;i++){
      if(hi==i) continue;
      canvas.drawCircle(pts[i],2.5,Paint()..color=Colors.black);
      canvas.drawCircle(pts[i],2,Paint()..color=color);
    }
    void lbl(String t,double y){
      final lp=TextPainter(text:TextSpan(text:t,
          style:TextStyle(color:Colors.white.withOpacity(0.4),fontSize:9)),
          textDirection:TextDirection.ltr)..layout();
      lp.paint(canvas,Offset(4,y-lp.height/2));
    }
    lbl('${mx.round()} ms',fy(mx));
    lbl('${mn.round()} ms',fy(mn));
  }
  @override
  bool shouldRepaint(covariant _GP old) => old.data!=data||old.hi!=hi;
}