import 'package:flutter/material.dart';
import '../design/glass_card.dart';
import '../design/glass_button.dart';

class RecordingConsentDialog extends StatefulWidget {
  const RecordingConsentDialog({super.key});

  @override
  State<RecordingConsentDialog> createState() => _RecordingConsentDialogState();
}

class _RecordingConsentDialogState extends State<RecordingConsentDialog> {
  bool _isConfirmed = false;

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
              Text(
                'Please confirm that you have consent to record this conversation.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              
              // Consent Checkbox
              InkWell(
                onTap: () {
                  setState(() {
                    _isConfirmed = !_isConfirmed;
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: _isConfirmed,
                      onChanged: (value) {
                        setState(() {
                          _isConfirmed = value ?? false;
                        });
                      },
                      activeColor: theme.primaryColor,
                    ),
                    Expanded(
                      child: Text(
                        'I confirm this is my private conversation',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    label: 'Start Recording',
                    onPressed: _isConfirmed
                        ? () => Navigator.of(context).pop(true)
                        : null,
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
