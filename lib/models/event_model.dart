import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class EventModel extends Equatable {
  final String id;
  final String title;
  final DateTime date;
  final String senderId;
  final DateTime timestamp;

  const EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.senderId,
    required this.timestamp,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderId: data['senderId'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  @override
  List<Object?> get props => [id, title, date, senderId, timestamp];
}
