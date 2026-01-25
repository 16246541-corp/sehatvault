import 'package:flutter/material.dart';
import '../../services/education_service.dart';
import 'education_modal.dart';
import '../design/glass_button.dart';
import '../design/liquid_glass_background.dart';
import '../../utils/theme.dart';

class EducationGate extends StatefulWidget {
  final String contentId;
  final Widget child;
  final bool blocking;

  const EducationGate({
    super.key,
    required this.contentId,
    required this.child,
    this.blocking = true,
  });

  @override
  State<EducationGate> createState() => _EducationGateState();
}

class _EducationGateState extends State<EducationGate> {
  bool _isCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkEducation();
  }

  Future<void> _checkEducation() async {
    final service = EducationService();
    await service.loadContent(widget.contentId);

    final completed = await service.isEducationCompleted(widget.contentId);
    if (mounted) {
      setState(() {
        _isCompleted = completed;
        _isLoading = false;
      });

      if (!_isCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showModal();
        });
      }
    }
  }

  Future<void> _showModal() async {
    await EducationModal.show(context, contentId: widget.contentId);
    if (mounted) {
      final completed =
          await EducationService().isEducationCompleted(widget.contentId);
      setState(() {
        _isCompleted = completed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (!widget.blocking || _isCompleted) {
      return widget.child;
    }

    return LiquidGlassBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school,
                    size: 48, color: AppTheme.accentTeal),
              ),
              const SizedBox(height: 24),
              Text(
                'Feature Education Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please complete the short introduction\nto access this feature.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
              const SizedBox(height: 32),
              GlassButton(
                label: 'Start Introduction',
                onPressed: _showModal,
                isProminent: true,
                tintColor: AppTheme.accentTeal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
