import 'package:flutter/material.dart';
import '../../models/education_content.dart';
import '../../services/education_service.dart';
import '../../utils/theme.dart';
import '../design/glass_card.dart';
import '../design/glass_button.dart';

class EducationModal extends StatefulWidget {
  final EducationContent content;
  final VoidCallback onCompleted;

  const EducationModal({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  static Future<void> show(BuildContext context,
      {required String contentId}) async {
    final service = EducationService();
    if (await service.isEducationCompleted(contentId)) return;

    final content = await service.loadContent(contentId);
    if (content == null) {
      return;
    }
    await service.logEducationDisplayed(contentId);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EducationModal(
        content: content,
        onCompleted: () {
          service.markEducationCompleted(contentId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  State<EducationModal> createState() => _EducationModalState();
}

class _EducationModalState extends State<EducationModal> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.content.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onCompleted();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.content.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: widget.content.pages.length,
                  itemBuilder: (context, index) {
                    final page = widget.content.pages[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Semantics(
                        label: '${page.title}. ${page.description}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (page.imageAsset != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Semantics(
                                  image: true,
                                  label: page.title,
                                  child: Image.asset(
                                    page.imageAsset!,
                                    height: 180,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            if (page.iconName != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Semantics(
                                  label: page.title,
                                  child: Icon(
                                    _getIcon(page.iconName),
                                    size: 80,
                                    color: AppTheme.accentTeal,
                                  ),
                                ),
                              ),
                            Text(
                              page.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page.description,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.content.pages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? AppTheme.accentTeal
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: GlassButton(
                              onPressed: _previousPage,
                              label: 'Back',
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: 16),
                        Expanded(
                          child: GlassButton(
                            onPressed: _nextPage,
                            isProminent: true,
                            tintColor: AppTheme.accentTeal,
                            label:
                                _currentPage == widget.content.pages.length - 1
                                    ? 'I Understand'
                                    : 'Next',
                          ),
                        ),
                      ],
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

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'security':
        return Icons.security;
      case 'lock':
        return Icons.lock;
      case 'scanner':
        return Icons.document_scanner;
      case 'mic':
        return Icons.mic;
      case 'ai':
        return Icons.auto_awesome;
      case 'cloud_off':
        return Icons.cloud_off;
      case 'privacy_tip':
        return Icons.privacy_tip;
      case 'storage':
        return Icons.storage;
      case 'fingerprint':
        return Icons.fingerprint;
      case 'verified_user':
        return Icons.verified_user;
      default:
        return Icons.info;
    }
  }
}
