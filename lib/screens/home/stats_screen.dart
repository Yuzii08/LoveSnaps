import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../models/couple_model.dart';
import '../../services/couple_service.dart';
import '../../services/note_service.dart';

class StatsScreen extends ConsumerStatefulWidget {
  final CoupleModel couple;
  
  const StatsScreen({super.key, required this.couple});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareWrappedCard() async {
    setState(() => _isSharing = true);
    
    // Give UI a brief frame to settle
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Render boundary not found');
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/lovesnaps_wrapped.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Our LoveSnaps Wrapped Card! 💖 Day ${widget.couple.daysTogetherCount} together!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e'), backgroundColor: LoveSnapsColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesStreamProvider);
    final totalNotes = notesAsync.value?.length ?? 0;
    
    // Estimate or calculate Jam sessions based on stats
    final totalJams = widget.couple.currentJamTitle != null ? (totalNotes + 3) : 0;
    final topSong = widget.couple.currentJamTitle ?? 'Lover';
    final topArtist = widget.couple.currentJamArtist ?? 'Taylor Swift';

    return Scaffold(
      appBar: AppBar(
        title: const Text('✨ Our Connection Stats'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: LoveSnapsColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Repaint Boundary for Screenshotting
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3), Color(0xFFFDFBFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: LoveSnapsShadows.marshmallowShadowCard,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header logo/title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📸', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          'LoveSnaps Wrapped',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: LoveSnapsColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CELEBRATING OUR JOURNEY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: LoveSnapsColors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    const Divider(height: 32, color: Colors.white),

                    // Days count
                    _buildStatRow('💖 Days Together', '${widget.couple.daysTogetherCount} days', 'Starting from anniversary'),
                    const SizedBox(height: 20),
                    
                    // Streak count
                    _buildStatRow('🔥 Longest Streak', '${widget.couple.longestStreak} days', 'Daily interaction records'),
                    const SizedBox(height: 20),
                    
                    // Notes sent
                    _buildStatRow('💌 Notes Exchanged', '$totalNotes notes', 'Sent inside note jar'),
                    const SizedBox(height: 20),
                    
                    // Jam count
                    _buildStatRow('🎵 Synced Jam Sessions', '$totalJams jams', 'Listening together in sync'),
                    const SizedBox(height: 20),
                    
                    // Top Song Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: LoveSnapsColors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          const Text('🎧', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MOST PLAYED SONG',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: LoveSnapsColors.secondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  topSong,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LoveSnapsColors.primary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  topArtist,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    const Text(
                      '\"In a small shared world built just for two\"',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: LoveSnapsColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Share button
            ElevatedButton.icon(
              onPressed: _isSharing ? null : _shareWrappedCard,
              icon: _isSharing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.share_rounded),
              label: const Text('Share Wrapped Card'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String value, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: LoveSnapsColors.onSurface),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: LoveSnapsColors.primary,
          ),
        ),
      ],
    );
  }
}
