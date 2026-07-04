import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/couple_model.dart';

class LocalMockDb {
  static final StreamController<UserModel?> userController = StreamController<UserModel?>.broadcast();
  static final StreamController<CoupleModel?> coupleController = StreamController<CoupleModel?>.broadcast();

  static String? _currentUid;
  
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUid = prefs.getString('mock_current_uid');
    await refresh();
  }

  static Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUid == null) {
      userController.add(null);
      coupleController.add(null);
      return;
    }

    final userJson = prefs.getString('mock_user_$_currentUid');
    if (userJson != null) {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      final user = UserModel(
        uid: _currentUid!,
        displayName: userData['displayName'] as String? ?? '',
        email: userData['email'] as String? ?? '',
        coupleId: userData['coupleId'] as String?,
        fcmToken: userData['fcmToken'] as String?,
        createdAt: DateTime.parse(userData['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      );
      userController.add(user);

      if (user.coupleId != null && user.coupleId!.isNotEmpty) {
        final coupleJson = prefs.getString('mock_couple_${user.coupleId}');
        if (coupleJson != null) {
          final coupleData = jsonDecode(coupleJson) as Map<String, dynamic>;
          final locations = (coupleData['latestLocations'] as Map<String, dynamic>? ?? {}).map(
            (key, val) => MapEntry(
              key,
              LatestLocation(
                lat: (val['lat'] as num).toDouble(),
                lng: (val['lng'] as num).toDouble(),
                updatedAt: DateTime.parse(val['updatedAt'] as String),
              ),
            ),
          );
          
          final couple = CoupleModel(
            coupleId: user.coupleId!,
            memberIds: List<String>.from(coupleData['memberIds'] as List? ?? []),
            inviteCode: coupleData['inviteCode'] as String? ?? user.coupleId!,
            relationshipStartDate: coupleData['relationshipStartDate'] != null
                ? DateTime.parse(coupleData['relationshipStartDate'] as String)
                : null,
            streakCount: coupleData['streakCount'] as int? ?? 0,
            streakLastUpdatedDate: coupleData['streakLastUpdatedDate'] as String?,
            partnerACheckedIn: coupleData['partnerACheckedIn'] as bool? ?? false,
            partnerBCheckedIn: coupleData['partnerBCheckedIn'] as bool? ?? false,
            latestLocations: locations,
            useManualDistance: coupleData['useManualDistance'] as bool? ?? false,
            manualStatus: coupleData['manualStatus'] as String? ?? 'apart',
            lastMissYouSentAt: coupleData['lastMissYouSentAt'] != null
                ? DateTime.parse(coupleData['lastMissYouSentAt'] as String)
                : null,
            lastMissYouSentBy: coupleData['lastMissYouSentBy'] as String?,
            createdAt: DateTime.parse(coupleData['createdAt'] as String? ?? DateTime.now().toIso8601String()),
          );
          coupleController.add(couple);
        } else {
          coupleController.add(null);
        }
      } else {
        coupleController.add(null);
      }
    } else {
      userController.add(null);
      coupleController.add(null);
    }
  }

  static Future<UserModel> signUp(String email, String password, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    final existingUid = prefs.getString('mock_user_email_$email');
    if (existingUid != null) {
      throw Exception('That email is already registered. Try signing in.');
    }

    final uid = 'mock_uid_${DateTime.now().millisecondsSinceEpoch}';
    final userMap = {
      'displayName': displayName,
      'email': email,
      'coupleId': null,
      'fcmToken': null,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString('mock_user_$uid', jsonEncode(userMap));
    await prefs.setString('mock_user_email_$email', uid);
    await prefs.setString('mock_user_password_$uid', password);

    _currentUid = uid;
    await prefs.setString('mock_current_uid', uid);
    await refresh();

    return UserModel(
      uid: uid,
      displayName: displayName,
      email: email,
      createdAt: DateTime.now(),
    );
  }

  static Future<UserModel> signIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('mock_user_email_$email');
    if (uid == null) {
      throw Exception('Incorrect email or password.');
    }

    final savedPassword = prefs.getString('mock_user_password_$uid');
    if (savedPassword != password) {
      throw Exception('Incorrect email or password.');
    }

    _currentUid = uid;
    await prefs.setString('mock_current_uid', uid);
    await refresh();

    final userJson = prefs.getString('mock_user_$uid')!;
    final userData = jsonDecode(userJson) as Map<String, dynamic>;
    return UserModel(
      uid: uid,
      displayName: userData['displayName'] as String? ?? '',
      email: email,
      coupleId: userData['coupleId'] as String?,
      fcmToken: userData['fcmToken'] as String?,
      createdAt: DateTime.parse(userData['createdAt'] as String),
    );
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUid = null;
    await prefs.remove('mock_current_uid');
    await refresh();
  }

  static String? getCurrentUid() => _currentUid;

  // Couple DB helper functions
  static Future<String> generateInviteCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = 'MOCK${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    
    final coupleMap = {
      'memberIds': [_currentUid],
      'inviteCode': code,
      'relationshipStartDate': null,
      'streakCount': 0,
      'streakLastUpdatedDate': null,
      'partnerACheckedIn': false,
      'partnerBCheckedIn': false,
      'latestLocations': {},
      'useManualDistance': false,
      'manualStatus': 'apart',
      'lastMissYouSentAt': null,
      'lastMissYouSentBy': null,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString('mock_couple_$code', jsonEncode(coupleMap));
    
    // Update user
    final userJson = prefs.getString('mock_user_$_currentUid')!;
    final userData = jsonDecode(userJson) as Map<String, dynamic>;
    userData['coupleId'] = code;
    await prefs.setString('mock_user_$_currentUid', jsonEncode(userData));

    await refresh();
    return code;
  }

  static Future<void> joinWithCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final coupleJson = prefs.getString('mock_couple_${code.toUpperCase()}');
    if (coupleJson == null) {
      throw Exception('Invalid invite code. Please check and try again.');
    }
    
    final coupleData = jsonDecode(coupleJson) as Map<String, dynamic>;
    final memberIds = List<String>.from(coupleData['memberIds'] as List? ?? []);
    if (memberIds.length >= 2) {
      throw Exception('This invite code has already been used.');
    }
    if (memberIds.contains(_currentUid)) {
      throw Exception("You can't pair with yourself!");
    }

    memberIds.add(_currentUid!);
    coupleData['memberIds'] = memberIds;
    await prefs.setString('mock_couple_${code.toUpperCase()}', jsonEncode(coupleData));

    // Update user
    final userJson = prefs.getString('mock_user_$_currentUid')!;
    final userData = jsonDecode(userJson) as Map<String, dynamic>;
    userData['coupleId'] = code.toUpperCase();
    await prefs.setString('mock_user_$_currentUid', jsonEncode(userData));

    await refresh();
  }

  static Future<void> setStartDate(String coupleId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final coupleJson = prefs.getString('mock_couple_$coupleId')!;
    final coupleData = jsonDecode(coupleJson) as Map<String, dynamic>;
    coupleData['relationshipStartDate'] = date.toIso8601String();
    await prefs.setString('mock_couple_$coupleId', jsonEncode(coupleData));
    await refresh();
  }

  static Future<void> setManualStatus(String coupleId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final coupleJson = prefs.getString('mock_couple_$coupleId')!;
    final coupleData = jsonDecode(coupleJson) as Map<String, dynamic>;
    coupleData['manualStatus'] = status;
    await prefs.setString('mock_couple_$coupleId', jsonEncode(coupleData));
    await refresh();
  }

  static Future<void> setUseManualDistance(String coupleId, bool useManual) async {
    final prefs = await SharedPreferences.getInstance();
    final coupleJson = prefs.getString('mock_couple_$coupleId')!;
    final coupleData = jsonDecode(coupleJson) as Map<String, dynamic>;
    coupleData['useManualDistance'] = useManual;
    await prefs.setString('mock_couple_$coupleId', jsonEncode(coupleData));
    await refresh();
  }

  static Future<void> sendMissYou(String coupleId) async {
    final prefs = await SharedPreferences.getInstance();
    final coupleJson = prefs.getString('mock_couple_$coupleId')!;
    final coupleData = jsonDecode(coupleJson) as Map<String, dynamic>;
    coupleData['lastMissYouSentAt'] = DateTime.now().toIso8601String();
    coupleData['lastMissYouSentBy'] = _currentUid;
    await prefs.setString('mock_couple_$coupleId', jsonEncode(coupleData));
    await refresh();
  }

  static Future<void> checkIn(String coupleId) async {
    final prefs = await SharedPreferences.getInstance();
    final coupleJson = prefs.getString('mock_couple_$coupleId')!;
    final coupleData = jsonDecode(coupleJson) as Map<String, dynamic>;
    
    final memberIds = List<String>.from(coupleData['memberIds'] as List? ?? []);
    if (memberIds.isEmpty) return;

    final isPartnerA = _currentUid == memberIds[0];
    final myKey = isPartnerA ? 'partnerACheckedIn' : 'partnerBCheckedIn';
    final partnerKey = isPartnerA ? 'partnerBCheckedIn' : 'partnerACheckedIn';
    final partnerCheckedIn = coupleData[partnerKey] as bool? ?? false;
    final alreadyCheckedIn = coupleData[myKey] as bool? ?? false;

    if (alreadyCheckedIn) return;

    coupleData[myKey] = true;

    if (partnerCheckedIn) {
      final currentStreak = coupleData['streakCount'] as int? ?? 0;
      coupleData['streakCount'] = currentStreak + 1;
      coupleData['streakLastUpdatedDate'] = DateTime.now().toIso8601String().substring(0, 10);
    } else {
      // If it's a new check-in and partner has not checked in, we keep my checked in as true
    }

    await prefs.setString('mock_couple_$coupleId', jsonEncode(coupleData));
    await refresh();
  }

  static Future<void> updateLocation(String coupleId, double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final coupleJson = prefs.getString('mock_couple_$coupleId')!;
    final coupleData = jsonDecode(coupleJson) as Map<String, dynamic>;
    
    final locations = coupleData['latestLocations'] as Map<String, dynamic>? ?? {};
    locations[_currentUid!] = {
      'lat': lat,
      'lng': lng,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    coupleData['latestLocations'] = locations;
    
    await prefs.setString('mock_couple_$coupleId', jsonEncode(coupleData));
    await refresh();
  }
}
