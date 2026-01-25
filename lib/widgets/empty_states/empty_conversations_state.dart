import 'package:flutter/material.dart';
import '../../utils/design_constants.dart';
import '../design/glass_button.dart';

class EmptyConversationsState extends StatefulWidget {
  final VoidCallback onRecordTap;
  final bool showOnboarding;

  const EmptyConversationsState({
    super.key,
    required this.onRecordTap,
    this.showOnboarding = false,
  });

  @override
  State<EmptyConversationsState> createState() =>
      _EmptyConversationsStateState();
}

class _EmptyConversationsStateState extends State<EmptyConversationsState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.showOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dynamic tooltip = _buttonKey.currentState;
        tooltip?.ensureTooltipVisible();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.pageHorizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulse Animation & Icon
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.15),
                          theme.colorScheme.secondary.withOpacity(0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.mic_none_outlined,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Secondary Text
            Text(
              'Record and transcribe your appointments for personal reference',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),

            // Primary Button with Tooltip
            Tooltip(
              key: _buttonKey,
              message:
                  'Privacy First: Recordings are encrypted and never leave your device.',
              preferBelow: false,
              triggerMode: TooltipTriggerMode.manual,
              child: Semantics(
                label: 'Start recording doctor visit',
                button: true,
                hint: 'Opens the recording screen',
                child: GlassButton(
                  label: '+ Record Doctor Visit',
                  onPressed: widget.onRecordTap,
                  isProminent: true,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Disclaimer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'All audio stays on your device and is encrypted at rest',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
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
