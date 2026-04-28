import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import '../services/health_api_service.dart';
import '../services/health_alert_service.dart';
import '../services/notification_service.dart';
import '../services/medication_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/checkin_model.dart';
import '../models/emergency_contact_model.dart';
import '../providers/app_provider.dart';
import '../main.dart' show mainShellKey;

const kPrimary  = Color(0xFF2D7DD2);
const kSuccess  = Color(0xFF27AE60);
const kDanger   = Color(0xFFE74C3C);
const kWarning  = Color(0xFFF39C12);
const kPurple   = Color(0xFF8E44AD);
const kTeal     = Color(0xFF16A085);
const kBg       = Color(0xFFF5F7FA);
const kCard     = Colors.white;
const kTextDark = Color(0xFF1A2535);
const kTextGrey = Color(0xFF7F8C9A);

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with SingleTickerProviderStateMixin {
  bool isCheckedIn = false;
  double fontSize = 18;
  bool _isListening = false;
  bool _isSendingSOS = false;
  TimeOfDay? _savedReminderTime;   // ← track the saved reminder time

  // Health alert
  HealthAlert? _healthAlert;
  bool _alertLoading = true;
  bool _alertDismissed = false;

  final FlutterTts tts = FlutterTts();
  final SpeechToText speech = SpeechToText();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    loadTodayStatus();
    loadSavedReminder();
    _loadSavedReminderTime();
    _fetchHealthAlert();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future speak(String text) async {
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.5);
    await tts.speak(text);
  }

  // ─────────────────────────────────────────────────────────────────
  // VOICE COMMAND — listens and navigates / triggers features
  // ─────────────────────────────────────────────────────────────────
  Future<void> startListening() async {
    bool available = await speech.initialize(
      onError: (e) => setState(() => _isListening = false),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone not available')),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    await speak("Listening. Say a command.");

    speech.listen(
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) async {
        if (!result.finalResult) return;
        final cmd = result.recognizedWords.toLowerCase().trim();
        setState(() => _isListening = false);
        await _handleVoiceCommand(cmd);
      },
    );
  }

  Future<void> _handleVoiceCommand(String cmd) async {
    debugPrint('🎤 Voice command: $cmd');

    // ── SOS / emergency ─────────────────────────────────────────────
    if (cmd.contains('sos') ||
        cmd.contains('help') ||
        cmd.contains('emergency') ||
        cmd.contains('danger')) {
      await speak("Sending emergency SOS");
      await emergencyCall();
      return;
    }

    // ── I'm okay / check in ─────────────────────────────────────────
    if (cmd.contains('okay') ||
        cmd.contains('ok') ||
        cmd.contains('fine') ||
        cmd.contains('safe') ||
        cmd.contains('check in')) {
      await speak("Marking you as safe");
      await checkIn();
      return;
    }

    // ── Medicine / medication ────────────────────────────────────────
    if (cmd.contains('medicine') ||
        cmd.contains('medication') ||
        cmd.contains('pill') ||
        cmd.contains('tablet')) {
      await speak("Opening medication check");
      showMedicationDialog();
      return;
    }

    // ── Navigation: History ─────────────────────────────────────────
    if (cmd.contains('history') || cmd.contains('past')) {
      await speak("Going to History");
      mainShellKey.currentState?.navigateTo(1);
      return;
    }

    // ── Navigation: Health ──────────────────────────────────────────
    if (cmd.contains('health') ||
        cmd.contains('profile') ||
        cmd.contains('condition')) {
      await speak("Going to Health Profile");
      mainShellKey.currentState?.navigateTo(2);
      return;
    }

    // ── Navigation: Contacts ─────────────────────────────────────────
    if (cmd.contains('contact') ||
        cmd.contains('contacts') ||
        cmd.contains('emergency contact')) {
      await speak("Going to Contacts");
      mainShellKey.currentState?.navigateTo(3);
      return;
    }

    // ── Navigation: Family ───────────────────────────────────────────
    if (cmd.contains('family') || cmd.contains('relatives')) {
      await speak("Going to Family view");
      mainShellKey.currentState?.navigateTo(4);
      return;
    }

    // ── Navigate home / check-in tab ─────────────────────────────────
    if (cmd.contains('home') || cmd.contains('back')) {
      await speak("Going home");
      mainShellKey.currentState?.navigateTo(0);
      return;
    }

    // ── Call family ──────────────────────────────────────────────────
    if (cmd.contains('call') || cmd.contains('phone')) {
      await speak("Calling your family");
      await callNow();
      return;
    }

    // ── Reminder ─────────────────────────────────────────────────────
    if (cmd.contains('reminder') || cmd.contains('alarm')) {
      await speak("Opening reminder settings");
      await pickMedicationTime();
      return;
    }

    // ── Unrecognised ─────────────────────────────────────────────────
    await speak(
      "Sorry, I didn't understand. Say: okay, SOS, medicine, history, health, contacts, family, call, or reminder.",
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: kTextGrey,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Heard: "$cmd"',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Try: okay • SOS • medicine • history • health • contacts • family • call • reminder',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // LOAD DATA
  // ─────────────────────────────────────────────────────────────────
  Future<void> loadTodayStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    setState(() => isCheckedIn = prefs.getBool(today) ?? false);
  }

  // ─────────────────────────────────────────────────────────────────
  // CHECK-IN  →  mark safe + SMS all contacts
  // ─────────────────────────────────────────────────────────────────
  Future<void> checkIn() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    await prefs.setBool(today, true);

    // Save to Firebase
    final uid = AuthService.uid;
    if (uid != null) {
      await FirebaseService.saveCheckIn(uid, today);
      if (mounted) {
        context.read<AppProvider>().onCheckInSaved({
          'date': today,
          'checkedIn': true,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }

    setState(() => isCheckedIn = true);
    await speak("You are marked safe");

    // ── Notify all emergency contacts via SMS ────────────────────────
    final contacts = await _loadAllContacts();
    if (contacts.isNotEmpty) {
      final name = prefs.getString('user_name') ?? 'Your loved one';
      final msg =
          'SeniorCare: $name has checked in and is safe! (${DateTime.now().toString().substring(0, 16)})';
      await _sendSmsToAll(contacts, msg);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: kSuccess,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                contacts.isNotEmpty
                    ? "You're safe ❤️  •  ${contacts.length} contact(s) notified via SMS"
                    : "You are marked safe ❤️",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────
  Future<List<EmergencyContact>> _loadAllContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('emergency_contacts_v2');
    if (raw != null) {
      try {
        return (json.decode(raw) as List)
            .map((e) => EmergencyContact.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    // Legacy fallback
    final legacy = prefs.getString('emergency_contact');
    if (legacy != null && legacy.isNotEmpty) {
      return [EmergencyContact(id: '0', name: 'Emergency Contact', phone: legacy)];
    }
    return [];
  }

  /// Send SMS programmatically without opening the SMS app on Android
  Future<void> _sendSmsToAll(List<EmergencyContact> contacts, String msg) async {
    // Only attempt background SMS if we're on Android
    if (Platform.isAndroid) {
      final status = await Permission.sms.request();
      if (status.isGranted) {
        const platform = MethodChannel('com.seniorcare/sms');
        for (final c in contacts) {
          try {
            // Strong formatting guard for native APIs
            final cleanPhone = c.phone.replaceAll(RegExp(r'[^\d+]'), '');
            
            // Trigger native Kotlin execution in MainActivity
            final result = await platform.invokeMethod('sendSMS', {
              'phone': cleanPhone,
              'msg': msg,
            });
            debugPrint('Background SMS to ${c.name}: $result');
          } catch (e) {
            debugPrint('SMS failed for ${c.name}: $e');
          }
        }
        return; // Successfully sent in background, skip fallback
      }
    }

    // Fallback: For iOS, or if Android user denies background SMS permission
    for (final c in contacts) {
      final uri = Uri(
        scheme: 'sms',
        path: c.phone,
        queryParameters: {'body': msg},
      );
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }


  // ─────────────────────────────────────────────────────────────────
  // CALL NOW — direct call, no app redirect
  // ─────────────────────────────────────────────────────────────────
  Future<void> callNow() async {
    final contacts = await _loadAllContacts();
    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No emergency contacts set. Go to Contacts tab.'),
            backgroundColor: kWarning,
          ),
        );
      }
      return;
    }
    await _directCall(contacts.first.phone);
  }

  /// Places a call directly without opening the dialler UI
  Future<void> _directCall(String phone) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(phone);
    } catch (_) {
      // Fallback to url_launcher if permission denied
      await launchUrl(Uri(scheme: 'tel', path: phone));
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // EMERGENCY CALL — SOS: SMS all + direct call primary
  // ─────────────────────────────────────────────────────────────────
  Future<void> emergencyCall() async {
    final contacts = await _loadAllContacts();
    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No emergency contacts set! Please add one first.'),
            backgroundColor: kDanger,
          ),
        );
      }
      return;
    }

    setState(() => _isSendingSOS = true);

    try {
      // Check and request location permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      String mapsLink = "";
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        // Get location safely if permitted
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        mapsLink = 'My live location: https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
      } else {
        mapsLink = 'Location could not be retrieved.';
      }

      final msg =
          'SOS! I need immediate help! $mapsLink (SeniorCare Emergency)';

      // Send SMS directly to ALL contacts
      await _sendSmsToAll(contacts, msg);

      // Call primary contact directly
      await speak('Emergency alert sent. Calling ${contacts.first.name}.');
      
      // Add a 2.5-second buffer to guarantee the SMS intents hit the OS before the Call Dialer takes over the screen and pauses the app.
      await Future.delayed(const Duration(milliseconds: 2500));
      await _directCall(contacts.first.phone);
    } catch (e) {
      // Location failed — still send SOS without location
      const msg =
          'SOS! I need immediate help! Please call me back immediately. (SeniorCare Emergency)';
      await _sendSmsToAll(contacts, msg);
      await speak('Emergency alert sent');
      
      await Future.delayed(const Duration(milliseconds: 2500));
      await _directCall(contacts.first.phone);
    } finally {
      if (mounted) setState(() => _isSendingSOS = false);
    }
  }

  Future<void> _fetchHealthAlert() async {
    if (!mounted) return;
    setState(() => _alertLoading = true);
    try {
      final alert = await HealthAlertService.getAlert();
      if (mounted) setState(() { _healthAlert = alert; _alertLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _alertLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────────────────────────
  void showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: kDanger.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: kDanger, size: 36),
              ),
              const SizedBox(height: 16),
              const Text("Emergency Alert",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextDark)),
              const SizedBox(height: 8),
              const Text(
                "This will DIRECTLY call your primary contact and SEND an SOS SMS with your live location to ALL contacts.",
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextGrey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () { Navigator.pop(context); emergencyCall(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDanger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text("SEND SOS", style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showMedicationDialog() {
    String note = "";
    speak("Did you take your medicine?");
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: kPurple.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.medication_rounded, color: kPurple, size: 36),
              ),
              const SizedBox(height: 16),
              const Text("Medication Check",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextDark)),
              const SizedBox(height: 8),
              const Text("Did you take your medicine today?",
                  textAlign: TextAlign.center, style: TextStyle(color: kTextGrey)),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => note = v,
                decoration: InputDecoration(
                  hintText: "Add a note (optional)",
                  filled: true,
                  fillColor: kBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await MedicationService.saveLog(false, note);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kDanger),
                        foregroundColor: kDanger,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Not Yet", style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await MedicationService.saveLog(true, note);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text("Yes, Taken ✓",
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // REMINDER
  // ─────────────────────────────────────────────────────────────────
  Future<void> pickMedicationTime() async {
    // Request notification permission first (Android 13+)
    await NotificationService.requestNotificationsPermission();

    if (!mounted) return;
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('med_hour', picked.hour);
      await prefs.setInt('med_min', picked.minute);
      await NotificationService.scheduleDaily(picked.hour, picked.minute);
      setState(() => _savedReminderTime = picked);  // ← update UI card

      if (!mounted) return;
      final formattedTime = picked.format(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: kPurple,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.alarm_on_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '💊 Medication reminder set for $formattedTime daily',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> loadSavedReminder() async {
    final prefs = await SharedPreferences.getInstance();
    int? h = prefs.getInt('med_hour');
    int? m = prefs.getInt('med_min');
    if (h != null && m != null) await NotificationService.scheduleDaily(h, m);
  }

  Future<void> _loadSavedReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt('med_hour');
    final m = prefs.getInt('med_min');
    if (h != null && m != null && mounted) {
      setState(() => _savedReminderTime = TimeOfDay(hour: h, minute: m));
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? "Good Morning"
        : now.hour < 17
            ? "Good Afternoon"
            : "Good Evening";

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Header ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting,
                                style: const TextStyle(
                                    fontSize: 14, color: kTextGrey, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            const Text("SeniorCare",
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w900, color: kTextDark)),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
                          ],
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.text_decrease_rounded, size: 20),
                              onPressed: () =>
                                  setState(() => fontSize = (fontSize - 2).clamp(14, 28)),
                            ),
                            const Text("A", style: TextStyle(fontWeight: FontWeight.w700)),
                            IconButton(
                              icon: const Icon(Icons.text_increase_rounded, size: 20),
                              onPressed: () =>
                                  setState(() => fontSize = (fontSize + 2).clamp(14, 28)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Health Alert Banner ──────────────────────────────
                  if (!_alertDismissed)
                    _HealthAlertBanner(
                      alert: _healthAlert,
                      isLoading: _alertLoading,
                      onDismiss: () => setState(() => _alertDismissed = true),
                      onRefresh: _fetchHealthAlert,
                    ),

                  const SizedBox(height: 16),

                  // ── Status / Check-In Card ───────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCheckedIn
                            ? [const Color(0xFF27AE60), const Color(0xFF2ECC71)]
                            : [const Color(0xFF2D7DD2), const Color(0xFF5BA4E8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: (isCheckedIn ? kSuccess : kPrimary).withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Icon(
                            isCheckedIn
                                ? Icons.check_circle_rounded
                                : Icons.favorite_rounded,
                            key: ValueKey(isCheckedIn),
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isCheckedIn ? "You're Safe Today!" : "Ready to Check In?",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCheckedIn
                              ? "✅ Your family has been notified via SMS ❤️"
                              : "Tap below to let your family know you're okay",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        if (!isCheckedIn) ...[
                          const SizedBox(height: 20),
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: checkIn,
                                icon: const Icon(Icons.favorite_rounded, size: 22),
                                label: Text(
                                  "I'M OKAY",
                                  style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: kSuccess,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── SOS Button ───────────────────────────────────────
                  GestureDetector(
                    onTap: showEmergencyDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE74C3C), Color(0xFFFF6B6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: kDanger.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.sos_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "SOS Emergency",
                            style: TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "SMS all contacts + direct call",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Call Now ─────────────────────────────────────────
                  _BigActionButton(
                    icon: Icons.phone_rounded,
                    label: "Call Family Now",
                    subtitle: "Direct call — no dialler needed",
                    color: kWarning,
                    fontSize: fontSize,
                    onTap: callNow,
                  ),

                  const SizedBox(height: 28),

                  // ── Quick Actions ─────────────────────────────────────
                  const Text("Quick Actions",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _QuickCard(
                        icon: Icons.medication_rounded,
                        label: "Medication",
                        color: kPurple,
                        onTap: () async {
                          await NotificationService.showReminder();
                          await speak("Time to take your medicine");
                          showMedicationDialog();
                        },
                      ),
                      _QuickCard(
                        icon: _isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        label: _isListening ? "Listening..." : "Voice Command",
                        color: kTeal,
                        onTap: startListening,
                      ),
                      _QuickCard(
                        icon: Icons.alarm_rounded,
                        label: "Set Reminder",
                        color: const Color(0xFF2980B9),
                        subtitle: _savedReminderTime != null
                            ? _savedReminderTime!.format(context)
                            : null,
                        onTap: pickMedicationTime,
                      ),
                      _QuickCard(
                        icon: Icons.info_outline_rounded,
                        label: "Voice Tips",
                        color: const Color(0xFF7F8C8D),
                        onTap: () => speak(
                          "Say: okay to check in, SOS for emergency, medicine for medication, history, health, contacts, family, call, or reminder.",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── SOS sending overlay ───────────────────────────────────
          if (_isSendingSOS)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: kDanger, strokeWidth: 3),
                    SizedBox(height: 16),
                    Text(
                      "Sending SOS...",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Getting your location & notifying contacts",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // ── Voice listening indicator ─────────────────────────────
          if (_isListening)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: kTeal,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: kTeal.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6)),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Listening...",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          Text(
                            "Say: okay • SOS • medicine • history • health • contacts • family • call",
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final double fontSize;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: fontSize - 2,
                          fontWeight: FontWeight.w800,
                          color: kTextDark)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextGrey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;   // optional
  final Color color;
  final VoidCallback onTap;

  const _QuickCard(
      {required this.icon, required this.label, required this.color, required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
            if (subtitle != null)
              Text(subtitle!,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Health Alert Banner ───────────────────────────────────────────────────────

class _HealthAlertBanner extends StatelessWidget {
  final HealthAlert? alert;
  final bool isLoading;
  final VoidCallback onDismiss;
  final VoidCallback onRefresh;

  const _HealthAlertBanner({
    required this.alert,
    required this.isLoading,
    required this.onDismiss,
    required this.onRefresh,
  });

  (Color bg, Color border, Color text, IconData icon) _theme(RiskLevel r) {
    switch (r) {
      case RiskLevel.low:
        return (const Color(0xFFE8F8EF), const Color(0xFF27AE60), const Color(0xFF1A6B3C),
            Icons.shield_rounded);
      case RiskLevel.medium:
        return (const Color(0xFFFFF8E1), const Color(0xFFF39C12), const Color(0xFF7A5000),
            Icons.warning_amber_rounded);
      case RiskLevel.high:
        return (const Color(0xFFFFECEC), const Color(0xFFE74C3C), const Color(0xFF8B1A1A),
            Icons.coronavirus_rounded);
      case RiskLevel.critical:
        return (const Color(0xFFF9E9E9), const Color(0xFF8E1111), const Color(0xFF5C0A0A),
            Icons.emergency_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))
          ],
        ),
        child: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary)),
            SizedBox(width: 14),
            Expanded(
              child: Text('Fetching live health alert for your area…',
                  style: TextStyle(fontSize: 13, color: kTextGrey, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
    }

    if (alert == null) return const SizedBox.shrink();

    final (bg, border, textColor, iconData) = _theme(alert!.riskLevel);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: border.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: border.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(iconData, color: border, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(6)),
                            child: Text(alert!.riskLabel.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8)),
                          ),
                          const SizedBox(width: 8),
                          Text(alert!.cityName,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: textColor.withOpacity(0.7),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(alert!.title,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 3),
                      Text(alert!.message,
                          style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.85), height: 1.4)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 18, color: textColor.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ),
          if (alert!.recommendations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: border.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: border, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('💡 Stay Safe: ${alert!.recommendations.first}',
                          style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: textColor.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text('Updated ${_timeAgo(alert!.fetchedAt)}',
                    style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.5))),
                const Spacer(),
                GestureDetector(
                  onTap: onRefresh,
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: border),
                      const SizedBox(width: 4),
                      Text('Refresh',
                          style: TextStyle(fontSize: 11, color: border, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}