import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests microphone permission with platform-specific rationale handling.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  static Future<bool> requestMicPermission(BuildContext context) async {
    // Check current status
    PermissionStatus status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(context);
      }
      return false;
    }

    // Show rationale if needed (mainly for Android)
    if (await Permission.microphone.shouldShowRequestRationale) {
      if (context.mounted) {
        final bool shouldRequest = await _showRationaleDialog(context);
        if (!shouldRequest) return false;
      }
    }

    // Request permission
    status = await Permission.microphone.request();

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(context);
      }
      return false;
    }

    return false;
  }

  static Future<bool> _showRationaleDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Microphone Permission'),
            content: const Text(
                'We need microphone access to provide voice guidance during document scanning. This helps you capture better images.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
            'Microphone access is permanently denied. Please enable it in the app settings to use voice features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
