import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDocProvider);
    final coupleAsync = ref.watch(coupleStreamProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: LoveSnapsColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Manage your connection and account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LoveSnapsColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),

                // Profiles Bento Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: LoveSnapsShadows.marshmallowShadowCard,
                  ),
                  child: userAsync.when(
                    data: (user) {
                      if (user == null)
                        return const Text('Loading user data...');
                      return Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor:
                                    LoveSnapsColors.primaryContainer,
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: LoveSnapsColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        color: LoveSnapsColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          coupleAsync.when(
                            data: (couple) {
                              if (couple == null)
                                return const SizedBox.shrink();
                              return Row(
                                children: [
                                  const Icon(Icons.favorite_rounded,
                                      color: LoveSnapsColors.pinkAccent),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Couple ID: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: LoveSnapsColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    couple.coupleId,
                                    style: const TextStyle(
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.bold,
                                      color: LoveSnapsColors.primary,
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error: $err'),
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Anniversary Settings Card
                coupleAsync
                    .when(
                      data: (couple) {
                        if (couple == null) return const SizedBox.shrink();
                        final hasStartDate =
                            couple.relationshipStartDate != null;
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: LoveSnapsColors.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: LoveSnapsColors.primaryContainer,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('📅', style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Anniversary Date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hasStartDate
                                          ? DateFormat('MMMM d, yyyy').format(
                                              couple.relationshipStartDate!)
                                          : 'Not set yet',
                                      style: const TextStyle(
                                        color: LoveSnapsColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_calendar_rounded,
                                    color: LoveSnapsColors.primary),
                                onPressed: () => context.push('/start-date'),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    )
                    .animate(delay: 100.ms)
                    .fadeIn(),

                const SizedBox(height: 32),

                // Settings & Sign Out Buttons
                GestureDetector(
                  onTap: () => context.push('/home/settings'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: LoveSnapsShadows.marshmallowShadowCard,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.settings_rounded,
                            color: LoveSnapsColors.onSurfaceVariant),
                        SizedBox(width: 16),
                        Text(
                          'Additional Settings',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            color: LoveSnapsColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (!context.mounted) return;
                    context.go('/auth');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red[100]!, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.red[400]),
                        const SizedBox(width: 12),
                        Text(
                          'SIGN OUT',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 250.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
