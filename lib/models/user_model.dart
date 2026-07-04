import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final String? coupleId;
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.coupleId,
    this.fcmToken,
    required this.createdAt,
  });

  bool get isPaired => coupleId != null && coupleId!.isNotEmpty;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      coupleId: data['coupleId'] as String?,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'coupleId': coupleId,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? coupleId,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      coupleId: coupleId ?? this.coupleId,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [uid, displayName, email, coupleId, fcmToken];
}
