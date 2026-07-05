import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class LatestLocation {
  final double lat;
  final double lng;
  final DateTime updatedAt;

  const LatestLocation({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory LatestLocation.fromMap(Map<String, dynamic> map) {
    return LatestLocation(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class CoupleModel extends Equatable {
  final String coupleId;
  final List<String> memberIds;
  final String inviteCode;
  final DateTime? relationshipStartDate;
  final int streakCount;
  final String? streakLastUpdatedDate; // "YYYY-MM-DD"
  final bool partnerACheckedIn;
  final bool partnerBCheckedIn;
  final Map<String, LatestLocation> latestLocations;
  final bool useManualDistance;
  final String manualStatus; // "together" | "apart"
  final DateTime? lastMissYouSentAt;
  final String? lastMissYouSentBy;
  final String? currentJamTitle;
  final String? currentJamArtist;
  final String? currentJamSharedBy;
  final DateTime? currentJamSharedAt;
  final DateTime createdAt;

  const CoupleModel({
    required this.coupleId,
    required this.memberIds,
    required this.inviteCode,
    this.relationshipStartDate,
    this.streakCount = 0,
    this.streakLastUpdatedDate,
    this.partnerACheckedIn = false,
    this.partnerBCheckedIn = false,
    this.latestLocations = const {},
    this.useManualDistance = false,
    this.manualStatus = 'apart',
    this.lastMissYouSentAt,
    this.lastMissYouSentBy,
    this.currentJamTitle,
    this.currentJamArtist,
    this.currentJamSharedBy,
    this.currentJamSharedAt,
    required this.createdAt,
  });

  // ── Computed properties ─────────────────────────────────────────────────

  bool get isFullyPaired => memberIds.length == 2;

  int get daysTogetherCount {
    if (relationshipStartDate == null) return 0;
    final now = DateTime.now();
    final start = DateTime(
      relationshipStartDate!.year,
      relationshipStartDate!.month,
      relationshipStartDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(start).inDays + 1;
  }

  bool get isMilestoneDay {
    final days = daysTogetherCount;
    const milestones = [7, 14, 30, 50, 100, 150, 200, 365, 500, 730, 1000];
    return milestones.contains(days);
  }

  int? get nextMilestone {
    final days = daysTogetherCount;
    const milestones = [7, 14, 30, 50, 100, 150, 200, 365, 500, 730, 1000];
    for (final m in milestones) {
      if (m > days) return m;
    }
    return null;
  }

  String partnerUid(String myUid) {
    return memberIds.firstWhere((id) => id != myUid, orElse: () => '');
  }

  bool hasCheckedIn(String uid) {
    if (memberIds.isEmpty) return false;
    return uid == memberIds[0] ? partnerACheckedIn : partnerBCheckedIn;
  }

  // ── Serialization ───────────────────────────────────────────────────────

  factory CoupleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawLocations = data['latestLocations'] as Map<String, dynamic>? ?? {};
    final locations = rawLocations.map(
      (key, value) => MapEntry(
        key,
        LatestLocation.fromMap(value as Map<String, dynamic>),
      ),
    );

    return CoupleModel(
      coupleId: doc.id,
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      inviteCode: data['inviteCode'] as String? ?? doc.id,
      relationshipStartDate:
          (data['relationshipStartDate'] as Timestamp?)?.toDate(),
      streakCount: (data['streakCount'] as num?)?.toInt() ?? 0,
      streakLastUpdatedDate: data['streakLastUpdatedDate'] as String?,
      partnerACheckedIn: data['partnerACheckedIn'] as bool? ?? false,
      partnerBCheckedIn: data['partnerBCheckedIn'] as bool? ?? false,
      latestLocations: locations,
      useManualDistance: data['useManualDistance'] as bool? ?? false,
      manualStatus: data['manualStatus'] as String? ?? 'apart',
      lastMissYouSentAt:
          (data['lastMissYouSentAt'] as Timestamp?)?.toDate(),
      lastMissYouSentBy: data['lastMissYouSentBy'] as String?,
      currentJamTitle: data['currentJamTitle'] as String?,
      currentJamArtist: data['currentJamArtist'] as String?,
      currentJamSharedBy: data['currentJamSharedBy'] as String?,
      currentJamSharedAt: (data['currentJamSharedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      'relationshipStartDate': relationshipStartDate != null
          ? Timestamp.fromDate(relationshipStartDate!)
          : null,
      'streakCount': streakCount,
      'streakLastUpdatedDate': streakLastUpdatedDate,
      'partnerACheckedIn': partnerACheckedIn,
      'partnerBCheckedIn': partnerBCheckedIn,
      'latestLocations': latestLocations.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'useManualDistance': useManualDistance,
      'manualStatus': manualStatus,
      'lastMissYouSentAt': lastMissYouSentAt != null
          ? Timestamp.fromDate(lastMissYouSentAt!)
          : null,
      'lastMissYouSentBy': lastMissYouSentBy,
      'currentJamTitle': currentJamTitle,
      'currentJamArtist': currentJamArtist,
      'currentJamSharedBy': currentJamSharedBy,
      'currentJamSharedAt': currentJamSharedAt != null
          ? Timestamp.fromDate(currentJamSharedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CoupleModel copyWith({
    List<String>? memberIds,
    DateTime? relationshipStartDate,
    int? streakCount,
    String? streakLastUpdatedDate,
    bool? partnerACheckedIn,
    bool? partnerBCheckedIn,
    Map<String, LatestLocation>? latestLocations,
    bool? useManualDistance,
    String? manualStatus,
    DateTime? lastMissYouSentAt,
    String? lastMissYouSentBy,
    String? currentJamTitle,
    String? currentJamArtist,
    String? currentJamSharedBy,
    DateTime? currentJamSharedAt,
  }) {
    return CoupleModel(
      coupleId: coupleId,
      memberIds: memberIds ?? this.memberIds,
      inviteCode: inviteCode,
      relationshipStartDate:
          relationshipStartDate ?? this.relationshipStartDate,
      streakCount: streakCount ?? this.streakCount,
      streakLastUpdatedDate:
          streakLastUpdatedDate ?? this.streakLastUpdatedDate,
      partnerACheckedIn: partnerACheckedIn ?? this.partnerACheckedIn,
      partnerBCheckedIn: partnerBCheckedIn ?? this.partnerBCheckedIn,
      latestLocations: latestLocations ?? this.latestLocations,
      useManualDistance: useManualDistance ?? this.useManualDistance,
      manualStatus: manualStatus ?? this.manualStatus,
      lastMissYouSentAt: lastMissYouSentAt ?? this.lastMissYouSentAt,
      lastMissYouSentBy: lastMissYouSentBy ?? this.lastMissYouSentBy,
      currentJamTitle: currentJamTitle ?? this.currentJamTitle,
      currentJamArtist: currentJamArtist ?? this.currentJamArtist,
      currentJamSharedBy: currentJamSharedBy ?? this.currentJamSharedBy,
      currentJamSharedAt: currentJamSharedAt ?? this.currentJamSharedAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        coupleId,
        memberIds,
        streakCount,
        relationshipStartDate,
        partnerACheckedIn,
        partnerBCheckedIn,
        manualStatus,
      ];
}
