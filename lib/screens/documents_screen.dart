import 'package:flutter/material.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../utils/design_constants.dart';

/// Documents Screen - Health documents storage
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DesignConstants.titleTopPadding),
              Text(
                'Documents',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your health records, stored locally',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: DesignConstants.sectionSpacing),
              
              // Document categories
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: DesignConstants.gridSpacing,
                  crossAxisSpacing: DesignConstants.gridSpacing,
                  children: [
                    _buildDocumentCategory(
                      context,
                      icon: Icons.medical_services_outlined,
                      title: 'Medical Records',
                      count: 0,
                    ),
                    _buildDocumentCategory(
                      context,
                      icon: Icons.science_outlined,
                      title: 'Lab Results',
                      count: 0,
                    ),
                    _buildDocumentCategory(
                      context,
                      icon: Icons.medication_outlined,
                      title: 'Prescriptions',
                      count: 0,
                    ),
                    _buildDocumentCategory(
                      context,
                      icon: Icons.vaccines_outlined,
                      title: 'Vaccinations',
                      count: 0,
                    ),
                    _buildDocumentCategory(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: 'Insurance',
                      count: 0,
                    ),
                    _buildDocumentCategory(
                      context,
                      icon: Icons.add_circle_outline,
                      title: 'Add Category',
                      count: -1, // Special indicator
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCategory(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
  }) {
    final theme = Theme.of(context);
    final isAddButton = count == -1;

    return GlassCard(
      onTap: () {
        // TODO: Navigate to category detail
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: isAddButton
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isAddButton) ...[
            const SizedBox(height: 4),
            Text(
              '$count files',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ],
      ),
    );
  }
}
