import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/version.dart';

class UpdateService {
  static const String _repoOwner = 'Yuzii08';
  static const String _repoName = 'LoveSnaps';
  static const String _branch = 'main';
  
  static const String _commitsUrl = 'https://api.github.com/repos/$_repoOwner/$_repoName/commits/$_branch';
  static const String _latestReleaseUrl = 'https://github.com/$_repoOwner/$_repoName/releases/latest';
  static const String _downloadUrl = 'https://github.com/$_repoOwner/$_repoName/releases/latest/download/app-release.apk';

  /// Checks if a new commit is available on the main branch compared to the built-in SHA.
  /// If an update is available, it shows an AlertDialog prompting the user to download the new APK.
  static Future<void> checkForUpdates(BuildContext context) async {
    // Skip update check during local development
    if (APP_COMMIT_SHA == 'dev') {
      debugPrint('UpdateService: Running in dev mode, skipping update check.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(_commitsUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestSha = data['sha'] as String;

        if (latestSha != APP_COMMIT_SHA && latestSha.isNotEmpty) {
          // A newer commit exists! Show update dialog
          if (context.mounted) {
            _showUpdateDialog(context);
          }
        } else {
          debugPrint('UpdateService: App is up to date.');
        }
      } else {
        debugPrint('UpdateService: Failed to fetch latest commit. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('UpdateService: Error checking for updates: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to acknowledge
      builder: (context) {
        return AlertDialog(
          title: const Text('✨ New Update Available!'),
          content: const Text(
            'A newer version of LoveSnaps is available.\n\n'
            'Would you like to download and install the latest features?',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final url = Uri.parse(_downloadUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  // Fallback to release page if direct APK link fails
                  final fallbackUrl = Uri.parse(_latestReleaseUrl);
                  await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Download Now'),
            ),
          ],
        );
      },
    );
  }
}
