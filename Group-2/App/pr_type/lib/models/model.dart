class ClientModel {
  final String username;
  final String ip;
  final int    filesSent;
  final int    packets;
  final int    ping;
  final bool   isBlocked;
  final bool   isFlooder;
  final bool   isOnline;

  const ClientModel({
    required this.username,
    required this.ip,
    this.filesSent = 0,
    this.packets   = 0,
    this.ping      = 0,
    this.isBlocked = false,
    this.isFlooder = false,
    this.isOnline  = false,
  });

  factory ClientModel.fromJson(Map<String, dynamic> j) => ClientModel(
    username:  j['username']    as String? ?? '',
    ip:        j['ip']          as String? ?? '',
    filesSent: (j['files_sent'] as num?)?.toInt() ?? 0,
    packets:   (j['packets']    as num?)?.toInt() ?? 0,
    ping:      (j['ping']       as num?)?.toInt() ?? 0,
    isBlocked: j['is_blocked']  as bool?   ?? false,
    isFlooder: j['is_flooder']  as bool?   ?? false,
    isOnline:  j['online']      as bool?   ?? false,
  );
}

class LogEntry {
  final String time;
  final String sourceIp;
  final String destIp;
  final String protocol;
  final String info;
  final int    length;

  const LogEntry({
    required this.time,
    required this.sourceIp,
    required this.destIp,
    required this.protocol,
    required this.info,
    required this.length,
  });

  bool get isHighTraffic =>
      info.contains('⚠️') ||
      info.toLowerCase().contains('flood') ||
      info.toLowerCase().contains('detected') ||
      info.toLowerCase().contains('blocked');

  factory LogEntry.fromJson(Map<String, dynamic> j) {
    String ts = '';
    final raw = (j['time'] ?? j['time_str'] ?? '') as String;
    if (raw.isNotEmpty) {
      if (raw.contains('T') || raw.contains('-')) {
        try {
          final dt = DateTime.parse(raw);
          ts = '${dt.hour.toString().padLeft(2,'0')}:'
               '${dt.minute.toString().padLeft(2,'0')}:'
               '${dt.second.toString().padLeft(2,'0')}';
        } catch (_) {
          ts = raw.length > 8 ? raw.substring(0, 8) : raw;
        }
      } else {
        ts = raw;
      }
    }
    return LogEntry(
      time:     ts,
      sourceIp: (j['src_ip']   ?? j['source_ip'] ?? '') as String,
      destIp:   (j['dst_ip']   ?? j['dest_ip']   ?? 'SERVER') as String,
      protocol: (j['protocol'] ?? '') as String,
      length:   (j['length']   as num?)?.toInt() ?? 0,
      info:     (j['info']     ?? '') as String,
    );
  }

  @override
  String toString() =>
      '$time | $sourceIp → $destIp | $protocol | ${length}B | $info';
}