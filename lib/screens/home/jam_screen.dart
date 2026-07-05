import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme.dart';
import '../../models/couple_model.dart';
import '../../services/couple_service.dart';
import '../../services/auth_service.dart';

class JamScreen extends ConsumerStatefulWidget {
  final CoupleModel couple;

  const JamScreen({super.key, required this.couple});

  @override
  ConsumerState<JamScreen> createState() => _JamScreenState();
}

class _JamScreenState extends ConsumerState<JamScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    // Start rotating if someone is playing music
    if (widget.couple.currentJamTitle != null && widget.couple.currentJamTitle!.isNotEmpty) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(JamScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasMusic = widget.couple.currentJamTitle != null && widget.couple.currentJamTitle!.isNotEmpty;
    if (hasMusic && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!hasMusic && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _updateJam() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    if (title.isEmpty || artist.isEmpty) return;

    try {
      await ref.read(coupleServiceProvider).shareJam(
        widget.couple.coupleId,
        title,
        artist,
      );
      if (!mounted) return;
      _titleController.clear();
      _artistController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎵 Posted your current jam!'),
          backgroundColor: LoveSnapsColors.pinkAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: $e'),
          backgroundColor: LoveSnapsColors.error,
        ),
      );
    }
  }

  void _showUpdateJamDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('🎵 What are you listening to?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Song Title',
                  hintText: 'e.g. As It Was',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _artistController,
                decoration: const InputDecoration(
                  labelText: 'Artist',
                  hintText: 'e.g. Harry Styles',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _updateJam,
              child: const Text('Share Jam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authStateProvider).value?.uid ?? '';
    final hasJam = widget.couple.currentJamTitle != null && widget.couple.currentJamTitle!.isNotEmpty;
    
    final isSharedByMe = widget.couple.currentJamSharedBy == myUid;
    final sharedByName = isSharedByMe ? 'You' : 'Your partner';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Marshmallow Vinyl Player Bento Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: LoveSnapsShadows.marshmallowShadowCard,
                  ),
                  child: Column(
                    children: [
                      // Vinyl disc
                      RotationTransition(
                        turns: _rotationController,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[900],
                            boxShadow: [
                              BoxShadow(
                                color: LoveSnapsColors.primary.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            gradient: RadialGradient(
                              colors: [
                                Colors.grey[800]!,
                                Colors.black.withOpacity(0.8),
                                Colors.black,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: LoveSnapsColors.primaryContainer,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: const Center(
                                child: Text('🎵', style: TextStyle(fontSize: 24)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      if (hasJam) ...[
                        Text(
                          widget.couple.currentJamTitle!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LoveSnapsColors.primary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn().scale(),
                        const SizedBox(height: 8),
                        Text(
                          widget.couple.currentJamArtist!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: LoveSnapsColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '$sharedByName shared this jam',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: LoveSnapsColors.secondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'No Jam Active',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LoveSnapsColors.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Share what you are listening to right now!',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 32),
                
                // tactile control button
                GestureDetector(
                  onTap: _showUpdateJamDialog,
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: LoveSnapsColors.pinkAccent,
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: LoveSnapsShadows.marshmallowShadowBtn,
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'SHARE WHAT I\'M LISTENING TO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate(delay: 200.ms).fadeIn().scale(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
