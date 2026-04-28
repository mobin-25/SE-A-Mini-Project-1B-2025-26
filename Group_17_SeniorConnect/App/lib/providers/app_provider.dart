import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class HealthProfile {
  final bool diabetes;
  final bool bp;
  final bool heart;
  final String? emergencyContact;
  final String? userName;
  final List<String> customConditions; // NEW: custom conditions list

  HealthProfile({
    this.diabetes        = false,
    this.bp              = false,
    this.heart           = false,
    this.emergencyContact,
    this.userName,
    this.customConditions = const [],
  });

  HealthProfile copyWith({
    bool?          diabetes,
    bool?          bp,
    bool?          heart,
    String?        emergencyContact,
    String?        userName,
    List<String>?  customConditions,
  }) => HealthProfile(
    diabetes:         diabetes         ?? this.diabetes,
    bp:               bp               ?? this.bp,
    heart:            heart            ?? this.heart,
    emergencyContact: emergencyContact ?? this.emergencyContact,
    userName:         userName         ?? this.userName,
    customConditions: customConditions ?? this.customConditions,
  );
}

class AppProvider extends ChangeNotifier {
  bool           isLoading      = true;
  String?        errorMessage;
  bool           onboardingDone = false;
  HealthProfile? profile;
  String?        userId;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingDone = prefs.getBool('onboarding_done') ?? false;
      if (onboardingDone) {
        if (!AuthService.isSignedIn) await AuthService.signInAnonymously();
        userId = AuthService.uid;
        await _loadProfile();
      }
    } catch (e) {
      errorMessage = 'Something went wrong. Please restart the app.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid   = userId;
    bool diabetes    = prefs.getBool('diabetes')          ?? false;
    bool bp          = prefs.getBool('bp')                ?? false;
    bool heart       = prefs.getBool('heart')             ?? false;
    String? contact  = prefs.getString('emergency_contact');
    String? userName = prefs.getString('user_name');
    List<String> customConditions = List<String>.from(prefs.getStringList('custom_conditions') ?? []);

    profile = HealthProfile(diabetes: diabetes, bp: bp, heart: heart,
        emergencyContact: contact, userName: userName, customConditions: customConditions);
    notifyListeners();

    if (uid != null) {
      final remote = await FirebaseService.getProfile(uid);
      if (remote != null) {
        diabetes = remote['diabetes'] ?? diabetes;
        bp       = remote['bp']       ?? bp;
        heart    = remote['heart']    ?? heart;
        contact  = remote['emergencyContact'] ?? contact;
        customConditions = List<String>.from(remote['customConditions'] ?? []);
        
        await prefs.setBool('diabetes', diabetes);
        await prefs.setBool('bp',       bp);
        await prefs.setBool('heart',    heart);
        if (contact != null) await prefs.setString('emergency_contact', contact);
        await prefs.setStringList('custom_conditions', customConditions);
        
        profile = HealthProfile(diabetes: diabetes, bp: bp, heart: heart,
            emergencyContact: contact, userName: userName, customConditions: customConditions);
        notifyListeners();
      }
    }
  }

  Future<void> completeOnboarding(String name) async {
    try {
      final uid = await AuthService.signInWithName(name);
      userId = uid;
      onboardingDone = true;
      profile = HealthProfile(userName: name);
      notifyListeners();
      
      if (uid != null) {
        print('🔐 User authenticated. UID: $uid');
        try {
          await FirebaseService.updateProfile(uid, {
            'userName': name,
            'createdAt': DateTime.now().toIso8601String(),
          });
          print('✅ Onboarding complete - user data saved to Firebase');
        } catch (firebaseError) {
          print('⚠️ Firebase save failed (local data saved): $firebaseError');
          errorMessage = 'Warning: Using offline mode. Data will sync when online.';
          notifyListeners();
        }
      } else {
        errorMessage = 'Authentication failed. Please try again.';
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error during onboarding: $e';
      debugPrint('Onboarding error: $e');
      notifyListeners();
    }
  }

  void updateHealth({required bool diabetes, required bool bp, required bool heart}) {
    profile = profile?.copyWith(diabetes: diabetes, bp: bp, heart: heart)
        ?? HealthProfile(diabetes: diabetes, bp: bp, heart: heart);
    notifyListeners();
  }

  void updateEmergencyContact(String contact) {
    profile = profile?.copyWith(emergencyContact: contact)
        ?? HealthProfile(emergencyContact: contact);
    notifyListeners();
  }

  Future<void> addCustomCondition(String condition) async {
    if (condition.trim().isEmpty) return;
    final updated = List<String>.from(profile?.customConditions ?? []);
    updated.add(condition.trim());
    profile = profile?.copyWith(customConditions: updated)
        ?? HealthProfile(customConditions: updated);
    notifyListeners();

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_conditions', updated);

    // Save to Firebase
    if (userId != null) {
      await FirebaseService.updateProfile(userId!, {
        'customConditions': updated,
      });
    }
  }

  Future<void> removeCustomCondition(String condition) async {
    final updated = List<String>.from(profile?.customConditions ?? []);
    updated.removeWhere((c) => c == condition);
    profile = profile?.copyWith(customConditions: updated)
        ?? HealthProfile(customConditions: updated);
    notifyListeners();

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_conditions', updated);

    // Save to Firebase
    if (userId != null) {
      await FirebaseService.updateProfile(userId!, {
        'customConditions': updated,
      });
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    onboardingDone = false;
    profile        = null;
    userId         = null;
    notifyListeners();
  }
  Future<void> onCheckInSaved(Map<String, dynamic> checkInData) async {
    try {
      if (userId != null) {
        final date = checkInData['date'] as String? ?? 
                     DateTime.now().toString().substring(0, 10);
        await FirebaseService.saveCheckIn(userId!, date);
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to save check-in. Please try again.';
      notifyListeners();
    }
  }
  List<dynamic> checkIns = [];

  Future<void> refreshCheckIns() async {
    try {
      if (userId != null) {
        final history = await FirebaseService.getCheckInHistory(userId!);
        checkIns = history.entries
            .map((e) => CheckInRecord(date: e.key, checkedIn: e.value))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to load check-in history.';
      notifyListeners();
    }
  }
}

class CheckInRecord {
  final String date;
  final bool checkedIn;

  CheckInRecord({required this.date, required this.checkedIn});
}