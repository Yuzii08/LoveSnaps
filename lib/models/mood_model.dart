import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MoodModel extends Equatable {
  final String id;
  final String uid;
  final String emoji;
  final String date; // YYYY-MM-DD
  final DateTime timestamp;

  const MoodModel({
    required this.id,
    required this.uid,
    required this.emoji,
    required this.date,
    required this.timestamp,
  });

  factory MoodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodModel(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '',
      date: data['date'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'emoji': emoji,
      'date': date,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [id, uid, emoji, date, timestamp];
}
