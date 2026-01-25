import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/design_constants.dart';
import 'glass_button.dart';

class EmergencyStopButton extends StatelessWidget {
  final VoidCallback onTap;

  const EmergencyStopButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: DesignConstants.pageHorizontalPadding,
      bottom: DesignConstants.pageHorizontalPadding +
          80, // Positioned above bottom nav/controls
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.cancel_presentation_rounded, // or warning/close
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
