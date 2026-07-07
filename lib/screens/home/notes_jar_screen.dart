import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';
import '../../services/auth_service.dart';

class NotesJarScreen extends ConsumerWidget {
  const NotesJarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesStreamProvider);
    final myUid = ref.watch(authServiceProvider).currentUser?.uid ?? '';

    // Color list for notes notes
    final noteColors = [
      const Color(0xFFFFF7ED), // Orange-ish tint
      const Color(0xFFFEF2F2), // Pink-ish tint
      const Color(0xFFECFDF5), // Mint-ish tint
      const Color(0xFFF5F3FF), // Lavender-ish tint
      const Color(0xFFFFFDF5), // Yellow-ish tint
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('💌 Our Notes Jar'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: LoveSnapsColors.primary,
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: LoveSnapsColors.primaryContainer.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🏺', style: TextStyle(fontSize: 72)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your Note Jar is empty!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LoveSnapsColors.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete today\'s daily prompt to send a note to your partner!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('🏺', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 8),
                        Text(
                          '${notes.length} sweet note${notes.length == 1 ? '' : 's'} inside',
                          style: TextStyle(
                            color: LoveSnapsColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final note = notes[index];
                      final isMe = note.senderId == myUid;
                      final bgColor = noteColors[index % noteColors.length];
                      final rotation = (index % 2 == 0 ? 0.03 : -0.03) * (index % 3 + 1);

                      return Transform.rotate(
                        angle: rotation,
                        child: Card(
                          color: bgColor,
                          elevation: 2,
                          shadowColor: LoveSnapsColors.primary.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showNoteDetail(context, note, isMe, bgColor),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isMe ? 'From Me ✍️' : 'From Partner 💖',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isMe ? LoveSnapsColors.primary : LoveSnapsColors.secondary,
                                        ),
                                      ),
                                      const Icon(Icons.push_pin_rounded, size: 14, color: LoveSnapsColors.pinkAccent),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    note.prompt,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: LoveSnapsColors.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      note.text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Quicksand',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                        height: 1.3,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(note.timestamp),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).scale(begin: const Offset(0.9, 0.9));
                    },
                    childCount: notes.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load notes: $err')),
      ),
    );
  }

  void _showNoteDetail(BuildContext context, NoteModel note, bool isMe, Color bgColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMe ? LoveSnapsColors.primaryContainer : LoveSnapsColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isMe ? 'Sent by Me' : 'Sent by Partner',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMe ? LoveSnapsColors.onPrimaryContainer : LoveSnapsColors.onSecondaryContainer,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMMM d, yyyy').format(note.timestamp),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Prompt: ${note.prompt}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey[700],
              ),
            ),
            const Divider(height: 24),
            Text(
              note.text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w500,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoveSnapsColors.primary,
                  minimumSize: const Size(120, 44),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
