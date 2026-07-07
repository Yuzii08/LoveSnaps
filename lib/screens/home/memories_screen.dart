import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/snap_model.dart';
import '../../models/couple_model.dart';
import '../../services/snap_service.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';

class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  Widget _buildImageWidget(String imageUrl, {BoxFit fit = BoxFit.cover}) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Content = imageUrl.split(',').last;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
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
        fit: fit,
        width: double.infinity,
        height: double.infinity,
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

  int _getDayTogether(DateTime timestamp, DateTime? startDate) {
    if (startDate == null) return 1;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
    return day.difference(start).inDays + 1;
  }

  void _openSwipeableFullImage(
    BuildContext context,
    WidgetRef ref,
    List<SnapModel> snaps,
    int initialIndex,
    String myUid,
    CoupleModel couple,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SwipeableMemoriesViewer(
          snaps: snaps,
          initialIndex: initialIndex,
          myUid: myUid,
          couple: couple,
          ref: ref,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapsAsync = ref.watch(snapsStreamProvider);
    final myUid = ref.watch(authStateProvider).value?.uid ?? '';
    final couple = ref.watch(coupleStreamProvider).value;
    
    if (couple == null) {
      return const Center(child: Text('Pair first to see memories!'));
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Our Memories',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: LoveSnapsColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Your shared polaroid timeline',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LoveSnapsColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        snapsAsync.when(
          data: (snaps) {
            if (snaps.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📸', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 16),
                      Text(
                        'No memories yet',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Post your first snap to start your memory timeline!',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final snap = snaps[index];
                    final double rotation = (index % 2 == 0 ? 0.02 : -0.02) * (index % 3 + 1);
                    final dayCount = _getDayTogether(snap.timestamp, couple.relationshipStartDate);

                    return Transform.rotate(
                      angle: rotation,
                      child: GestureDetector(
                        onTap: () => _openSwipeableFullImage(context, ref, snaps, index, myUid, couple),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: LoveSnapsShadows.marshmallowShadowCard,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Hero(
                                    tag: 'polaroid_${snap.id}',
                                    child: _buildImageWidget(snap.imageUrl),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: LoveSnapsColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Day $dayCount together',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: LoveSnapsColors.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                snap.caption.isNotEmpty ? snap.caption : 'Memory 💕',
                                style: const TextStyle(
                                  fontFamily: 'Quicksand',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM d, yyyy').format(snap.timestamp),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms);
                  },
                  childCount: snaps.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => SliverFillRemaining(
            child: Center(child: Text('Failed to load memories: $err')),
          ),
        ),
      ],
    );
  }
}

class SwipeableMemoriesViewer extends StatefulWidget {
  final List<SnapModel> snaps;
  final int initialIndex;
  final String myUid;
  final CoupleModel couple;
  final WidgetRef ref;

  const SwipeableMemoriesViewer({
    required this.snaps,
    required this.initialIndex,
    required this.myUid,
    required this.couple,
    required this.ref,
  });

  @override
  State<SwipeableMemoriesViewer> createState() => SwipeableMemoriesViewerState();
}

class SwipeableMemoriesViewerState extends State<SwipeableMemoriesViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Content = imageUrl.split(',').last;
        final bytes = base64Decode(base64Content);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 48));
      }
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.error_outline_rounded, color: Colors.white, size: 48)),
      );
    }
  }

  int _getDayTogether(DateTime timestamp, DateTime? startDate) {
    if (startDate == null) return 1;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
    return day.difference(start).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full Screen PageView with Pinch-Zoom
          PageView.builder(
            controller: _pageController,
            itemCount: widget.snaps.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final snap = widget.snaps[index];
              return Center(
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  maxScale: 4.0,
                  child: Hero(
                    tag: 'polaroid_${snap.id}',
                    child: _buildImage(snap.imageUrl),
                  ),
                ),
              );
            },
          ),

          // Header: Back button + Delete action
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                // Conditional delete button
                Builder(
                  builder: (context) {
                    final currentSnap = widget.snaps[_currentIndex];
                    final canDelete = DateTime.now().difference(currentSnap.timestamp).inMinutes < 15 && currentSnap.senderId == widget.myUid;
                    if (!canDelete) return const SizedBox.shrink();

                    return IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Snap?'),
                            content: const Text('Are you sure you want to delete this memory? This cannot be undone.'),
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
                            await widget.ref.read(snapServiceProvider).deleteSnap(widget.couple.coupleId, currentSnap.id);
                            if (context.mounted) {
                              Navigator.pop(context); // Close viewer
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('📸 Snap deleted!'), backgroundColor: Colors.redAccent),
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
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom card: Caption, Date, and Day count
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Display current reactions floating above the card
                if (widget.snaps[_currentIndex].reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, right: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: widget.snaps[_currentIndex].reactions.entries
                          .where((e) => e.value.isNotEmpty)
                          .map((e) {
                        return Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Text(e.value, style: const TextStyle(fontSize: 18)),
                        );
                      }).toList(),
                    ).animate().fadeIn().slideY(begin: 0.5, end: 0),
                  ),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: LoveSnapsColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Day ${_getDayTogether(widget.snaps[_currentIndex].timestamp, widget.couple.relationshipStartDate)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            DateFormat('MMMM d, yyyy · h:mm a').format(widget.snaps[_currentIndex].timestamp),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      if (widget.snaps[_currentIndex].caption.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.snaps[_currentIndex].caption,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Reaction buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['❤️', '😂', '🔥', '🥺', '😍'].map((emoji) {
                          final hasReacted = widget.snaps[_currentIndex].reactions[widget.myUid] == emoji;
                          return GestureDetector(
                            onTap: () {
                              widget.ref.read(coupleServiceProvider).reactToSnap(
                                widget.couple.coupleId, 
                                widget.snaps[_currentIndex].id, 
                                hasReacted ? '' : emoji // toggle reaction off if already selected
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: hasReacted ? LoveSnapsColors.primaryContainer : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 24)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
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
