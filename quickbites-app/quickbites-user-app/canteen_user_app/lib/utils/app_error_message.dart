import '../services/api_client.dart';

String appErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is ApiException) {
    final message = error.message.trim();
    if (message.isNotEmpty) return message;
  }

  final raw = error.toString();
  final normalized = raw.toLowerCase();

  final isOffline =
      normalized.contains('socketexception') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('connection refused') ||
      normalized.contains('network is unreachable') ||
      normalized.contains('no address associated') ||
      normalized.contains('clientexception') && normalized.contains('connection') ||
      normalized.contains('timed out') ||
      normalized.contains('timeout');

  if (isOffline) {
    return 'No internet connection. Please check your network and try again.';
  }

  final cleaned = raw
      .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^ApiException\([^)]*\):\s*', caseSensitive: false), '')
      .trim();

  if (cleaned.isEmpty || cleaned == 'Exception') {
    return fallback;
  }

  return cleaned;
}
