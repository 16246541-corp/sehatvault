import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/analytics_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/permission_service.dart';
import '../../utils/theme.dart';
import '../../widgets/design/glass_button.dart';
import '../../widgets/onboarding/permission_card.dart';

import '../../services/onboarding_service.dart';


/// Data class for permission configuration
class PermissionData {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final bool isOptional;
  PermissionStatus status;

  PermissionData({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    this.isOptional = false,
    this.status = PermissionStatus.pending,
  });
}

/// Permissions request screen for guided permission onboarding
/// Requests camera, microphone, and notification permissions one at a time
class PermissionsRequestScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const PermissionsRequestScreen({
    super.key,
    required this.onComplete,
    this.onBack,
    this.onSkip,
  });

  @override
  State<PermissionsRequestScreen> createState() =>
      _PermissionsRequestScreenState();
}

class _PermissionsRequestScreenState extends State<PermissionsRequestScreen>
    with TickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();

  late List<PermissionData> _permissions;
  int _currentPermissionIndex = 0;
  bool _isLoading = true;
  bool _isRequesting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializePermissions();
    _initializeAnimations();
    _checkExistingPermissions();
  }

  void _initializePermissions() {
    _permissions = [
      PermissionData(
        id: 'camera',
        icon: Icons.camera_alt_rounded,
        title: 'Camera Access',
        description:
            'Scan medical documents, prescriptions, and lab reports directly with your camera for automatic text extraction and organization.',
        isOptional: false,
      ),
      PermissionData(
        id: 'microphone',
        icon: Icons.mic_rounded,
        title: 'Microphone Access',
        description:
            'Record doctor visits and medical consultations for accurate transcription and easy reference later.',
        isOptional: false,
      ),
      PermissionData(
        id: 'notification',
        icon: Icons.notifications_rounded,
        title: 'Notifications',
        description:
            'Get reminders for follow-up appointments, medication schedules, and important health milestones.',
        isOptional: true,
      ),
    ];
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  /// Check if running on a desktop platform (macOS, Windows, Linux)
  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  Future<void> _checkExistingPermissions() async {
    setState(() => _isLoading = true);

    // On desktop platforms, permissions work differently and permission_handler
    // may hang. Skip permission checking and auto-complete this step.
    if (_isDesktopPlatform) {
      debugPrint('PermissionsRequestScreen: Desktop platform detected, skipping permission checks');
      await _completePermissionsSetup();
      return;
    }

    // Check camera permission
    final cameraGranted = await PermissionService.isCameraPermissionGranted();
    final cameraPermanentlyDenied =
        await PermissionService.isCameraPermissionPermanentlyDenied();

    // Check microphone permission
    final micGranted = await PermissionService.isMicPermissionGranted();
    final micPermanentlyDenied =
        await PermissionService.isMicPermissionPermanentlyDenied();

    // Check notification permission
    final notificationGranted =
        await PermissionService.isNotificationPermissionGranted();
    final notificationPermanentlyDenied =
        await PermissionService.isNotificationPermissionPermanentlyDenied();

    setState(() {
      // Update camera status
      _permissions[0].status = cameraGranted
          ? PermissionStatus.granted
          : cameraPermanentlyDenied
              ? PermissionStatus.permanentlyDenied
              : PermissionStatus.pending;

      // Update microphone status
      _permissions[1].status = micGranted
          ? PermissionStatus.granted
          : micPermanentlyDenied
              ? PermissionStatus.permanentlyDenied
              : PermissionStatus.pending;

      // Update notification status
      _permissions[2].status = notificationGranted
          ? PermissionStatus.granted
          : notificationPermanentlyDenied
              ? PermissionStatus.permanentlyDenied
              : PermissionStatus.pending;

      // Find first non-granted permission
      _currentPermissionIndex = _findNextPendingIndex();

      _isLoading = false;
    });

    _fadeController.forward();
    await _logAnalytics('permissions_screen_viewed');
  }

  int _findNextPendingIndex() {
    for (int i = 0; i < _permissions.length; i++) {
      if (_permissions[i].status != PermissionStatus.granted) {
        return i;
      }
    }
    return _permissions.length; // All granted
  }

  Future<void> _logAnalytics(String event) async {
    await _analyticsService.logEvent(event);
  }

  Future<void> _requestCurrentPermission() async {
    if (_isRequesting || _currentPermissionIndex >= _permissions.length) return;

    setState(() => _isRequesting = true);

    final permission = _permissions[_currentPermissionIndex];
    bool granted = false;

    try {
      switch (permission.id) {
        case 'camera':
          granted = await PermissionService.requestCameraPermission();
          await _logAnalytics(
              granted ? 'permission_camera_granted' : 'permission_camera_denied');
          break;
        case 'microphone':
          // Note: We pass context for the existing mic permission flow
          if (!mounted) return;
          granted = await PermissionService.requestMicPermission(context);
          await _logAnalytics(
              granted ? 'permission_mic_granted' : 'permission_mic_denied');
          break;
        case 'notification':
          granted = await PermissionService.requestNotificationPermission();
          await _logAnalytics(granted
              ? 'permission_notification_granted'
              : 'permission_notification_denied');
          break;
      }

      if (!mounted) return;

      // Check if permanently denied
      bool permanentlyDenied = false;
      if (!granted) {
        switch (permission.id) {
          case 'camera':
            permanentlyDenied =
                await PermissionService.isCameraPermissionPermanentlyDenied();
            break;
          case 'microphone':
            permanentlyDenied =
                await PermissionService.isMicPermissionPermanentlyDenied();
            break;
          case 'notification':
            permanentlyDenied = await PermissionService
                .isNotificationPermissionPermanentlyDenied();
            break;
        }
      }

      setState(() {
        permission.status = granted
            ? PermissionStatus.granted
            : permanentlyDenied
                ? PermissionStatus.permanentlyDenied
                : PermissionStatus.denied;
      });

      // Move to next permission if granted or if optional permission was denied
      if (granted || (permission.isOptional && !granted)) {
        _moveToNextPermission();
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _moveToNextPermission() {
    final nextIndex = _currentPermissionIndex + 1;

    if (nextIndex < _permissions.length) {
      setState(() {
        _currentPermissionIndex = nextIndex;
      });
    } else {
      // All permissions handled
      _completePermissionsSetup();
    }
  }

  void _skipOptionalPermission() {
    final permission = _permissions[_currentPermissionIndex];

    if (permission.isOptional) {
      _logAnalytics('permission_${permission.id}_skipped');
      _moveToNextPermission();
    }
  }

  Future<void> _openSettings() async {
    await PermissionService.openSettings();

    // Recheck permissions after returning from settings
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _checkExistingPermissions();
    }
  }

  Future<void> _completePermissionsSetup() async {
    await OnboardingService().markStepCompleted(OnboardingStep.permissions);
    await _logAnalytics('permissions_setup_completed');

    if (mounted) {
      widget.onComplete();
    }
  }


  bool get _canContinue {
    // Check if all required permissions are granted
    for (final permission in _permissions) {
      if (!permission.isOptional &&
          permission.status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  bool get _allPermissionsHandled {
    return _currentPermissionIndex >= _permissions.length ||
        _permissions.every((p) =>
            p.status == PermissionStatus.granted ||
            (p.isOptional && p.status != PermissionStatus.pending));
  }

  int get _grantedCount {
    return _permissions.where((p) => p.status == PermissionStatus.granted).length;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          'App Permissions',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Grant permissions to unlock all features',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Progress indicator
                        _buildProgressIndicator(),

                        const SizedBox(height: 24),

                        // Permission cards
                        ..._buildPermissionCards(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Bottom action
                _buildBottomAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
              ),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          // Granted counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 14,
                  color: _grantedCount > 0
                      ? AppTheme.healthGreen
                      : Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_grantedCount/${_permissions.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          ..._permissions.asMap().entries.map((entry) {
            final index = entry.key;
            final permission = entry.value;
            final isGranted = permission.status == PermissionStatus.granted;
            final isCurrent = index == _currentPermissionIndex;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isGranted
                                ? AppTheme.healthGreen.withValues(alpha: 0.2)
                                : isCurrent
                                    ? AppTheme.accentTeal.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isGranted
                                  ? AppTheme.healthGreen
                                  : isCurrent
                                      ? AppTheme.accentTeal
                                      : Colors.white.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isGranted ? Icons.check_rounded : permission.icon,
                            color: isGranted
                                ? AppTheme.healthGreen
                                : isCurrent
                                    ? AppTheme.accentTeal
                                    : Colors.white.withValues(alpha: 0.5),
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          permission.id.toUpperCase().substring(0, 3),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isGranted
                                ? AppTheme.healthGreen
                                : isCurrent
                                    ? AppTheme.accentTeal
                                    : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < _permissions.length - 1)
                    Container(
                      width: 24,
                      height: 2,
                      color: isGranted
                          ? AppTheme.healthGreen.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildPermissionCards() {
    return _permissions.asMap().entries.map((entry) {
      final index = entry.key;
      final permission = entry.value;
      final isActive = index == _currentPermissionIndex &&
          permission.status != PermissionStatus.granted;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: PermissionCard(
          icon: permission.icon,
          title: permission.title,
          description: permission.description,
          status: permission.status,
          isOptional: permission.isOptional,
          isActive: isActive,
          onGrant: isActive && !_isRequesting ? _requestCurrentPermission : null,
          onOpenSettings: isActive ? _openSettings : null,
        ),
      );
    }).toList();
  }

  Widget _buildBottomAction() {
    final currentPermission = _currentPermissionIndex < _permissions.length
        ? _permissions[_currentPermissionIndex]
        : null;

    final showSkipButton = currentPermission?.isOptional == true &&
        currentPermission?.status != PermissionStatus.granted;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info/requirement text
          if (!_allPermissionsHandled && !_canContinue)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Camera and microphone are required',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

          // Skip button for optional permissions
          if (showSkipButton) ...[
            TextButton(
              onPressed: _skipOptionalPermission,
              child: Text(
                'Skip for Now',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Continue button
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: _allPermissionsHandled || _canContinue
                  ? 'Continue'
                  : 'Grant Required Permissions',
              icon: _allPermissionsHandled || _canContinue
                  ? Icons.arrow_forward_rounded
                  : Icons.security_rounded,
              onPressed: (_allPermissionsHandled || _canContinue)
                  ? _completePermissionsSetup
                  : null,
              isProminent: true,
              tintColor: (_allPermissionsHandled || _canContinue)
                  ? AppTheme.accentTeal
                  : Colors.grey.withValues(alpha: 0.5),
              isInteractive: _allPermissionsHandled || _canContinue,
            ),
          ),
        ],
      ),
    );
  }
}
