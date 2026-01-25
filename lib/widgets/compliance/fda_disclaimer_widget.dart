import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/glass_card.dart';
import '../../services/compliance_service.dart';
import '../../services/local_storage_service.dart';

class FdaDisclaimerWidget extends StatelessWidget {
  final double? fontSize;
  final TextStyle? tappableLinkStyle;
  final VoidCallback? onLinkTap;
  final EdgeInsetsGeometry? padding;
  final ComplianceService? complianceService;

  const FdaDisclaimerWidget({
    super.key,
    this.fontSize,
    this.tappableLinkStyle,
    this.onLinkTap,
    this.padding,
    this.complianceService,
  });

  static const String _disclaimerText =
      "FDA Disclaimer: This application is for informational purposes only and does not constitute medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textSize = fontSize ?? theme.textTheme.bodySmall?.fontSize ?? 12.0;

    // Log display if service is provided
    if (complianceService != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        complianceService!.logDisclaimerDisplay('FdaDisclaimerWidget');
      });
    }

    return Semantics(
      label: 'FDA Disclaimer',
      hint: 'Read the medical disclaimer',
      child: GlassCard(
        padding: padding ?? const EdgeInsets.all(12),
        backgroundColor: Colors.amber.withValues(alpha: 0.05),
        borderColor: Colors.amber.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.amber[700],
                  size: textSize * 1.5,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: textSize,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: _disclaimerText),
                        if (onLinkTap != null) ...[
                          const TextSpan(text: ' '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                onLinkTap!();
                              },
                              child: Text(
                                'Learn more',
                                style: tappableLinkStyle ??
                                    theme.textTheme.bodySmall?.copyWith(
                                      fontSize: textSize,
                                      color: theme.primaryColor,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
