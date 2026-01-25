import 'package:flutter/material.dart';
import '../../services/biometric_service.dart';
import '../../utils/theme.dart';
import '../design/glass_card.dart';

class BiometricEnrollmentDialog extends StatelessWidget {
  final VoidCallback onEnroll;
  final VoidCallback onUsePin;
  final VoidCallback onDismiss;

  const BiometricEnrollmentDialog({
    super.key,
    required this.onEnroll,
    required this.onUsePin,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fingerprint,
              size: 64,
              color: AppTheme.accentTeal,
            ),
            const SizedBox(height: 16),
            Text(
              'Enhance Your Security',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Biometrics are available on your device but not set up. Enable them to securely access your health data without typing a PIN every time.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onEnroll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Enroll Now'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onUsePin,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3)),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Use PIN Instead'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
              child: const Text('Not Now'),
            ),
          ],
        ),
      ),
    );
  }
}
