import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/constants.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final widgetServiceProvider =
    Provider<WidgetService>((ref) => WidgetService());

// ── Service ────────────────────────────────────────────────────────────────

class WidgetService {
  // ── Data Push ─────────────────────────────────────────────────────────

  /// Pushes all widget data to shared storage and triggers a widget refresh.
  Future<void> updateWidgets({
    required String coupleId,
    required int streakCount,
    required int daysCount,
    required String partnerName,
    required String distance,      // formatted string or '—'
    required String manualStatus,  // 'together' | 'apart'
    required bool streakAtRisk,
    required bool missYouReceived,
  }) async {
    if (kIsWeb) return;
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('couple_id', coupleId),
        HomeWidget.saveWidgetData<int>(
          AppConstants.widgetKeyStreakCount, streakCount),
        HomeWidget.saveWidgetData<int>(
          AppConstants.widgetKeyDaysCount, daysCount),
        HomeWidget.saveWidgetData<String>(
          AppConstants.widgetKeyPartnerName, partnerName),
        HomeWidget.saveWidgetData<String>(
          AppConstants.widgetKeyDistance, distance),
        HomeWidget.saveWidgetData<String>(
          AppConstants.widgetKeyManualStatus, manualStatus),
        HomeWidget.saveWidgetData<bool>(
          AppConstants.widgetKeyStreakAtRisk, streakAtRisk),
        HomeWidget.saveWidgetData<bool>(
          AppConstants.widgetKeyMissYouReceived, missYouReceived),
      ]);

      // Trigger both widget sizes to redraw
      await Future.wait([
        HomeWidget.updateWidget(
          name: AppConstants.widgetNameSmall,
          androidName: AppConstants.androidWidgetSmall,
          iOSName: AppConstants.widgetNameSmall,
          qualifiedAndroidName:
              'com.lovesnaps.app.${AppConstants.androidWidgetSmall}',
        ),
        HomeWidget.updateWidget(
          name: AppConstants.widgetNameMedium,
          androidName: AppConstants.androidWidgetMedium,
          iOSName: AppConstants.widgetNameMedium,
          qualifiedAndroidName:
              'com.lovesnaps.app.${AppConstants.androidWidgetMedium}',
        ),
      ]);
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  // ── Widget Callback (from native side) ────────────────────────────────

  /// Called when the user taps the "Miss You" button on the medium widget.
  /// Returns the URI if the callback matches, null otherwise.
  static bool isMissYouCallback(Uri? uri) =>
      uri?.host == 'missyou';

  /// Clears the miss-you received flag after animation is shown.
  Future<void> clearMissYouFlag() async {
    if (kIsWeb) return;
    await HomeWidget.saveWidgetData<bool>(
        AppConstants.widgetKeyMissYouReceived, false);
  }

  // ── Widget Interaction URI ─────────────────────────────────────────────

  /// Registers a callback to handle widget interactions when app is foregrounded.
  void registerWidgetClickCallback(void Function(Uri?) callback) {
    if (kIsWeb) return;
    HomeWidget.widgetClicked.listen(callback);
  }
}
