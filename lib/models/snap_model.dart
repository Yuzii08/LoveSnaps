import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SnapModel extends Equatable {
  final String id;
  final String imageUrl;
  final String senderId;
  final String caption;
  final DateTime timestamp;
  final Map<String, String> reactions; // map of uid -> emoji

  const SnapModel({
    required this.id,
    required this.imageUrl,
    required this.senderId,
    required this.caption,
    required this.timestamp,
    this.reactions = const {},
  });

  factory SnapModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SnapModel(
      id: doc.id,
      imageUrl: data['imageUrl'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: data['reactions'] != null 
          ? Map<String, String>.from(data['reactions'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'senderId': senderId,
      'caption': caption,
      'timestamp': Timestamp.fromDate(timestamp),
      'reactions': reactions,
    };
  }

  @override
  List<Object?> get props => [id, imageUrl, senderId, caption, timestamp, reactions];
}
