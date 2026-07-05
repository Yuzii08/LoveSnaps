import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';

final partnerUserProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final couple = ref.watch(coupleStreamProvider).value;
  final myUid = ref.read(authServiceProvider).currentUser?.uid;
  if (couple == null || myUid == null) return null;
  final partnerUid = couple.partnerUid(myUid);
  if (partnerUid.isEmpty) return null;
  
  final doc = await FirebaseFirestore.instance.collection('users').doc(partnerUid).get();
  return doc.data();
});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String coupleId, String text) {
    if (text.trim().isEmpty) return;
    ref.read(chatServiceProvider).sendMessage(coupleId, text);
    _controller.clear();
    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(coupleStreamProvider);
    final messagesAsync = ref.watch(messagesStreamProvider);
    final user = ref.watch(authServiceProvider).currentUser;
    final partnerUser = ref.watch(partnerUserProvider).value;
    final partnerName = partnerUser?['displayName'] ?? 'My Partner';

    return Scaffold(
      appBar: AppBar(
        title: coupleAsync.when(
          data: (couple) {
            if (couple == null) return const Text('Chat');
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: LoveSnapsColors.primaryContainer,
                  radius: 18,
                  child: Text(
                    partnerName[0].toUpperCase(),
                    style: TextStyle(
                      color: LoveSnapsColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnerName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Connected 💕',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Chat'),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: LoveSnapsColors.onSurface,
      ),
      body: coupleAsync.when(
        data: (couple) {
          if (couple == null) {
            return const Center(child: Text('Pair first to start chatting!'));
          }

          return Column(
            children: [
              // Message List
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💬', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'Send a sweet message to $partnerName!',
                              style: TextStyle(color: LoveSnapsColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      reverse: true, // Display latest at the bottom
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == user?.uid;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? LoveSnapsColors.primary
                                  : LoveSnapsColors.surfaceVariant,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : LoveSnapsColors.onSurface,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('h:mm a').format(message.timestamp),
                                  style: TextStyle(
                                    color: isMe ? Colors.white60 : Colors.black38,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scaleXY(
                                begin: 0.9,
                                end: 1,
                                curve: Curves.bounceOut,
                                duration: 300.ms,
                              ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),

              // Quick replies helper
              Container(
                height: 40,
                color: Colors.white,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    'Love you! ❤️',
                    'Miss you! 💕',
                    'Hug me! 🤗',
                    'Call me? 📞',
                    'On my way! 🏃‍♂️',
                    'Eat well! 🍔',
                  ].map((phrase) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: ActionChip(
                        label: Text(
                          phrase,
                          style: TextStyle(
                            color: LoveSnapsColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: LoveSnapsColors.primaryContainer.withOpacity(0.5),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onPressed: () => _sendMessage(couple.coupleId, phrase),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Message Input Bar
              Container(
                padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: LoveSnapsColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Type a cute message...',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          onSubmitted: (val) => _sendMessage(couple.coupleId, val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendMessage(couple.coupleId, _controller.text),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: LoveSnapsColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
