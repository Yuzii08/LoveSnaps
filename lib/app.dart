import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/auth_screen.dart';
import 'screens/onboarding/pair_screen.dart';
import 'screens/onboarding/start_date_screen.dart';
import 'screens/onboarding/permissions_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/settings_screen.dart';
import 'screens/home/chat_screen.dart';
import 'screens/home/notes_jar_screen.dart';
import 'screens/home/mood_history_screen.dart';
import 'screens/home/event_list_screen.dart';
import 'screens/home/stats_screen.dart';
import 'models/couple_model.dart';

// ── Router ─────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // Auth guard handled per-screen; splash decides initial routing
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/splash',
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/pair',
      builder: (context, state) => const PairScreen(),
    ),
    GoRoute(
      path: '/start-date',
      builder: (context, state) => const StartDateScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionsScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'chat',
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: 'notes-jar',
          builder: (context, state) => const NotesJarScreen(),
        ),
        GoRoute(
          path: 'mood-history',
          builder: (context, state) => const MoodHistoryScreen(),
        ),
        GoRoute(
          path: 'events',
          builder: (context, state) => const EventListScreen(),
        ),
        GoRoute(
          path: 'stats',
          builder: (context, state) => StatsScreen(couple: state.extra as CoupleModel),
        ),
      ],
    ),
  ],
);

// ── App ────────────────────────────────────────────────────────────────────

class LoveSnapsApp extends ConsumerWidget {
  const LoveSnapsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'LoveSnaps',
      debugShowCheckedModeBanner: false,
      theme: LoveSnapsTheme.light(),
      darkTheme: LoveSnapsTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
