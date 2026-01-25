import 'package:flutter/material.dart';

class RecordingDisclaimer extends StatefulWidget {
  final ValueChanged<bool> onConfirmationChanged;
  final bool initialValue;

  const RecordingDisclaimer({
    super.key,
    required this.onConfirmationChanged,
    this.initialValue = false,
  });

  @override
  State<RecordingDisclaimer> createState() => _RecordingDisclaimerState();
}

class _RecordingDisclaimerState extends State<RecordingDisclaimer> {
  late bool _isConfirmed;

  static const String _disclaimer =
      "This recording and transcript are for your personal reference only. "
      "They do not constitute medical advice, diagnosis, or treatment. "
      "Always consult with qualified healthcare professionals for medical decisions. "
      "Do not share sensitive information you wouldn't want stored on your device.";

  @override
  void initState() {
    super.initState();
    _isConfirmed = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.amber[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _disclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            setState(() {
              _isConfirmed = !_isConfirmed;
              widget.onConfirmationChanged(_isConfirmed);
            });
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _isConfirmed,
                    onChanged: (value) {
                      setState(() {
                        _isConfirmed = value ?? false;
                        widget.onConfirmationChanged(_isConfirmed);
                      });
                    },
                    activeColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "I understand this is for personal use only",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
