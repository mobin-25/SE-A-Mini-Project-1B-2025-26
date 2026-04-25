import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/cart_provider.dart';
import 'providers/auth_session_provider.dart';
import 'providers/home_providers.dart';
import 'providers/order_profile_providers.dart';
import 'providers/order_realtime_provider.dart';
import 'providers/service_providers.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'widgets/global_loading_overlay.dart';

void main() {
  runApp(const ProviderScope(child: CanteenUserApp()));
}

class CanteenUserApp extends StatelessWidget {
  const CanteenUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'APSIT Canteen',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5A1F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8F2),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF101828),
          centerTitle: false,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A1F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1F2937),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const GlobalLoadingOverlay(),
          ],
        );
      },
      home: const AppEntryScreen(),
    );
  }
}

class AppEntryScreen extends ConsumerStatefulWidget {
  const AppEntryScreen({super.key});

  @override
  ConsumerState<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends ConsumerState<AppEntryScreen> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _hadInternet = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initializeConnectivitySync();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeConnectivitySync() async {
    final initialResults = await _connectivity.checkConnectivity();
    _hadInternet = _hasInternet(initialResults);

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final hasInternet = _hasInternet(results);

      if (!_hadInternet && hasInternet) {
        unawaited(_syncAfterReconnect());
      }

      _hadInternet = hasInternet;
    });
  }

  bool _hasInternet(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _syncAfterReconnect() async {
    if (!mounted || _isSyncing) return;

    final isLoggedIn = ref.read(authSessionProvider).asData?.value ?? false;
    if (!isLoggedIn) return;

    _isSyncing = true;
    try {
      ref.invalidate(cartProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(myProfileProvider);

      ref.invalidate(allItemsProvider);
      ref.invalidate(filteredItemsProvider);
      ref.invalidate(instantReadyItemsProvider);

      await Future.wait([
        ref.read(itemsPaginationProvider.notifier).refresh(),
        ref.read(ordersPaginationProvider.notifier).refresh(),
      ]);

      await ref.read(orderUpdatesSocketServiceProvider).connect();
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(orderRealtimeLifecycleProvider);
    final authState = ref.watch(authSessionProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
      data: (isLoggedIn) =>
          isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
    );
  }
}
