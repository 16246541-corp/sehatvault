import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/desktop/file_drop_zone.dart';
import '../widgets/design/recording_control_widget.dart';
import '../services/vault_service.dart';
import '../widgets/design/emergency_stop_button.dart';
import '../utils/design_constants.dart';
import '../widgets/ai/model_info_panel.dart';
import '../widgets/ai/token_usage_indicator.dart';
import '../widgets/compliance/knowledge_cutoff_notice.dart';
import '../models/model_option.dart';
import '../services/medical_field_extractor.dart';
import '../services/conversation_recorder_service.dart';
import '../services/transcription_service.dart';
import '../services/follow_up_extractor.dart';
import '../services/biometric_service.dart';
import '../services/battery_monitor_service.dart';
import '../services/session_manager.dart';
import '../services/local_audit_service.dart';
import 'package:sehatlocker/services/keyboard_shortcut_service.dart';
import '../models/doctor_conversation.dart';
import '../models/follow_up_item.dart';
import '../models/recording_audit_entry.dart';
import '../widgets/sheets/follow_up_review_sheet.dart';
import '../widgets/dialogs/recording_consent_dialog.dart';
import '../main_common.dart' show storageService;
import '../widgets/compliance/fda_disclaimer_widget.dart';
import '../widgets/compliance/emergency_use_banner.dart';
import 'issue_reporting_review_screen.dart';

/// AI Screen - Local LLM interface placeholder
class AIScreen extends StatefulWidget {
  final VoidCallback? onEmergencyExit;

