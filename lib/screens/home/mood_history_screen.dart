import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/mood_model.dart';
import '../../services/mood_service.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';

class MoodHistoryScreen extends ConsumerWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couple = ref.watch(coupleStreamProvider).value;
    final moodsAsync = ref.watch(moodsHistoryStreamProvider);
    final myUid = ref.watch(authServiceProvider).currentUser?.uid ?? '';
    
    if (couple == null) {
      return const Scaffold(body: Center(child: Text('Pair first to see mood history.')));
    }

    final partnerUid = couple.partnerUid(myUid);

    // Generate list of the past 30 days
    final List<DateTime> past30Days = List.generate(30, (index) {
      return DateTime.now().subtract(Duration(days: 29 - index));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗓️ Mood Heatmap'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: LoveSnapsColors.primary,
      ),
      body: moodsAsync.when(
        data: (moods) {
          // Group moods by date string and uid
          final Map<String, Map<String, String>> dailyMoodMap = {};
          
          for (final mood in moods) {
            dailyMoodMap.putIfAbsent(mood.date, () => {});
            dailyMoodMap[mood.date]![mood.uid] = mood.emoji;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and legend
                Text(
                  'Daily Mood Reflection',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LoveSnapsColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A calendar reflection of your mood bubbles over the past 30 days.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LoveSnapsColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Legend
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: LoveSnapsShadows.marshmallowShadowCard,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: LoveSnapsColors.primary)),
                          const SizedBox(width: 8),
                          const Text('You', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: LoveSnapsColors.secondary)),
                          const SizedBox(width: 8),
                          const Text('Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Heatmap Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 30,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final dayDate = past30Days[index];
                    final dateKey = DateFormat('yyyy-MM-dd').format(dayDate);
                    
                    final todayMoods = dailyMoodMap[dateKey] ?? {};
                    final myMood = todayMoods[myUid];
                    final partnerMood = todayMoods[partnerUid];
                    
                    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isToday ? LoveSnapsColors.primary : Colors.grey[200]!,
                          width: isToday ? 2.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('d').format(dayDate),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isToday ? LoveSnapsColors.primary : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // My Mood
                              _buildMiniMoodBubble(myMood, LoveSnapsColors.primaryContainer),
                              const SizedBox(width: 4),
                              // Partner Mood
                              _buildMiniMoodBubble(partnerMood, LoveSnapsColors.secondaryContainer),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: (index * 20).ms).scale(begin: const Offset(0.8, 0.8));
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load mood history: $err')),
      ),
    );
  }

  Widget _buildMiniMoodBubble(String? emoji, Color activeColor) {
    if (emoji == null || emoji.isEmpty) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: const Center(
          child: Text('—', style: TextStyle(fontSize: 8, color: Colors.grey)),
        ),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: activeColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}
