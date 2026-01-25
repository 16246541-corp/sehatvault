import 'package:flutter/material.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/cards/research_paper_card.dart';
import '../utils/design_constants.dart';

/// News Screen - Research papers with card swiping
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int _currentIndex = 0;

  // Sample research papers data
  final List<Map<String, String>> _papers = [
    {
      'category': 'Cardiology',
      'title': 'New Advances in Heart Disease Prevention',
      'abstract':
          'This comprehensive study examines the latest breakthroughs in cardiovascular disease prevention, including lifestyle interventions, novel pharmaceuticals, and emerging technologies for early detection.',
      'source': 'Journal of Cardiology',
      'date': 'Jan 2026',
    },
    {
      'category': 'Nutrition',
      'title': 'The Role of Gut Microbiome in Mental Health',
      'abstract':
          'Recent research reveals significant connections between gut bacteria composition and mental health outcomes. This paper explores the gut-brain axis and its implications for treating depression and anxiety.',
      'source': 'Nature Medicine',
      'date': 'Dec 2025',
    },
    {
      'category': 'Sleep Medicine',
      'title': 'Optimizing Sleep for Cognitive Performance',
      'abstract':
          'A meta-analysis of sleep optimization techniques and their measurable effects on memory consolidation, learning capacity, and overall cognitive function in adults.',
      'source': 'Sleep Research Society',
      'date': 'Nov 2025',
    },
    {
      'category': 'Immunology',
      'title': 'mRNA Technology Beyond Vaccines',
      'abstract':
          'Exploring the expanding applications of mRNA technology in treating cancer, autoimmune diseases, and rare genetic disorders. A look at current clinical trials and future possibilities.',
      'source': 'Cell Reports Medicine',
      'date': 'Jan 2026',
    },
  ];

  void _onSwipeRight() {
    // Save paper
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved: ${_papers[_currentIndex]['title']}'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 1),
      ),
    );
    _nextPaper();
  }

  void _onSwipeLeft() {
    // Skip paper
    _nextPaper();
  }

  void _nextPaper() {
    if (_currentIndex < _papers.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // Reset to beginning for demo
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_papers.isEmpty) {
      return LiquidGlassBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No papers available',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final paper = _papers[_currentIndex];

    return Stack(
      children: [
        ResearchPaperCard(
          category: paper['category']!,
          title: paper['title']!,
          abstract: paper['abstract'],
          source: paper['source'],
          publishedDate: paper['date'],
          onSwipeRight: _onSwipeRight,
          onSwipeLeft: _onSwipeLeft,
          actionButtons: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.close,
                label: 'Skip',
                color: const Color(0xFFEF4444),
                onTap: _onSwipeLeft,
              ),
              const SizedBox(width: 32),
              _buildActionButton(
                icon: Icons.bookmark_add,
                label: 'Save',
                color: const Color(0xFF10B981),
                onTap: _onSwipeRight,
              ),
            ],
          ),
        ),
        // Paper counter
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentIndex + 1} / ${_papers.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius:
              BorderRadius.circular(DesignConstants.buttonCornerRadius),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