  const AIScreen({
    super.key,
    this.onEmergencyExit,
  });

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final ConversationRecorderService _recorderService =
      ConversationRecorderService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final FollowUpExtractor _followUpExtractor = FollowUpExtractor();

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isProcessing = false;
  StreamSubscription? _recorderSubscription;
  Duration _lastDuration = Duration.zero;
  bool _lastConsentConfirmed = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    KeyboardShortcutService()
        .registerAction('record_start_stop', _handleToggleRecording);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SessionManager().showEducationIfNeeded('ai_features');
    });
  }

  Future<void> _initRecorder() async {
    await _recorderService.init();

    // Set up lifecycle callbacks
    _recorderService.onAutoStop = () {
      if (mounted) {
        _handleStopRecording();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Recording auto-stopped due to background inactivity')),
        );
      }
    };

    _recorderService.onPauseStateChanged = () {
      if (mounted) {
        setState(() {
          _isPaused = _recorderService.isPaused;
        });
      }
    };

    _recorderService.onCriticalBatteryStop = () {
      if (mounted) {
        _handleStopRecording();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Battery Critically Low'),
            content:
                const Text('Recording stopped to preserve battery and data.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    KeyboardShortcutService().unregisterAction('record_start_stop');
    _recorderSubscription?.cancel();
    _recorderService.dispose();
    super.dispose();
  }

  void _handleToggleRecording() {
    if (_isRecording) {
      _handleStopRecording();
    } else {
      _handleRecordingAction();
    }
  }

  Future<void> _handlePauseRecording() async {
    await _recorderService.pauseRecording();
    setState(() => _isPaused = true);
  }

  void _startAutoStopListener() {
    _stopAutoStopListener();
    _recorderSubscription = _recorderService.onProgress?.listen((e) {
      _lastDuration = e.duration;
      final settings = storageService.getAppSettings();
      final limit = settings.autoStopRecordingMinutes;
      if (e.duration.inMinutes >= limit) {
        _stopAutoStopListener(); // Stop listener immediately
        _handleStopRecording();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Recording auto-stopped after $limit minutes')),
          );
        }
      }
    });
  }

  void _stopAutoStopListener() {
    _recorderSubscription?.cancel();
    _recorderSubscription = null;
  }

  Future<void> _handleResumeRecording() async {
    bool authenticated = false;
    final biometricService = BiometricService();
    final settings = storageService.getAppSettings();

    if (!settings.enhancedPrivacySettings.requireBiometricsForSensitiveData) {
      authenticated = true;
    } else {
      try {
        authenticated = await biometricService.authenticate(
          reason: 'Authenticate to resume recording',
          sessionId: biometricService.sessionId,
        );
      } on BiometricAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
        return;
      }
    }

    if (authenticated) {
      await _recorderService.resumeRecording();
      setState(() => _isPaused = false);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required to resume')),
        );
      }
    }
  }

  Future<void> _handleStopRecording() async {
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _isProcessing = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/recording_$timestamp.wav.enc';

      await _recorderService.stopRecordingAndSaveEncrypted(
        destinationPath: path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording saved. Transcribing...')),
        );
      }

      try {
        final file = File(path);
        final size = await file.length();

        final deviceInfo = DeviceInfoPlugin();
        String deviceId = 'Unknown Device';
        if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'Unknown iOS Device';
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        }

        final auditEntry = RecordingAuditEntry(
          timestamp: DateTime.now(),
          duration: _lastDuration,
          consentConfirmed: _lastConsentConfirmed,
          doctorName: 'Unknown Doctor',
          fileSizeBytes: size,
          deviceId: deviceId,
        );

        await storageService.saveRecordingAuditEntry(auditEntry);
        await LocalAuditService(storageService, SessionManager()).log(
          action: 'recording_saved',
          details: {
            'durationSeconds': _lastDuration.inSeconds.toString(),
            'consentConfirmed': _lastConsentConfirmed.toString(),
            'fileSizeBytes': size.toString(),
          },
          sensitivity: 'warning',
        );
      } catch (e) {
        debugPrint('Error creating audit entry: $e');
      }

      // 1. Transcribe
      final encryptedFile = File(path);
      final transcriptionResult =
          await _transcriptionService.transcribeAudio(encryptedFile);

      // Check for dates after knowledge cutoff
      _checkTranscriptionForOutdatedKnowledge(transcriptionResult.fullText);

      // 2. Extract Items
      final conversationId = const Uuid().v4();
      final items = _followUpExtractor.extractFromTranscript(
        transcriptionResult.fullText,
        conversationId,
        segments: transcriptionResult.segments,
      );

      // 3. Review Items (if any)
      List<FollowUpItem> confirmedItems = items;
      if (items.isNotEmpty && mounted) {
        // Show review sheet
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FollowUpReviewSheet(
            items: items,
            onConfirm: (selected) {
              confirmedItems = selected;
              Navigator.pop(context);
            },
          ),
        );
      }

      // Save confirmed items
      for (final item in confirmedItems) {
        await storageService.saveFollowUpItem(item);
      }

      // 4. Save Conversation
      final conversation = DoctorConversation(
        id: conversationId,
        title: 'Conversation ${DateTime.now().toString().split(' ')[0]}',
        duration: _lastDuration.inSeconds,
        encryptedAudioPath: path,
        transcript: transcriptionResult.fullText,
        createdAt: DateTime.now(),
        followUpItems: confirmedItems.map((e) => e.id).toList(),
        doctorName: 'Unknown Doctor',
        segments: transcriptionResult.segments,
        complianceVersion: '1.0',
        complianceReviewDate: DateTime.now(),
        modelId: storageService.getAppSettings().selectedModelId,
      );

      await storageService.saveDoctorConversation(conversation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Saved with ${confirmedItems.length} follow-up items')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleEmergencyStop() async {
    // Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: const Text(
          'DELETE RECORDING?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This cannot be undone. All data will be permanently erased.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete & Exit',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _recorderService.emergencyStop();

      // Audit Log
      try {
        final auditEntry = RecordingAuditEntry(
          timestamp: DateTime.now(),
          duration: Duration.zero,
          consentConfirmed: _lastConsentConfirmed,
          doctorName: 'EMERGENCY DELETION',
          fileSizeBytes: 0,
          deviceId: 'Emergency Stop',
        );
        await storageService.saveRecordingAuditEntry(auditEntry);
        await LocalAuditService(storageService, SessionManager()).log(
          action: 'recording_emergency_delete',
          details: {
            'consentConfirmed': _lastConsentConfirmed.toString(),
            'reason': 'emergency_stop',
          },
          sensitivity: 'critical',
        );
      } catch (e) {
        debugPrint('Error saving emergency audit: $e');
      }

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording emergency deleted'),
            backgroundColor: Colors.red,
          ),
        );

        // Offer to report issue
        final reportIssue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Report Issue?'),
            content: const Text(
                'Would you like to anonymously report this incident to help improve safety?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Report')),
            ],
          ),
        );

        if (reportIssue == true && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const IssueReportingReviewScreen(
                description: 'Emergency Stop Triggered',
                isEmergency: true,
              ),
            ),
          );
        }

        widget.onEmergencyExit?.call();
      }
    }
  }

  Future<void> _handleRecordingAction() async {
    if (_isRecording) {
      await _handleStopRecording();
    } else {
      // Start Recording
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => const RecordingConsentDialog(),
      );

      if (confirmed == true) {
        // Battery Check
        if (storageService.getAppSettings().enableBatteryWarnings) {
          final warning =
              await BatteryMonitorService().checkPreRecordingBattery();
          if (warning != null && mounted) {
            final proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Low Battery Warning'),
                content: Text(warning),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
            if (proceed != true) {
              _lastConsentConfirmed = false;
              return;
            }
          }
        }

        try {
          _lastConsentConfirmed = true;
          await _recorderService.startRecording();
          await LocalAuditService(storageService, SessionManager()).log(
            action: 'recording_start',
            details: {
              'consentConfirmed': _lastConsentConfirmed.toString(),
            },
            sensitivity: 'warning',
          );
          _startAutoStopListener();
          setState(() {
            _isRecording = true;
            _isPaused = false;
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to start recording: $e')),
            );
          }
        }
      } else {
        _lastConsentConfirmed = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: LiquidGlassBackground(
        child: FileDropZone(
          vaultService: VaultService(storageService),
          settings: storageService.getAppSettings(),
          child: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(
                      DesignConstants.pageHorizontalPadding),
                  child: _isProcessing
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Processing conversation...'),
                            ],
                          ),
                        )
                      : _isRecording
                          ? Center(
                              child: RecordingControlWidget(
                                recorderService: _recorderService,
                                onStop: _handleStopRecording,
                                onPause: _handlePauseRecording,
                                onResume: _handleResumeRecording,
                                isPaused: _isPaused,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 60),
                                const SizedBox(
                                    height: DesignConstants.titleTopPadding),
                                Text(
                                  'AI Assistant',
                                  style: theme.textTheme.displayMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Powered by local LLM • Your data stays on device',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(
                                    height: DesignConstants.sectionSpacing),
                                const ModelInfoPanel(compact: true),
                                _buildKnowledgeCutoffNotice(),
                                const SizedBox(
                                    height: DesignConstants.sectionSpacing),
                                Text(
                                  'Quick Actions',
                                  style: theme.textTheme.headlineLarge,
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      _buildQuickAction(
                                        context,
                                        icon: _isRecording
                                            ? Icons.stop_circle_outlined
                                            : Icons.mic_outlined,
                                        title: _isRecording
                                            ? 'Stop Recording'
                                            : 'Record Conversation',
                                        description: _isRecording
                                            ? 'Tap to stop and save'
                                            : 'Securely record and analyze a conversation',
                                        onTap: _handleRecordingAction,
                                        isActive: _isRecording,
                                      ),
                                      _buildQuickAction(context,
                                          icon: Icons.summarize_outlined,
                                          title: 'Summarize Document',
                                          description:
                                              'Get a quick summary of any health document'),
                                      _buildQuickAction(context,
                                          icon: Icons.translate,
                                          title: 'Explain Medical Terms',
                                          description:
                                              'Understand complex medical terminology'),
                                      _buildQuickAction(context,
                                          icon: Icons.compare_arrows,
                                          title: 'Compare Results',
                                          description:
                                              'Track changes in your lab results over time'),
                                      _buildQuickAction(context,
                                          icon: Icons.search,
                                          title: 'Search Records',
                                          description:
                                              'Find information across all your documents'),
                                      _buildQuickAction(
                                        context,
                                        icon: Icons.history,
                                        title: 'View History',
                                        description:
                                            'Access past conversations',
                                        onTap: () {
                                          // Navigate to Documents tab
                                          // This might need a callback to parent to switch tabs
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 24.0),
                                        child: FdaDisclaimerWidget(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              if (_isRecording)
                EmergencyStopButton(onTap: _handleEmergencyStop),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignConstants.pageHorizontalPadding,
                      vertical: 8.0,
                    ),
                    child: EmergencyUseBanner(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkTranscriptionForOutdatedKnowledge(String text) {
    final settings = storageService.getAppSettings();
    final modelId = settings.selectedModelId;
    final model = ModelOption.availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => ModelOption.availableModels.first,
    );

    if (model.knowledgeCutoffDate == null) return;

    final extracted = MedicalFieldExtractor.extractDates(text);
    final dates = extracted['dates'] as List;

    bool hasRecentDate = false;
    for (var dateEntry in dates) {
      try {
        final dateValue = dateEntry['value'] as String;
        // Simple date parsing attempt
        DateTime? date;
        if (dateValue.contains('-')) {
          date = DateTime.tryParse(dateValue);
        } else if (dateValue.contains('/')) {
          final parts = dateValue.split('/');
          if (parts.length == 3) {
            // Assume DD/MM/YYYY or MM/DD/YYYY - this is a simplification
            final y = int.tryParse(parts[2]);
            if (y != null) {
              date = DateTime(y);
            }
          }
        }

        if (date != null && date.isAfter(model.knowledgeCutoffDate!)) {
          hasRecentDate = true;
          break;
        }
      } catch (_) {}
    }

    if (hasRecentDate) {
      // Show warning or trigger re-show of cutoff notice
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Note: This conversation mentions dates after ${model.name}\'s knowledge cutoff.'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              onPressed: () {
                // Show a dialog or expand the notice
                _showCutoffDetailsDialog(model);
              },
            ),
          ),
        );
      }
    }
  }

  void _showCutoffDetailsDialog(ModelOption model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Knowledge Cutoff Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KnowledgeCutoffNotice(model: model, forceShow: true),
            const SizedBox(height: 16),
            const Text(
              'The AI model used for this analysis has a knowledge cutoff date. It may not be aware of medical research or guidelines published after this date.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeCutoffNotice() {
    final settings = storageService.getAppSettings();
    final modelId = settings.selectedModelId;
    final model = ModelOption.availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => ModelOption.availableModels.first,
    );

    final isDismissed =
        settings.dismissedKnowledgeCutoffModelIds.contains(modelId);

    if (isDismissed) {
      return const SizedBox.shrink();
    }

    return KnowledgeCutoffNotice(
      model: model,
      onDismiss: () {
        final newSettings = storageService.getAppSettings();
        if (!newSettings.dismissedKnowledgeCutoffModelIds.contains(modelId)) {
          newSettings.dismissedKnowledgeCutoffModelIds.add(modelId);
          newSettings.save();
          setState(() {});
        }
      },
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap ??
            () {
              // TODO: Handle action
            },
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: isActive ? Colors.red : theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.red : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!isActive)
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}
