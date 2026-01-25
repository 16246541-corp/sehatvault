import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// Status enum for permission cards
enum PermissionStatus {
  pending,
  granted,
  denied,
  permanentlyDenied,
}

/// A beautiful permission card widget for onboarding flow
/// Shows icon, title, description, status indicator, and grant button
class PermissionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final PermissionStatus status;
  final VoidCallback? onGrant;
  final VoidCallback? onOpenSettings;
  final bool isOptional;
  final bool isActive;

  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    this.onGrant,
    this.onOpenSettings,
    this.isOptional = false,
    this.isActive = false,
  });

  @override
  State<PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<PermissionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isActive && widget.status == PermissionStatus.pending) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PermissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && widget.status == PermissionStatus.pending) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGranted = widget.status == PermissionStatus.granted;
    final isDenied = widget.status == PermissionStatus.denied;
    final isPermanentlyDenied =
        widget.status == PermissionStatus.permanentlyDenied;
    final isPending = widget.status == PermissionStatus.pending;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isActive ? _pulseAnimation.value : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getBorderColor(isGranted, isDenied, isPermanentlyDenied),
                width: widget.isActive ? 2 : 1,
              ),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.accentTeal.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with icon, title, and status
                Row(
                  children: [
                    // Icon container
                    _buildIconContainer(isGranted, isDenied || isPermanentlyDenied),

                    const SizedBox(width: 16),

                    // Title and optional badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (widget.isOptional) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Optional',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 13,
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status indicator
                    _buildStatusIndicator(
                        isGranted, isDenied, isPermanentlyDenied, isPending),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),

                // Action button
                if (widget.isActive && !isGranted) ...[
                  const SizedBox(height: 20),
                  _buildActionButton(isPermanentlyDenied),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBorderColor(bool isGranted, bool isDenied, bool isPermanentlyDenied) {
    if (isGranted) {
      return AppTheme.healthGreen.withValues(alpha: 0.5);
    }
    if (isDenied || isPermanentlyDenied) {
      return AppTheme.warningOrange.withValues(alpha: 0.5);
    }
    if (widget.isActive) {
      return AppTheme.accentTeal.withValues(alpha: 0.5);
    }
    return Colors.white.withValues(alpha: 0.1);
  }

  Widget _buildIconContainer(bool isGranted, bool isDeniedOrPermanent) {
    Color bgColor;
    Color iconColor;

    if (isGranted) {
      bgColor = AppTheme.healthGreen.withValues(alpha: 0.2);
      iconColor = AppTheme.healthGreen;
    } else if (isDeniedOrPermanent) {
      bgColor = AppTheme.warningOrange.withValues(alpha: 0.2);
      iconColor = AppTheme.warningOrange;
    } else if (widget.isActive) {
      bgColor = AppTheme.accentTeal.withValues(alpha: 0.2);
      iconColor = AppTheme.accentTeal;
    } else {
      bgColor = Colors.white.withValues(alpha: 0.08);
      iconColor = Colors.white.withValues(alpha: 0.6);
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        widget.icon,
        color: iconColor,
        size: 26,
      ),
    );
  }

  Widget _buildStatusIndicator(
      bool isGranted, bool isDenied, bool isPermanentlyDenied, bool isPending) {
    if (isGranted) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.healthGreen.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppTheme.healthGreen,
          size: 18,
        ),
      );
    }

    if (isDenied || isPermanentlyDenied) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.warningOrange.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPermanentlyDenied ? Icons.settings_rounded : Icons.close_rounded,
          color: AppTheme.warningOrange,
          size: 18,
        ),
      );
    }

    if (isPending && widget.isActive) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.accentTeal.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.pending_rounded,
          color: AppTheme.accentTeal,
          size: 18,
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.circle_outlined,
        color: Colors.white.withValues(alpha: 0.4),
        size: 18,
      ),
    );
  }

  String _getStatusText() {
    switch (widget.status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied';
      case PermissionStatus.permanentlyDenied:
        return 'Requires settings change';
      case PermissionStatus.pending:
        return widget.isActive ? 'Tap to grant' : 'Waiting...';
    }
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case PermissionStatus.granted:
        return AppTheme.healthGreen;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return AppTheme.warningOrange;
      case PermissionStatus.pending:
        return widget.isActive ? AppTheme.accentTeal : Colors.white54;
    }
  }

  Widget _buildActionButton(bool isPermanentlyDenied) {
    if (isPermanentlyDenied) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.onOpenSettings,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.warningOrange,
            side: BorderSide(
              color: AppTheme.warningOrange.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.settings_rounded, size: 18),
          label: const Text(
            'Open Settings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onGrant,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.security_rounded, size: 18),
        label: const Text(
          'Grant Permission',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Animation builder widget for complex animations
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilderImpl(
      animation: animation,
      builder: builder,
    );
  }
}

class AnimatedBuilderImpl extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilderImpl({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
