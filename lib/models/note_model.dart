import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class NoteModel extends Equatable {
  final String id;
  final String prompt;
  final String text;
  final String senderId;
  final DateTime timestamp;

  const NoteModel({
    required this.id,
    required this.prompt,
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      prompt: data['prompt'] as String? ?? '',
      text: data['text'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'prompt': prompt,
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [id, prompt, text, senderId, timestamp];
}
