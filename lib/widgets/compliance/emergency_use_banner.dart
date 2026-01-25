import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import '../../services/session_manager.dart';
import '../design/glass_banner.dart';

class EmergencyUseBanner extends StatefulWidget {
  const EmergencyUseBanner({super.key});

  @override
  State<EmergencyUseBanner> createState() => _EmergencyUseBannerState();
}

class _EmergencyUseBannerState extends State<EmergencyUseBanner> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = SessionManager().onResume.listen((_) {
      if (mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          _announcementText(),
          Directionality.of(context),
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warningColor = Colors.amber[700]!;

    return Focus(
      autofocus: true,
      child: Semantics(
        label: _semanticsLabel(),
        hint: _semanticsHint(),
        container: true,
        focused: true,
        child: GlassBanner(
          backgroundColor: Colors.amber.withValues(alpha: 0.15),
          onTap: () {
            Feedback.forTap(context);
            _showDetailedExplanation(context);
          },
          isDismissible: false,
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: warningColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _bannerTitle(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber[700]),
            const SizedBox(width: 8),
            Expanded(child: Text(_dialogTitle())),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint(
                context,
                _detailBulletPersonalReference(),
              ),
              _buildBulletPoint(
                context,
                _detailBulletNoReplacement(),
              ),
              _buildBulletPoint(
                context,
                _detailBulletEmergencyCall(),
              ),
              _buildBulletPoint(
                context,
                _detailBulletNoCriticalDecisions(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_dialogAcknowledge()),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _bannerTitle() => Intl.message(
        'Not for Medical Emergencies',
        name: 'emergencyUseBannerTitle',
      );

  String _semanticsLabel() => Intl.message(
        'Emergency Use Disclaimer',
        name: 'emergencyUseBannerSemanticsLabel',
      );

  String _semanticsHint() => Intl.message(
        'Double tap for details',
        name: 'emergencyUseBannerSemanticsHint',
      );

  String _dialogTitle() => Intl.message(
        'Important Safety Notice',
        name: 'emergencyUseBannerDialogTitle',
      );

  String _dialogAcknowledge() => Intl.message(
        'I Understand',
        name: 'emergencyUseBannerDialogAcknowledge',
      );

  String _announcementText() => Intl.message(
        'Emergency Use Warning: Not for Medical Emergencies',
        name: 'emergencyUseBannerAnnouncement',
      );

  String _detailBulletPersonalReference() => Intl.message(
        'This app is for documentation and personal reference only.',
        name: 'emergencyUseBannerDetailPersonalReference',
      );

  String _detailBulletNoReplacement() => Intl.message(
        'It does NOT replace professional medical advice, diagnosis, or treatment.',
        name: 'emergencyUseBannerDetailNoReplacement',
      );

  String _detailBulletEmergencyCall() => Intl.message(
        'In case of a medical emergency, call your local emergency number (e.g., 911) immediately.',
        name: 'emergencyUseBannerDetailEmergencyCall',
      );

  String _detailBulletNoCriticalDecisions() => Intl.message(
        'Do not rely on this app for critical health decisions.',
        name: 'emergencyUseBannerDetailNoCriticalDecisions',
      );
}
