import 'package:flutter/material.dart';
import '../../utils/design_constants.dart';

/// Content section for research paper cards
class CardContentSection extends StatelessWidget {
  final String title;
  final String? description;
  final String? source;
  final String? footerText;
  final Widget? actionButtons;
  final VoidCallback? onTap;

  const CardContentSection({
    super.key,
    required this.title,
    this.description,
    this.source,
    this.footerText,
    this.actionButtons,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: DesignConstants.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: theme.textTheme.headlineLarge,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          if (description != null) ...[
            const SizedBox(height: DesignConstants.headlineBodySpacing),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  description!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],

          // Footer with source and actions
          if (source != null ||
              footerText != null ||
              actionButtons != null) ...[
            const SizedBox(height: DesignConstants.sectionSpacing),
            Row(
              children: [
                if (source != null)
                  Expanded(
                    child: Text(
                      source!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (footerText != null)
                  Text(
                    footerText!,
                    style: theme.textTheme.labelMedium,
                  ),
              ],
            ),
            if (actionButtons != null) ...[
              const SizedBox(height: DesignConstants.standardPadding),
              actionButtons!,
            ],
          ],
        ],
      ),
    );
  }
}
