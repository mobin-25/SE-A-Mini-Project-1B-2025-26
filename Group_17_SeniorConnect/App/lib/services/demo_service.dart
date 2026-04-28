import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import '../models/emergency_contact_model.dart';
import '../providers/app_provider.dart';

class DemoService {
  static Future<void> populateDemoData(String uid) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();

    // 1. Set Health Profile & Local Prefs
    await FirebaseService.updateProfile(uid, {
      'userName': 'Demo Senior',
      'diabetes': true,
      'bp': false,
      'heart': true,
      'customConditions': ['Arthritis'],
      'emergencyContact': '+919876543210',
      'createdAt': now.toIso8601String(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('diabetes', true);
    await prefs.setBool('bp', false);
    await prefs.setBool('heart', true);
    await prefs.setStringList('custom_conditions', ['Arthritis']);
    await prefs.setString('user_name', 'Demo Senior');

    // 2. Set Emergency Contacts
    final contacts = [
      EmergencyContact(id: 'c1', name: 'Rahul Sharma', phone: '+91 9876543210', relation: 'Son'),
      EmergencyContact(id: 'c2', name: 'Dr. Vivek', phone: '+91 9123456780', relation: 'Doctor'),
    ];
    await prefs.setString('emergency_contacts_v2', json.encode(contacts.map((c) => c.toMap()).toList()));
    await FirebaseService.updateProfile(uid, {
      'emergencyContacts': contacts.map((c) => c.toMap()).toList()
    });

    // 3. Populate Check-ins (28 of the last 30 days)
    final checkinsCol = db.collection('users').doc(uid).collection('checkins');
    for (int i = 0; i < 30; i++) {
      // Missed days: 5, 12. Checked in other days.
      if (i == 5 || i == 12) continue;
      
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toString().substring(0, 10);
      
      // Also update local cache so frontend updates instantly
      await prefs.setBool(dateStr, true);
      
      checkinsCol.doc(dateStr).set({
        'date': dateStr,
        'checkedIn': true,
        'timestamp': Timestamp.fromDate(date.subtract(const Duration(hours: 3))), // 3 hours ago that day
      });
    }

    // 4. Populate Medication Logs
    final medsCol = db.collection('users').doc(uid).collection('medications');
    medsCol.add({
      'taken': true,
      'note': 'Morning meds',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      'date': now.toString().substring(0, 10),
    });
    medsCol.add({
      'taken': false,
      'note': 'Forgot evening pill',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 20))),
      'date': now.subtract(const Duration(days: 1)).toString().substring(0, 10),
    });
    medsCol.add({
      'taken': true,
      'note': 'Morning meds',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 26))),
      'date': now.subtract(const Duration(days: 1)).toString().substring(0, 10),
    });

    // 5. Populate Family Notes
    final notesCol = db.collection('users').doc(uid).collection('familyNotes');
    notesCol.add({
      'author': 'Rahul (Son)',
      'message': 'Dad, remember to take your new arthritis meds!',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
    });
    notesCol.add({
      'author': 'Priya (Daughter)',
      'message': 'Coming to visit you this weekend! ❤️',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1, hours: 2))),
    });
  }
}
