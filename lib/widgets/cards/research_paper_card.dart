import 'package:flutter/material.dart';
import 'category_badge.dart';
import 'card_image_section.dart';
import 'card_content_section.dart';

/// Research Paper Card for swiping through papers
/// Full-screen card with image at top and content overlay at bottom
class ResearchPaperCard extends StatelessWidget {
  final String? imageUrl;
  final String category;
  final String title;
  final String? abstract;
  final String? source;
  final String? publishedDate;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onTap;
  final Widget? actionButtons;
  final Widget? floatingWidget;

  const ResearchPaperCard({
    super.key,
    this.imageUrl,
    required this.category,
    required this.title,
    this.abstract,
    this.source,
    this.publishedDate,
    this.onTap,
    this.actionButtons,
    this.floatingWidget,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.40; // 40% for image, 60% for content
    
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe Left - Dismiss
          onSwipeLeft?.call();
          return false;
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe Right - Save
          onSwipeRight?.call();
          return false;
        }
        return false;
      },
      background: _buildSwipeBackground(
        context,
        alignment: Alignment.centerLeft,
        icon: Icons.bookmark_add,
        label: 'Save',
        color: const Color(0xFF10B981), // Green
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        alignment: Alignment.centerRight,
        icon: Icons.close,
        label: 'Skip',
        color: const Color(0xFFEF4444), // Red
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Stack(
            children: [
              Column(
                children: [
                  // Image section (40% of screen)
                  CardImageSection(
                    imageUrl: imageUrl,
                    height: imageHeight,
                    badge: CategoryBadge(label: category),
                  ),
                  
                  // Content section (60% of screen)
                  Expanded(
                    child: CardContentSection(
                      title: title,
                      description: abstract,
                      source: source,
                      footerText: publishedDate,
                      actionButtons: actionButtons,
                      onTap: onTap,
                    ),
                  ),
                ],
              ),
              
              // Floating widget (e.g., save button)
              if (floatingWidget != null)
                Positioned(
                  top: imageHeight - 24,
                  right: 16,
                  child: floatingWidget!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(
    BuildContext context, {
    required Alignment alignment,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      color: color.withValues(alpha: 0.2),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
