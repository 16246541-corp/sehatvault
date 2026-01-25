import 'package:flutter/material.dart';
import '../../services/consent_service.dart';
import '../design/glass_card.dart';
import '../design/glass_button.dart';
import '../design/recording_disclaimer.dart';

class RecordingConsentDialog extends StatefulWidget {
  const RecordingConsentDialog({super.key});

  @override
  State<RecordingConsentDialog> createState() => _RecordingConsentDialogState();
}

class _RecordingConsentDialogState extends State<RecordingConsentDialog> {
  bool _isConfirmed = false;
  bool _isSaving = false;

  Future<void> _handleStart() async {
    setState(() => _isSaving = true);

    try {
      final service = ConsentService();
      // Load template content to ensure we hash exactly what we expect
      // In a real app, we might display this content dynamically
      final templateContent = await service.loadTemplate('recording', 'v1');

      await service.recordConsent(
        templateId: 'recording',
        version: 'v1',
        userId: 'local_user',
        scope: 'recording',
        granted: true,
        content: templateContent,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error saving consent: $e');
      // Proceed anyway or show error? For now proceed as fallback
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Recording',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              RecordingDisclaimer(
                onConfirmationChanged: (value) {
                  setState(() {
                    _isConfirmed = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  GlassButton(
                    label: _isSaving ? 'Starting...' : 'Start Recording',
                    onPressed: _isConfirmed && !_isSaving ? _handleStart : null,
                    isProminent: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
