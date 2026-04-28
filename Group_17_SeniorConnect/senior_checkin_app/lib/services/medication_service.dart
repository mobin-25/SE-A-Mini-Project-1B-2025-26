import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import 'auth_service.dart';

class MedicationService {
  static Future<void> saveLog(bool taken, String note) async {
    // 1. Save locally (works offline)
    final prefs = await SharedPreferences.getInstance();
    final logs  = prefs.getStringList('med_logs') ?? [];
    logs.add('${DateTime.now()} | ${taken ? 'Taken' : 'Missed'} | Note: $note');
    await prefs.setStringList('med_logs', logs);

    // 2. Sync to Firestore
    final uid = AuthService.uid;
    if (uid != null) await FirebaseService.saveMedicationLog(uid, taken, note);
  }

  static Future<List<String>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('med_logs') ?? [];
  }

  static Future<List<Map<String, dynamic>>> getCloudLogs() async {
    final uid = AuthService.uid;
    if (uid == null) return [];
    return FirebaseService.getMedicationLogs(uid);
  }
}