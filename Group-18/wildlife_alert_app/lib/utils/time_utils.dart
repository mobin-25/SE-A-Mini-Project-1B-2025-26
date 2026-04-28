import 'package:timeago/timeago.dart' as timeago;

class TimeUtils {
  static final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Returns a relative time string like "2 minutes ago".
  static String relative(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return timeago.format(date);
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Returns a full formatted date like "Apr 5, 2026 at 11:44 PM".
  static String full(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown';
    try {
      final d = DateTime.parse(isoString).toLocal();
      final month = _months[d.month - 1];
      final hour = d.hour > 12
          ? d.hour - 12
          : (d.hour == 0 ? 12 : d.hour);
      final minute = d.minute.toString().padLeft(2, '0');
      final ampm = d.hour >= 12 ? 'PM' : 'AM';
      return '$month ${d.day}, ${d.year} at $hour:$minute $ampm';
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Returns just the date portion like "Apr 5, 2026".
  static String date(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown';
    try {
      final d = DateTime.parse(isoString).toLocal();
      return '${_months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return 'Unknown';
    }
  }
}
