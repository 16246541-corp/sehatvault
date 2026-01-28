import 'package:flutter/material.dart';
import '../../models/document_extraction.dart';
import '../../models/health_record.dart';
import '../../utils/category_utils.dart';
import '../../utils/design_constants.dart';
import '../../widgets/design/glass_card.dart';
import '../../widgets/design/glass_button.dart';

class DocumentCategorizationContent extends StatefulWidget {
  final DocumentExtraction extraction;
  final HealthCategory? suggestedCategory;
  final double confidence;
  final String reasoning;
  final Function(HealthCategory) onSave;
  final VoidCallback onCancel;

  const DocumentCategorizationContent({
    super.key,
    required this.extraction,
    required this.suggestedCategory,
    required this.confidence,
    required this.reasoning,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<DocumentCategorizationContent> createState() =>
      _DocumentCategorizationContentState();
}

class _DocumentCategorizationContentState
    extends State<DocumentCategorizationContent> {
  late HealthCategory? _selectedCategory;
  bool _showFullText = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.suggestedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: DesignConstants.pageHorizontalPadding,
        vertical: DesignConstants.pageVerticalPadding,
      ).copyWith(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // OCR Preview Section
          _buildOCRPreview(context, theme, isDark),
          const SizedBox(height: 20),

          // Suggestion Badge
          if (widget.suggestedCategory != null && widget.confidence >= 0.4)
            _buildSuggestionBadge(context, theme, isDark)
          else
            _buildNoConfidenceBadge(context, theme, isDark),
          const SizedBox(height: 20),

          // Category Selection
          _buildCategorySelection(context, theme, isDark),
          const SizedBox(height: 30),

          // Actions
          _buildActions(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOCRPreview(
      BuildContext context, ThemeData theme, bool isDark) {
    final text = widget.extraction.extractedText;
    final displayText =
        _showFullText ? text : (text.length > 200 ? text.substring(0, 200) + '...' : text);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EXTRACTED TEXT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Monospace',
                height: 1.4,
              ),
            ),
            if (text.length > 200) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _showFullText = !_showFullText;
                  });
                },
                child: Text(
                  _showFullText ? 'Show Less' : 'Show Full Text',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionBadge(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Suggested: ${widget.suggestedCategory?.displayName}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${(widget.confidence * 100).toInt()}% confidence',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.reasoning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoConfidenceBadge(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
          Text(
            'No confident suggestion',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection(
      BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT CATEGORY',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<HealthCategory>(
          value: _selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? Colors.black26 : Colors.white70,
          ),
          items: HealthCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Icon(category.icon, size: 18),
                  const SizedBox(width: 12),
                  Text(category.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          hint: const Text('Choose a category...'),
        ),
        const SizedBox(height: 8),
        Text(
          'You control how documents are organized. Suggestions are informational only.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassButton(
            onPressed: widget.onCancel,
            label: 'Discard',
            icon: Icons.delete_outline,
            isProminent: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassButton(
            onPressed: _selectedCategory != null
                ? () => widget.onSave(_selectedCategory!)
                : null,
            label: 'Add to Vault',
            icon: Icons.shield,
            isProminent: true,
          ),
        ),
      ],
    );
  }
}
