import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_session_provider.dart';
import '../providers/order_profile_providers.dart';
import '../utils/app_error_message.dart';
import '../widgets/glass_card.dart';
import '../widgets/skeleton_box.dart';
import 'change_password_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: RefreshIndicator(
          onRefresh: () async {
            unawaited(ref.refresh(myProfileProvider.future));
            await Future<void>.delayed(const Duration(milliseconds: 100));
          },
          child: profileAsync.when(
            skipLoadingOnRefresh: false,
            loading: () => const _ProfileSkeleton(),
            error: (error, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    appErrorMessage(
                      error,
                      fallback: 'Unable to load profile right now. Please try again.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            data: (profile) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: const Color(0xFFE2E8F0),
                          backgroundImage: profile.profilePictureUrl != null
                              ? NetworkImage(profile.profilePictureUrl!)
                              : null,
                          child: profile.profilePictureUrl == null
                              ? const Icon(Icons.person_rounded, size: 36)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile.username,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(profile.email),
                        const SizedBox(height: 4),
                        Text(profile.mobileNumber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_reset_rounded,
                              color: Color(0xFFFF5A1F)),
                          title: const Text('Change Password'),
                          subtitle: const Text('Update your account password'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await ref.read(authSessionProvider.notifier).logout();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Logged out successfully')),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            children: [
              CircleAvatar(radius: 38, backgroundColor: Color(0xFFE5E7EB)),
              SizedBox(height: 12),
              SkeletonBox(height: 18, width: 140),
              SizedBox(height: 8),
              SkeletonBox(height: 14, width: 190),
              SizedBox(height: 6),
              SkeletonBox(height: 14, width: 120),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SkeletonBox(height: 24, width: 24),
                  SizedBox(width: 12),
                  SkeletonBox(height: 16, width: 150),
                ],
              ),
              SkeletonBox(height: 16, width: 16),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SkeletonBox(
            height: 44, borderRadius: BorderRadius.all(Radius.circular(14))),
      ],
    );
  }
}
