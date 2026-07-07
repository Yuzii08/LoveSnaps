import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/location_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loading = false;

  Future<void> _signOut() async {
    setState(() => _loading = true);
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(coupleStreamProvider);
    final userAsync = ref.watch(currentUserDocProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile section
          userAsync.when(
            data: (user) => _SectionCard(
              title: 'Your Profile',
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: LoveSnapsColors.primaryContainer,
                    child: Text(
                      (user?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: LoveSnapsColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(user?.displayName ?? '—'),
                  subtitle: Text(user?.email ?? '—'),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 16),

          // Couple section
          coupleAsync.when(
            data: (couple) {
              if (couple == null) return const SizedBox.shrink();
              return _SectionCard(
                title: 'Your Relationship',
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today_rounded),
                    title: const Text('Relationship start date'),
                    subtitle: Text(
                      couple.relationshipStartDate != null
                          ? '${couple.relationshipStartDate!.day}/${couple.relationshipStartDate!.month}/${couple.relationshipStartDate!.year}'
                          : 'Not set',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/start-date'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_rounded),
                    title: const Text('Couple ID'),
                    subtitle: Text(couple.coupleId),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.location_off_rounded),
                    title: const Text('Manual distance mode'),
                    subtitle: const Text(
                        'Use a simple together/apart toggle instead of GPS'),
                    value: couple.useManualDistance,
                    activeColor: LoveSnapsColors.primary,
                    onChanged: (val) async {
                      await ref
                          .read(coupleServiceProvider)
                          .setUseManualDistance(couple.coupleId, val);
                    },
                  ),
                  if (couple.useManualDistance)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'together',
                            label: Text('Together 💑'),
                            icon: Icon(Icons.favorite_rounded),
                          ),
                          ButtonSegment(
                            value: 'apart',
                            label: Text('Apart 💌'),
                            icon: Icon(Icons.airplanemode_active_rounded),
                          ),
                        ],
                        selected: {couple.manualStatus},
                        onSelectionChanged: (val) async {
                          await ref
                              .read(coupleServiceProvider)
                              .setManualStatus(couple.coupleId, val.first);
                        },
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor:
                              LoveSnapsColors.primaryContainer,
                          selectedForegroundColor: LoveSnapsColors.primary,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 16),

          // Danger zone
          _SectionCard(
            title: 'Account',
            children: [
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: LoveSnapsColors.error),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: LoveSnapsColors.error),
                ),
                onTap: _loading ? null : _signOut,
              ),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 32),

          const Center(
            child: Text(
              'LoveSnaps v1.0.0\nMade with 💕',
              textAlign: TextAlign.center,
              style: TextStyle(color: LoveSnapsColors.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LoveSnapsColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}
