import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class SecurityCompletionCard extends StatelessWidget {
  final bool biometricEnabled;
  final bool pinSet;
  final bool recoveryQuestionSet;

  const SecurityCompletionCard({
    super.key,
    required this.biometricEnabled,
    required this.pinSet,
    required this.recoveryQuestionSet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.healthGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppTheme.healthGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Security Checklist',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCheckItem(
            context,
            'AES-256 encryption enabled',
            true, // Always true as per requirements
          ),
          _buildCheckItem(
            context,
            'Biometric authentication enabled',
            biometricEnabled,
          ),
          _buildCheckItem(
            context,
            'PIN fallback configured',
            pinSet,
          ),
          _buildCheckItem(
            context,
            'Recovery question set',
            recoveryQuestionSet,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String label, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isChecked ? AppTheme.healthGreen : Colors.white.withValues(alpha: 0.3),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isChecked ? Colors.white : Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                decoration: isChecked ? null : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
