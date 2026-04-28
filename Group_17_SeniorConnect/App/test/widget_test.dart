import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_checkin_app/main.dart' as app;
import 'package:senior_checkin_app/services/firebase_service.dart';
import 'package:senior_checkin_app/services/auth_service.dart';

void main() {
  group('Firebase Storage Tests', () {
    test('Verify user data is stored in Firebase', () async {
      // Replace with an actual user ID that exists in your Firebase
      const String testUserId = 'YOUR_ACTUAL_USER_ID';

      // Check if user profile exists
      final bool exists = await FirebaseService.userProfileExists(testUserId);
      
      if (exists) {
        print('✓ User profile exists in Firebase');
        
        // Retrieve user data
        final userData = await FirebaseService.getUserProfile(testUserId);
        expect(userData, isNotNull, reason: 'User data should not be null');
        print('User data: $userData');
      } else {
        print('✗ User profile does NOT exist in Firebase');
        expect(exists, false, reason: 'No user data found');
      }
    });

    test('Verify check-in history is stored', () async {
      const String testUserId = 'YOUR_ACTUAL_USER_ID';

      // Get check-in history
      final history = await FirebaseService.getCheckInHistory(testUserId);
      
      if (history.isNotEmpty) {
        print('✓ Check-in history found: $history');
        expect(history, isNotEmpty, reason: 'Check-in history should not be empty');
      } else {
        print('✗ No check-in history found');
      }
    });
  });
}