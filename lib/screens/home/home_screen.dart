import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/couple_model.dart';
import '../../models/note_model.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/streak_service.dart';
import '../../services/location_service.dart';
import '../../services/widget_service.dart';
import '../../services/update_service.dart';
import '../../services/notification_service.dart';
import '../../services/note_service.dart';
import 'jam_screen.dart';
import 'memories_screen.dart';
import 'profile_screen.dart';
import '../../widgets/days_card.dart';
import '../../widgets/streak_card.dart';
import '../../widgets/distance_card.dart';
import '../../widgets/memory_card.dart';
import '../../models/snap_model.dart';
import '../../services/snap_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = 0;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    ref.read(widgetServiceProvider).registerWidgetClickCallback((uri) {
      if (WidgetService.isMissYouCallback(uri)) {
        _sendMissYou();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
      ref.read(notificationServiceProvider).initialize();
      _checkAndShowTour();

      _locationTimer = Timer.periodic(const Duration(minutes: 15), (_) {
        final couple = ref.read(coupleStreamProvider).value;
        if (couple != null) {
          ref.read(locationServiceProvider).updateMyLocation(couple.coupleId);
        }
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        final couple = ref.read(coupleStreamProvider).value;
        if (couple != null) {
          ref.read(locationServiceProvider).updateMyLocation(couple.coupleId);
        }
      });
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendMissYou() async {
    final couple = ref.read(coupleStreamProvider).value;
    if (couple == null) return;
    try {
      await ref.read(coupleServiceProvider).sendMissYou(couple.coupleId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('💕 Miss you sent!'),
          backgroundColor: LoveSnapsColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } catch (_) {}
  }

  Widget? _buildResurfacingCard(List<SnapModel> snaps, String myUid, CoupleModel couple) {
    if (snaps.isEmpty) return null;
    final now = DateTime.now();
    
    SnapModel? targetSnap;
    String timeLabel = '';
    
    for (final snap in snaps) {
      final diffDays = now.difference(snap.timestamp).inDays;
      if (diffDays >= 360 && diffDays <= 370) {
        targetSnap = snap;
        timeLabel = 'This time last year... ✨';
        break;
      }
    }
    
    if (targetSnap == null) {
      for (final snap in snaps) {
        final diffDays = now.difference(snap.timestamp).inDays;
        if (diffDays >= 28 && diffDays <= 32) {
          targetSnap = snap;
          timeLabel = 'This time last month... 🌸';
          break;
        }
      }
    }
    
    if (targetSnap == null) return null;
    
    final relationshipStart = couple.relationshipStartDate;
    int dayCount = 1;
    if (relationshipStart != null) {
      final start = DateTime(relationshipStart.year, relationshipStart.month, relationshipStart.day);
      final snapDate = DateTime(targetSnap.timestamp.year, targetSnap.timestamp.month, targetSnap.timestamp.day);
      dayCount = snapDate.difference(start).inDays + 1;
    }
    
    final finalSnap = targetSnap;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            final idx = snaps.indexOf(finalSnap);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SwipeableMemoriesViewer(
                  snaps: snaps,
                  initialIndex: idx,
                  myUid: myUid,
                  couple: couple,
                  ref: ref,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: LoveSnapsColors.pinkAccentDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day $dayCount together',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: LoveSnapsColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        finalSnap.caption.isNotEmpty ? '"${finalSnap.caption}"' : 'A cute memory 💕',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: finalSnap.imageUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(finalSnap.imageUrl.split(',').last),
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: finalSnap.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSection(CoupleModel couple, String myUid) {
    final partnerUid = couple.partnerUid(myUid);
    final myMood = couple.currentMoods[myUid];
    final partnerMood = couple.currentMoods[partnerUid];
    
    final moods = [
      {'emoji': '😊', 'label': 'Happy'},
      {'emoji': '🥰', 'label': 'Loved'},
      {'emoji': '😴', 'label': 'Tired'},
      {'emoji': '🥺', 'label': 'Soft'},
      {'emoji': '😢', 'label': 'Sad'},
      {'emoji': '😡', 'label': 'Angry'},
    ];

    if (myMood == null || myMood.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: LoveSnapsShadows.marshmallowShadowCard,
          border: Border.all(color: LoveSnapsColors.primaryContainer, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💭', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'How are you feeling today?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LoveSnapsColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: moods.map((m) {
                return GestureDetector(
                  onTap: () async {
                    try {
                      await ref.read(coupleServiceProvider).setMood(couple.coupleId, m['emoji']!);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Mood saved: ${m['emoji']} ${m['label']}! 🌟'),
                          backgroundColor: LoveSnapsColors.pinkAccent,
                        ),
                      );
                    } catch (e) {
                      debugPrint('Set mood failed: $e');
                    }
                  },
                  child: Column(
                    children: [
                      Text(m['emoji']!, style: const TextStyle(fontSize: 28))
                          .animate()
                          .scale(duration: 200.ms, curve: Curves.bounceOut),
                      const SizedBox(height: 4),
                      Text(
                        m['label']!,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black45),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: LoveSnapsColors.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Text('✨ Moods: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: LoveSnapsColors.primary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text('Me: $myMood', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    partnerMood != null && partnerMood.isNotEmpty
                        ? 'Partner: $partnerMood'
                        : 'Partner: ❓',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: LoveSnapsColors.primary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => context.push('/home/mood-history'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPromptCard(CoupleModel couple, String myUid, List<NoteModel> notes) {
    final partnerUid = couple.partnerUid(myUid);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final todayNotes = notes.where((n) => DateFormat('yyyy-MM-dd').format(n.timestamp) == todayStr).toList();
    final didIWriteToday = todayNotes.any((n) => n.senderId == myUid);
    final didPartnerWriteToday = todayNotes.any((n) => n.senderId == partnerUid);

    final prompts = [
      "What is one thing I did recently that made you smile? 😊",
      "If we could teleport anywhere right now, where would we go? ✈️",
      "What is your favorite memory of us from last month? 💖",
      "What is a song that reminds you of me, and why? 🎵",
      "What is a little habit of mine that you secretly love? 🥰",
      "Write down three things you are grateful for about us today. 🌸",
      "Describe our perfect date night in three sentences. 🥂",
    ];

    final promptIndex = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays % prompts.length;
    final todayPrompt = prompts[promptIndex];

    if (!didIWriteToday) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFDE68A), width: 2),
          boxShadow: LoveSnapsShadows.marshmallowShadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Daily Love Prompt',
                  style: TextStyle(
                    fontWeight: FontWeight.extrabold,
                    fontSize: 16,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              todayPrompt,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.amber[950],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showWriteNoteBottomSheet(couple.coupleId, todayPrompt),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[600],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Write Note ✍️', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (didIWriteToday && !didPartnerWriteToday) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
          boxShadow: LoveSnapsShadows.marshmallowShadowCard,
        ),
        child: Column(
          children: [
            const Text('📮', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'Your note is folded and waiting!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue[900]),
            ),
            const SizedBox(height: 6),
            Text(
              'We will unlock each other\'s notes as soon as your partner responds to today\'s prompt.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Column(
        children: [
          const Text('💌', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            'Both notes unlocked!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.emerald[900]),
          ),
          const SizedBox(height: 6),
          Text(
            'Taps are locked, check-ins are done! Tap below to open our Notes Jar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.emerald[700], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/home/notes-jar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.emerald[500],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Open Notes Jar 🏺', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showWriteNoteBottomSheet(String coupleId, String prompt) {
    final noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: LoveSnapsColors.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '✍️ Fold Today\'s Love Note',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: LoveSnapsColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              prompt,
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Write down something sweet...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 200,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final txt = noteController.text.trim();
                if (txt.isEmpty) return;
                
                try {
                  await ref.read(noteServiceProvider).sendNote(coupleId, prompt, txt);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note submitted and checked in! 💌')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Send Note 📮'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkAndShowTour() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_guided_tour') ?? false;
    if (seen) return;

    if (!mounted) return;
    _showTourBottomSheet();
  }

  void _showTourBottomSheet() {
    int slideIndex = 0;
    
    final slides = [
      {
        'title': 'Welcome to LoveSnaps! 👫',
        'emoji': '🌸',
        'text': 'A small shared world built just for the two of you. Let\'s take a 1-minute tour of your features!'
      },
      {
        'title': 'Daily Snaps & Polaroid Timeline',
        'emoji': '📸',
        'text': 'Capture and send daily snaps. They stack in a swipeable, pinch-to-zoom timeline that counts your days together.'
      },
      {
        'title': 'Daily Love Prompts & Notes Jar',
        'emoji': '📝',
        'text': 'Fold sweet handwritten notes by responding to daily prompts. Writing a note unlocks your partner\'s note!'
      },
      {
        'title': 'Real-Time Synced Jams',
        'emoji': '🎵',
        'text': 'Search JioSaavn, start a Jam, and listen in sync across locations with premium queue management!'
      },
      {
        'title': 'Streak & Mood Heatmaps',
        'emoji': '🗓️',
        'text': 'Check in daily to keep your streak flame alive, and reflect on your days with the mood heatmap calendar.'
      },
    ];

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final slide = slides[slideIndex];
          final isLast = slideIndex == slides.length - 1;

          return Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(slide['emoji']!, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  slide['title']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: LoveSnapsColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  slide['text']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(slides.length, (idx) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: slideIndex == idx ? 16 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: slideIndex == idx ? LoveSnapsColors.primary : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (isLast) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('seen_guided_tour', true);
                          if (context.mounted) Navigator.pop(context);
                        } else {
                          setModalState(() {
                            slideIndex++;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LoveSnapsColors.primary,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isLast ? 'Start! 💕' : 'Next ➡️'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkIn(CoupleModel couple) async {
    try {
      await ref.read(streakServiceProvider).checkIn(couple.coupleId);
      _syncWidgets(couple);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🔥 Checked in for today!'),
          backgroundColor: LoveSnapsColors.pinkAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _syncWidgets(CoupleModel couple) {
    final myUid = ref.read(authStateProvider).value?.uid ?? '';
    final locationService = ref.read(locationServiceProvider);
    final distanceKm = locationService.calculateDistance(couple, myUid);
    final distanceStr = couple.useManualDistance
        ? (couple.manualStatus == 'together' ? 'Together 💑' : 'Apart 💌')
        : locationService.formatDistance(distanceKm);

    final myCheckedIn = couple.hasCheckedIn(myUid);
    final partnerUid = couple.partnerUid(myUid);
    final partnerCheckedIn = couple.hasCheckedIn(partnerUid);
    final atRisk = ref.read(streakServiceProvider).isStreakAtRisk(
      myCheckedIn: myCheckedIn,
      partnerCheckedIn: partnerCheckedIn,
      lastUpdatedDate: couple.streakLastUpdatedDate,
    );

    final partnerName = 'Partner';
    final missYouReceived = couple.lastMissYouSentBy == partnerUid;

    ref.read(widgetServiceProvider).updateWidgets(
      coupleId: couple.coupleId,
      streakCount: couple.streakCount,
      daysCount: couple.daysTogetherCount,
      partnerName: partnerName,
      distance: distanceStr,
      manualStatus: couple.manualStatus,
      streakAtRisk: atRisk,
      missYouReceived: missYouReceived,
    );
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(coupleStreamProvider);
    final myUid = ref.watch(authStateProvider).value?.uid ?? '';

    return Scaffold(
      extendBody: true,
      backgroundColor: LoveSnapsColors.background,
      body: coupleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (couple) {
          if (couple == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💔', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('Not paired yet', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/pair'),
                    child: const Text('Pair with your partner'),
                  ),
                ],
              ),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) => _syncWidgets(couple));
          final snapsAsync = ref.watch(snapsStreamProvider);
          final notesAsync = ref.watch(notesStreamProvider);
          final notes = notesAsync.value ?? [];

          Widget getBody() {
            switch (_currentTab) {
              case 1:
                return JamScreen(couple: couple);
              case 2:
                return const MemoriesScreen();
              case 3:
                return const ProfileScreen();
              default:
                return CustomScrollView(
                  slivers: [
                    // Custom App Bar (Matches HTML header)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: LoveSnapsColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.mood_rounded, color: LoveSnapsColors.primary),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'LoveSnaps',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: LoveSnapsColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_rounded, color: LoveSnapsColors.primary),
                              onPressed: () => context.push('/home/chat'),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                              duration: 2.seconds,
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(1.05, 1.05),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (couple.isMilestoneDay)
                            _MilestoneBanner(days: couple.daysTogetherCount)
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: -0.5, end: 0),
                          if (couple.isMilestoneDay) const SizedBox(height: 16),

                          _buildMoodSection(couple, myUid),

                          // Day Counter Card
                          DaysCard(couple: couple)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 50.ms)
                              .slideY(begin: 0.15, end: 0),

                          const SizedBox(height: 16),

                          snapsAsync.when(
                            data: (snaps) {
                              final card = _buildResurfacingCard(snaps, myUid, couple);
                              return card ?? const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                          // Grid for Streak and Jam
                          Row(
                            children: [
                              Expanded(
                                child: StreakCard(
                                  couple: couple,
                                  onCheckIn: () => _checkIn(couple),
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 100.ms)
                                    .slideY(begin: 0.15, end: 0),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: LoveSnapsColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: LoveSnapsShadows.marshmallowShadowCard,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: () => setState(() => _currentTab = 1),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.music_note_rounded, color: LoveSnapsColors.secondary),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              (couple.currentJamTitle != null && couple.currentJamTitle!.isNotEmpty)
                                                  ? couple.currentJamTitle!
                                                  : 'Currently\nListening',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: LoveSnapsColors.onSecondaryContainer,
                                                fontWeight: FontWeight.w600,
                                                height: 1.2,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (couple.currentJamTitle != null && couple.currentJamTitle!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'by ${couple.currentJamArtist}',
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: LoveSnapsColors.secondary,
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ]
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.15, end: 0),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _buildDailyPromptCard(couple, myUid, notes),

                          // Distance Card
                          DistanceCard(
                            couple: couple,
                            myUid: myUid,
                            onMissYou: _sendMissYou,
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 200.ms)
                              .slideY(begin: 0.15, end: 0),

                          const SizedBox(height: 32),
                          
                          // Recent Snaps
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Recent Snaps', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: LoveSnapsColors.primary)),
                              Text('VIEW ALL', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LoveSnapsColors.secondary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            child: snapsAsync.when(
                              data: (snaps) {
                                return Row(
                                  children: [
                                    if (snaps.isEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: _buildSnapPlaceholder(
                                          'Capture a selfie!',
                                          '🤳',
                                          [const Color(0xFFFFD1DC), const Color(0xFFFFC0CB)],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: _buildSnapPlaceholder(
                                          'What are you eating?',
                                          '🍰',
                                          [const Color(0xFFFFF0C2), const Color(0xFFFFE599)],
                                        ),
                                      ),
                                    ] else
                                      ...snaps.map((snap) => Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: GestureDetector(
                                          onTap: () {
                                            final idx = snaps.indexOf(snap);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => SwipeableMemoriesViewer(
                                                  snaps: snaps,
                                                  initialIndex: idx,
                                                  myUid: myUid,
                                                  couple: couple,
                                                  ref: ref,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Hero(
                                            tag: 'polaroid_${snap.id}',
                                            child: _buildSnapCard(snap),
                                          ),
                                        ),
                                      )),
                                    // Add Snap button
                                    Container(
                                      width: 140,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        color: LoveSnapsColors.primaryContainer.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: LoveSnapsColors.primaryContainer, width: 2, style: BorderStyle.solid),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(24),
                                          onTap: () => _addSnap(couple.coupleId),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.add, color: LoveSnapsColors.primaryContainer),
                                              ),
                                              const SizedBox(height: 8),
                                              Text('Add Snap', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LoveSnapsColors.primaryContainer)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => Row(
                                children: List.generate(3, (index) => Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Container(
                                    width: 140,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                )),
                              ),
                              error: (err, _) => Text('Error loading snaps: $err'),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
            }
          }

          return SafeArea(
            bottom: false,
            child: getBody(),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Future<void> _addSnap(String coupleId) async {
    final snapService = ref.read(snapServiceProvider);
    final file = await snapService.capturePhoto();
    if (file == null) return;

    if (!mounted) return;
    
    // Show a dialog to get caption
    final captionController = TextEditingController();
    final caption = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('🌸 Add a Caption'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(
              hintText: 'What are you up to?',
            ),
            maxLength: 50,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, captionController.text),
              child: const Text('Post Snap'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text('Uploading snap...'),
          ],
        ),
        backgroundColor: LoveSnapsColors.primary,
        duration: const Duration(days: 1), // keeps visible until upload completes or fails
      ),
    );

    try {
      await snapService.uploadSnap(
        coupleId: coupleId,
        file: file,
        caption: caption ?? '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📸 Snap posted successfully!'),
          backgroundColor: LoveSnapsColors.pinkAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: LoveSnapsColors.error,
        ),
      );
    }
  }

  void _openFullImage(SnapModel snap, String myUid, String coupleId) {
    final canDelete = DateTime.now().difference(snap.timestamp).inMinutes < 10 && snap.senderId == myUid;

    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.9),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Hero(
                        tag: snap.id,
                        child: _buildImageWidget(snap.imageUrl),
                      ),
                    ),
                  ),
                  if (snap.caption.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.transparent,
                      child: Text(
                        snap.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: Text(
                      DateFormat('MMMM d, yyyy · h:mm a').format(snap.timestamp),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
              if (canDelete)
                Positioned(
                  top: 48,
                  right: 24,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Snap?'),
                              content: const Text('Are you sure you want to delete this snap? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ref.read(snapServiceProvider).deleteSnap(coupleId, snap.id);
                              if (context.mounted) {
                                Navigator.pop(context); // Close full preview
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📸 Snap deleted successfully!'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete snap: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Content = imageUrl.split(',').last;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Container(
          color: LoveSnapsColors.surfaceVariant,
          child: const Center(
            child: Icon(Icons.broken_image_rounded),
          ),
        );
      }
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: LoveSnapsColors.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: LoveSnapsColors.surfaceVariant,
          child: const Icon(Icons.error_outline),
        ),
      );
    }
  }

  Widget _buildSnapCard(SnapModel snap) {
    return Container(
      width: 140,
      height: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildImageWidget(snap.imageUrl),
          ),
          if (snap.caption.isNotEmpty)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  snap.caption,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSnapPlaceholder(String label, String emoji, List<Color> gradient) {
    return Container(
      width: 140,
      height: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: LoveSnapsColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: LoveSnapsShadows.marshmallowShadowBtn,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, isSelected: _currentTab == 0, onTap: () => setState(() => _currentTab = 0)),
              _NavItem(icon: Icons.music_note_rounded, isSelected: _currentTab == 1, onTap: () => setState(() => _currentTab = 1)),
              _NavItem(icon: Icons.auto_awesome_motion_rounded, isSelected: _currentTab == 2, onTap: () => setState(() => _currentTab = 2)),
              _NavItem(icon: Icons.person_rounded, isSelected: _currentTab == 3, onTap: () => setState(() => _currentTab = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? LoveSnapsColors.secondaryContainer : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? LoveSnapsColors.onSecondaryContainer : LoveSnapsColors.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}

class _MilestoneBanner extends StatelessWidget {
  final int days;
  const _MilestoneBanner({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: LoveSnapsColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milestone! Day $days',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: LoveSnapsColors.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Celebrate every moment together 💕',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LoveSnapsColors.onTertiaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextMilestoneHint extends StatelessWidget {
  final int current;
  final int next;
  const _NextMilestoneHint({required this.current, required this.next});

  @override
  Widget build(BuildContext context) {
    final remaining = next - current;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: LoveSnapsColors.secondaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: LoveSnapsColors.secondaryContainer),
        ),
        child: Text(
          '⭐ $remaining day${remaining == 1 ? '' : 's'} until Day $next',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: LoveSnapsColors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
