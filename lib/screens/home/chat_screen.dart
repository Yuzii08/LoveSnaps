import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';
import '../../models/couple_model.dart';

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
  final ImagePicker _picker = ImagePicker();
  
  bool _isStickerDrawerOpen = false;
  Timer? _typingTimer;
  bool _isTypingLocally = false;

  @override
  void initState() {
    super.initState();
    // Schedule marking messages as read on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _markAsRead() {
    final couple = ref.read(coupleStreamProvider).value;
    if (couple != null) {
      ref.read(chatServiceProvider).markMessagesAsRead(couple.coupleId);
    }
  }

  void _sendMessage(String coupleId, String text) {
    if (text.trim().isEmpty) return;
    _stopTyping();
    ref.read(chatServiceProvider).sendMessage(coupleId, text);
    _controller.clear();
    _scrollToBottom();
  }

  void _sendSticker(String coupleId, String stickerName) {
    ref.read(chatServiceProvider).sendStickerMessage(coupleId, stickerName);
    setState(() {
      _isStickerDrawerOpen = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendPhoto(String coupleId, ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 70);
      if (file == null) return;
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text('Sending cute photo... 📸'),
            ],
          ),
          backgroundColor: LoveSnapsColors.primary,
        ),
      );
      
      await ref.read(chatServiceProvider).sendPhotoMessage(coupleId, file);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send photo: $e'), backgroundColor: LoveSnapsColors.error),
      );
    }
  }

  void _onTextChanged(String text, String coupleId) {
    if (text.isEmpty) {
      _stopTyping();
      return;
    }
    
    if (!_isTypingLocally) {
      _isTypingLocally = true;
      ref.read(chatServiceProvider).setTyping(coupleId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 2000), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    if (_isTypingLocally) {
      _isTypingLocally = false;
      final couple = ref.read(coupleStreamProvider).value;
      if (couple != null) {
        ref.read(chatServiceProvider).setTyping(couple.coupleId, false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _openFullPhotoViewer(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.95),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  maxScale: 4.0,
                  child: imageUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(imageUrl.split(',').last),
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              Positioned(
                top: 48,
                right: 24,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
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
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(coupleStreamProvider);
    final messagesAsync = ref.watch(messagesStreamProvider);
    final user = ref.watch(authServiceProvider).currentUser;
    final partnerUser = ref.watch(partnerUserProvider).value;
    final partnerName = partnerUser?['displayName'] ?? 'My Partner';

    // Mark messages as read whenever new ones flow in
    ref.listen(messagesStreamProvider, (_, __) {
      _markAsRead();
    });

    return Scaffold(
      appBar: AppBar(
        title: coupleAsync.when(
          data: (couple) {
            if (couple == null) return const Text('Chat');
            final partnerUid = couple.partnerUid(user?.uid ?? '');
            final isTyping = couple.typingState[partnerUid] ?? false;

            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: LoveSnapsColors.primaryContainer,
                  radius: 18,
                  child: Text(
                    partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: LoveSnapsColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isTyping ? 'typing... 💬' : 'Connected 💕',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isTyping ? FontWeight.bold : FontWeight.normal,
                          color: isTyping ? LoveSnapsColors.primary : Colors.green[600],
                        ),
                      ),
                    ],
                  ),
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

          final partnerUid = couple.partnerUid(user?.uid ?? '');
          final isPartnerTyping = couple.typingState[partnerUid] ?? false;

          return Column(
            children: [
              // Message List
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    return Column(
                      children: [
                        Expanded(
                          child: messages.isEmpty
                              ? Center(
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
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  reverse: true, // Display latest at the bottom
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final message = messages[index];
                                    final isMe = message.senderId == user?.uid;

                                    return _buildMessageItem(message, isMe);
                                  },
                                ),
                        ),
                        // Real-time Partner Typing Indicator Bubble
                        if (isPartnerTyping)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8, right: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: LoveSnapsColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$partnerName is typing', style: const TextStyle(fontSize: 13, color: LoveSnapsColors.primary, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 6),
                                    const Text('• • •', style: TextStyle(fontSize: 14, color: LoveSnapsColors.primary, fontWeight: FontWeight.bold))
                                        .animate(onPlay: (c) => c.repeat())
                                        .scaleXY(duration: 1000.ms, begin: 0.8, end: 1.2, curve: Curves.easeInOut),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),

              // Quick replies helper (if keyboard not fully open or drawer closed)
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
                          style: const TextStyle(
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

              // Input Bar & Drawer Toggles
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Attachment Button (+)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: LoveSnapsColors.primary, size: 28),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => _buildAttachmentPicker(couple.coupleId),
                            );
                          },
                        ),
                        // Sticker Drawer Toggle Button (🧸)
                        IconButton(
                          icon: Icon(
                            _isStickerDrawerOpen ? Icons.keyboard_rounded : Icons.face_retouching_natural_rounded,
                            color: LoveSnapsColors.secondary,
                            size: 28,
                          ),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _isStickerDrawerOpen = !_isStickerDrawerOpen;
                            });
                          },
                        ),
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
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              maxLines: null,
                              onChanged: (val) => _onTextChanged(val, couple.coupleId),
                              onSubmitted: (val) => _sendMessage(couple.coupleId, val),
                              onTap: () {
                                if (_isStickerDrawerOpen) {
                                  setState(() {
                                    _isStickerDrawerOpen = false;
                                  });
                                }
                              },
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
                    if (_isStickerDrawerOpen) _buildStickerDrawer(couple.coupleId),
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

  Widget _buildMessageItem(MessageModel message, bool isMe) {
    // Determine content type
    final isSticker = message.sticker != null && message.sticker!.isNotEmpty;
    final isPhoto = message.imageUrl != null && message.imageUrl!.isNotEmpty;

    Widget body;
    if (isSticker) {
      body = _buildStickerWidget(message.sticker!);
    } else if (isPhoto) {
      body = GestureDetector(
        onTap: () => _openFullPhotoViewer(message.imageUrl!),
        child: Container(
          width: 200,
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[200],
          ),
          clipBehavior: Clip.antiAlias,
          child: message.imageUrl!.startsWith('data:image')
              ? Image.memory(
                  base64Decode(message.imageUrl!.split(',').last),
                  fit: BoxFit.cover,
                )
              : Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded)),
                ),
        ),
      );
    } else {
      body = Text(
        message.text,
        style: TextStyle(
          color: isMe ? Colors.white : LoveSnapsColors.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: (isSticker || isPhoto)
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: (isSticker || isPhoto)
                ? null
                : BoxDecoration(
                    color: isMe ? LoveSnapsColors.primary : LoveSnapsColors.surfaceVariant,
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
            child: body,
          ).animate().scaleXY(
                begin: 0.9,
                end: 1,
                curve: Curves.bounceOut,
                duration: 300.ms,
              ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 9,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.read ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: message.read ? LoveSnapsColors.secondary : Colors.black26,
                    size: 10,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStickerWidget(String stickerName) {
    String emoji = '🧸';
    Color bgColor = Colors.purple[50]!;
    
    switch (stickerName) {
      case 'hug':
        emoji = '🤗';
        bgColor = Colors.blue[50]!;
        break;
      case 'heart':
        emoji = '💖';
        bgColor = Colors.pink[50]!;
        break;
      case 'sparkles':
        emoji = '✨';
        bgColor = Colors.yellow[50]!;
        break;
      case 'cry':
        emoji = '🥺';
        bgColor = Colors.cyan[50]!;
        break;
      case 'kiss':
        emoji = '😘';
        bgColor = Colors.red[50]!;
        break;
      case 'dance':
        emoji = '💃';
        bgColor = Colors.orange[50]!;
        break;
    }

    final wiggleEffect = Text(emoji, style: const TextStyle(fontSize: 64))
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .rotate(duration: 800.ms, begin: -0.03, end: 0.03);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: wiggleEffect,
    );
  }

  Widget _buildStickerDrawer(String coupleId) {
    final stickers = [
      {'name': 'heart', 'emoji': '💖', 'label': 'Love'},
      {'name': 'hug', 'emoji': '🤗', 'label': 'Hug'},
      {'name': 'kiss', 'emoji': '😘', 'label': 'Kiss'},
      {'name': 'cry', 'emoji': '🥺', 'label': 'Compliment'},
      {'name': 'sparkles', 'emoji': '✨', 'label': 'Sparkles'},
      {'name': 'dance', 'emoji': '💃', 'label': 'Dance'},
    ];

    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: LoveSnapsColors.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stickers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          final sticker = stickers[index];
          return GestureDetector(
            onTap: () => _sendSticker(coupleId, sticker['name']!),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(sticker['emoji']!, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Text(
                  sticker['label']!,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: LoveSnapsColors.primary),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 250.ms, curve: Curves.easeOut);
  }

  Widget _buildAttachmentPicker(String coupleId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: LoveSnapsColors.outlineVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          const Text('🌸 Send a cute photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: LoveSnapsColors.primary)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachmentOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: LoveSnapsColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _sendPhoto(coupleId, ImageSource.camera);
                },
              ),
              _AttachmentOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: LoveSnapsColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _sendPhoto(coupleId, ImageSource.gallery);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
