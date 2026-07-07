import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'core/constants.dart';
import 'firebase_options.dart';
import 'services/local_mock_db.dart';

// Background handler for Firebase Cloud Messages (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling background FCM message: ${message.messageId}');
}

// Background callback from home_widget interactive actions (e.g. Miss You tap)
@pragma('vm:entry-point')
void widgetBackgroundCallback(Uri? uri) async {
  if (uri?.host == 'missyou') {
    debugPrint('Widget background callback: miss you tapped');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final coupleId = await HomeWidget.getWidgetData<String>('couple_id');
      if (uid != null && coupleId != null) {
        await FirebaseFirestore.instance.collection(AppConstants.couplesCollection).doc(coupleId).update({
          'lastMissYouSentAt': FieldValue.serverTimestamp(),
          'lastMissYouSentBy': uid,
        });
        debugPrint('Successfully updated miss you in background!');
      } else {
        debugPrint('Could not update miss you in background: uid=$uid, coupleId=$coupleId');
      }
    } catch (e) {
      debugPrint('Error updating miss you in background: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
  );

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase Storage if credentials are provided
  if (AppConstants.supabaseUrl != 'YOUR_SUPABASE_URL') {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    debugPrint('Supabase initialized for Storage');
  }

  if (AppConstants.useLocalMock) {
    await LocalMockDb.init();
    debugPrint('Local Mock Database Initialized');
  }

  // Native-only features (not supported on web)
  if (!kIsWeb) {
    // Background FCM handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // home_widget: set app group for iOS shared storage
    await HomeWidget.setAppGroupId('group.com.lovesnaps.app');

    // Register background callback for interactive widget actions
    HomeWidget.registerBackgroundCallback(widgetBackgroundCallback);
  }

  runApp(
    const ProviderScope(
      child: LoveSnapsApp(),
    ),
  );
}
