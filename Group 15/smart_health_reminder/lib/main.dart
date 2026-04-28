// MEDITOUCH app entry point.
// Splash → Auth Gate → Onboarding (if first time) → Main app with bottom nav.
// Doctors/admins are routed to the admin shell instead.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/providers.dart';
import 'providers/admin_providers.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart' show AuthScreen, signUpWritesCompleter;
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/medicines_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/symptom_checker_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_appointments_screen.dart';
import 'screens/admin/admin_chat_screen.dart';
import 'screens/admin/admin_doctor_profile_screen.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'services/push_notification_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  await FcmService().init();
  runApp(const ProviderScope(child: MeditouchApp()));
}

class MeditouchApp extends StatelessWidget {
  const MeditouchApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEDITOUCH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _FadeScaleTransitionBuilder(),
            TargetPlatform.iOS: _FadeScaleTransitionBuilder(),
            TargetPlatform.windows: _FadeScaleTransitionBuilder(),
          },
        ),
      ),
      home: const AppEntry(),
    );
  }
}

/// Controls the app flow: splash → auth check → onboarding → main.
class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});
  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> {
  int _stage = 0; // 0 = splash, 1+ = auth gate

  void _onSplashDone() {
    if (mounted) setState(() => _stage = 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == 0) {
      return SplashScreen(onFinished: _onSplashDone);
    }
    // After splash, show auth gate
    return const _AuthGate();
  }
}

/// Listens to Firebase auth state — shows login or the main app.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const AuthScreen();
        // Save/refresh FCM token whenever user is authenticated
        FcmService().saveTokenToFirestore();
        return _AppLoader(key: ValueKey(user.uid));
      },
      loading:
          () => const Scaffold(
            backgroundColor: AppTheme.bgPrimary,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.electricBlue),
            ),
          ),
      error: (_, __) => const AuthScreen(),
    );
  }
}

/// Loads Firestore data then shows onboarding or main app.
class _AppLoader extends ConsumerStatefulWidget {
  const _AppLoader({super.key});
  @override
  ConsumerState<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends ConsumerState<_AppLoader> {
  bool _loaded = false;
  int _stage = 0; // 0 = loading, 1 = onboarding, 2 = main patient, 3 = admin

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // If a sign-up is in progress, wait for all Firestore writes to finish
    if (signUpWritesCompleter != null) {
      await signUpWritesCompleter!.future;
    }

    await ref.read(profileProvider.notifier).loadFromFirestore();
    var profile = ref.read(profileProvider);

    // Retry once if profile looks like default (race condition with sign-up)
    if (profile.name == 'User' && !profile.onboardingComplete) {
      await Future.delayed(const Duration(seconds: 2));
      await ref.read(profileProvider.notifier).loadFromFirestore();
      profile = ref.read(profileProvider);
    }

    if (profile.isDoctor) {
      // Load admin-specific data for doctors
      await Future.wait([
        ref.read(adminAppointmentsProvider.notifier).loadFromFirestore(),
        ref.read(prescriptionsProvider.notifier).loadFromFirestore(),
        ref.read(doctorProfileProvider.notifier).loadFromFirestore(),
        ref.read(adminNotificationsProvider.notifier).loadFromFirestore(),
      ]);
    } else {
      // Load patient data
      await Future.wait([
        ref.read(medicinesProvider.notifier).loadFromFirestore(),
        ref.read(appointmentsProvider.notifier).loadFromFirestore(),
        ref.read(checkInProvider.notifier).loadFromFirestore(),
      ]);
    }

    // Start listening for real-time push notifications (both patient & doctor)
    PushNotificationListener().startListening();

    if (mounted) {
      setState(() {
        _loaded = true;
        if (profile.isDoctor) {
          _stage = 3; // admin/doctor portal
        } else if (profile.onboardingComplete) {
          _stage = 2; // patient main app
        } else {
          _stage = 1; // onboarding
        }
      });
    }
  }

  void _onOnboardingDone() {
    setState(() => _stage = 2);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.electricBlue),
        ),
      );
    }
    if (_stage == 1) {
      return OnboardingScreen(onComplete: _onOnboardingDone);
    }
    if (_stage == 3) {
      return const AdminShell();
    }
    return const AppShell();
  }
}

/// Main navigation shell with glassmorphic BottomNavigationBar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = [
    HomeScreen(),
    MedicinesScreen(),
    SymptomCheckerScreen(),
    AppointmentsScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.medication_rounded, Icons.medication_outlined, 'Medicines'),
    _NavItem(Icons.favorite_rounded, Icons.favorite_outline, 'Diagnose'),
    _NavItem(
      Icons.calendar_month_rounded,
      Icons.calendar_month_outlined,
      'Appts',
    ),
    _NavItem(Icons.person_rounded, Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: currentTab, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(
            0xE6181A20,
          ), // 90% bgPrimary — opaque enough without blur
          border: const Border(
            top: BorderSide(color: AppTheme.glassBorder, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.radiantPink.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = currentTab == i;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ref.read(currentTabProvider.notifier).state = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? AppTheme.radiantPink.withValues(alpha: 0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color:
                            selected
                                ? AppTheme.radiantPink
                                : AppTheme.textSecondary,
                        size: 24,
                        shadows:
                            selected
                                ? [
                                  Shadow(
                                    color: AppTheme.radiantPink.withValues(
                                      alpha: 0.6,
                                    ),
                                    blurRadius: 16,
                                  ),
                                ]
                                : null,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              selected
                                  ? AppTheme.radiantPink
                                  : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

/// Admin / Doctor navigation shell with 5-tab bottom nav.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static const _screens = [
    AdminDashboardScreen(),
    AdminAppointmentsScreen(),
    AdminChatScreen(),
    AdminDoctorProfileScreen(),
  ];

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
    _NavItem(
      Icons.calendar_month_rounded,
      Icons.calendar_month_outlined,
      'Appts',
    ),
    _NavItem(Icons.chat_rounded, Icons.chat_outlined, 'Chat'),
    _NavItem(Icons.person_rounded, Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(adminTabProvider);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: currentTab, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xE6181A20),
          border: const Border(
            top: BorderSide(color: AppTheme.glassBorder, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.radiantPink.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = currentTab == i;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ref.read(adminTabProvider.notifier).state = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? AppTheme.radiantPink.withValues(alpha: 0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color:
                            selected
                                ? AppTheme.radiantPink
                                : AppTheme.textSecondary,
                        size: 24,
                        shadows:
                            selected
                                ? [
                                  Shadow(
                                    color: AppTheme.radiantPink.withValues(
                                      alpha: 0.6,
                                    ),
                                    blurRadius: 16,
                                  ),
                                ]
                                : null,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              selected
                                  ? AppTheme.radiantPink
                                  : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Custom page transition: fade + subtle scale for a modern sci-fi feel.
class _FadeScaleTransitionBuilder extends PageTransitionsBuilder {
  const _FadeScaleTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}
