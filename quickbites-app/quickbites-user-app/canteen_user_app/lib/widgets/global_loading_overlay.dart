import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/transaction_provider.dart';
import 'skeleton_visibility_registry.dart';

class GlobalLoadingOverlay extends ConsumerWidget {
  const GlobalLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(isTransactionInProgressProvider);
    if (!isBusy) return const SizedBox.shrink();

    return ValueListenableBuilder<int>(
      valueListenable: skeletonVisibilityCounter,
      builder: (context, visibleCount, _) {
        if (visibleCount > 0) {
          return const SizedBox.shrink();
        }

        return Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
