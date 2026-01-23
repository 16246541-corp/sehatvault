import 'package:flutter/material.dart';
import '../../models/model_option.dart';
import '../../utils/theme.dart';
import '../design/glass_card.dart';
import '../design/glass_button.dart';
import '../../main.dart' show storageService;
import '../../services/model_manager.dart';
import '../../screens/model_selection_screen.dart';

class ModelStatusCard extends StatefulWidget {
  const ModelStatusCard({super.key});

  @override
  State<ModelStatusCard> createState() => _ModelStatusCardState();
}

class _ModelStatusCardState extends State<ModelStatusCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Get latest settings
    final settings = storageService.getAppSettings();
    
    // Find matching model or default to first
    final currentModel = ModelOption.availableModels.firstWhere(
      (m) => m.id == settings.selectedModelId,
      orElse: () => ModelOption.availableModels.first,
    );

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.psychology,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentModel.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Active Language Model',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              GlassButton(
                label: 'Change',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ModelSelectionScreen()),
                  );
                  // Refresh state when coming back
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                icon: Icons.memory,
                label: 'Est. RAM',
                value: '${currentModel.ramRequired} GB',
              ),
              _buildStatItem(
                context,
                icon: Icons.storage,
                label: 'Storage',
                value: '${currentModel.storageRequired} GB',
              ),
              FutureBuilder<bool>(
                future: ModelManager.isModelDownloaded(currentModel.id),
                builder: (context, snapshot) {
                  final isReady = snapshot.data ?? false;
                  return _buildStatItem(
                    context,
                    icon: isReady ? Icons.offline_bolt : Icons.download_for_offline,
                    label: 'Status',
                    value: isReady ? 'Ready' : 'Not Loaded',
                    valueColor: isReady ? AppTheme.healthGreen : AppTheme.warningOrange,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 14, 
              color: theme.colorScheme.primary.withValues(alpha: 0.7)
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
