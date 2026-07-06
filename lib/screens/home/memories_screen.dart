import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/snap_model.dart';
import '../../services/snap_service.dart';
import '../../services/auth_service.dart';

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

  void _openFullImage(BuildContext context, WidgetRef ref, SnapModel snap, String myUid, String coupleId) {
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
                        child: _buildImageWidget(snap.imageUrl, fit: BoxFit.contain),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapsAsync = ref.watch(snapsStreamProvider);
    final myUid = ref.watch(authStateProvider).value?.uid ?? '';
    final userDoc = ref.watch(currentUserDocProvider).value;
    final coupleId = userDoc?.coupleId ?? '';

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
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final snap = snaps[index];
                    // Alternating slight rotations for organic polaroid look
                    final double rotation = (index % 2 == 0 ? 0.02 : -0.02) * (index % 3 + 1);

                    return Transform.rotate(
                      angle: rotation,
                      child: GestureDetector(
                        onTap: () => _openFullImage(context, ref, snap, myUid, coupleId),
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
                                    tag: snap.id,
                                    child: _buildImageWidget(snap.imageUrl),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
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
