/// App-wide constants for LoveSnaps
class AppConstants {
  // Firestore collections
  static const String usersCollection = 'users';
  static const String couplesCollection = 'couples';

  // Toggle local mock mode for lag-free instant demo/testing
  static const bool useLocalMock = false;

  // Supabase Configuration (Free Storage)
  static const String supabaseUrl = 'https://ejufjwtpzusgjyhqcsxz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqdWZqd3RwenVzZ2p5aHFjc3h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1NTM4NDgsImV4cCI6MjA4OTEyOTg0OH0.lMj99M2nRI8Te8sGpjzEESa4aDSgZtmDdnOa1OWu320';
  static const String supabaseSnapsBucket = 'snaps';

  // SharedPreferences / HomeWidget keys
  static const String widgetKeyStreakCount = 'streak_count';
  static const String widgetKeyDaysCount = 'days_count';
  static const String widgetKeyPartnerName = 'partner_name';
  static const String widgetKeyDistance = 'distance';
  static const String widgetKeyDistanceUnit = 'distance_unit';
  static const String widgetKeyManualStatus = 'manual_status';
  static const String widgetKeyStreakAtRisk = 'streak_at_risk';
  static const String widgetKeyMissYouReceived = 'miss_you_received';

  // Widget names (must match Android/iOS widget names)
  static const String widgetNameSmall = 'LoveSnapSmallWidget';
  static const String widgetNameMedium = 'LoveSnapMediumWidget';

  // iOS App Group (must match Xcode capability)
  static const String iosAppGroup = 'group.com.lovesnaps.app';

  // Android widget class names
  static const String androidWidgetSmall = 'LoveSnapWidgetProvider';
  static const String androidWidgetMedium = 'LoveMediumWidgetProvider';

  // Deep link scheme
  static const String deepLinkScheme = 'lovesnaps';
  static const String deepLinkMissYou = 'lovesnaps://missyou';
  static const String deepLinkHome = 'lovesnaps://home';

  // Streak
  static const int streakAtRiskHour = 20; // 8 PM local — show "at risk" warning
  static const int locationRefreshMinutes = 20;

  // Milestone days
  static const List<int> milestoneDays = [
    7, 14, 30, 50, 100, 150, 200, 365, 500, 730, 1000
  ];

  // Invite code length
  static const int inviteCodeLength = 6;

  // FCM topics
  static const String topicPrefix = 'couple_';
}
