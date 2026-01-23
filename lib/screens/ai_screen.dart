import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/design/recording_control_widget.dart';
import '../utils/design_constants.dart';
import '../widgets/cards/model_status_card.dart';
import '../services/conversation_recorder_service.dart';
import '../widgets/dialogs/recording_consent_dialog.dart';
import '../main.dart'; // for storageService

/// AI Screen - Local LLM interface placeholder
class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final ConversationRecorderService _recorderService = ConversationRecorderService();
  bool _isRecording = false;
  bool _isPaused = false;
  StreamSubscription? _recorderSubscription;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorderService.init();
  }

  @override
  void dispose() {
    _recorderService.dispose();
    super.dispose();
  }

  Future<void> _handlePauseRecording() async {
    await _recorderService.pauseRecording();
    setState(() => _isPaused = true);
  }

  void _startAutoStopListener() {
    _stopAutoStopListener();
    _recorderSubscription = _recorderService.onProgress?.listen((e) {
      final settings = storageService.getAppSettings();
      final limit = settings.autoStopRecordingMinutes;
      if (e.duration.inMinutes >= limit) {
        _stopAutoStopListener(); // Stop listener immediately
        _handleStopRecording();
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recording auto-stopped after $limit minutes')),
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
    await _recorderService.resumeRecording();
    setState(() => _isPaused = false);
  }

  Future<void> _handleStopRecording() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/recording_$timestamp.wav.enc';
      
      // Using a dummy key for now - in production this should be securely managed
      // 32 chars = 256 bits
      const key = '12345678901234567890123456789012'; 
      
      await _recorderService.stopRecordingAndSaveEncrypted(
        destinationPath: path,
        encryptionKey: key,
      );
      
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording saved securely')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
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
        try {
          await _recorderService.startRecording();
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
          child: _isRecording
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
              const SizedBox(height: DesignConstants.titleTopPadding),
              Text(
                'AI Assistant',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Powered by local LLM • Your data stays on device',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: DesignConstants.sectionSpacing),
              
              // AI Status Card
              const ModelStatusCard(),
              
              const SizedBox(height: DesignConstants.sectionSpacing),
              
              // Quick Actions
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
                      icon: _isRecording ? Icons.stop_circle_outlined : Icons.mic_outlined,
                      title: _isRecording ? 'Stop Recording' : 'Record Conversation',
                      description: _isRecording 
                          ? 'Tap to stop and save' 
                          : 'Securely record and analyze a conversation',
                      onTap: _handleRecordingAction,
                      isActive: _isRecording,
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.summarize_outlined,
                      title: 'Summarize Document',
                      description: 'Get a quick summary of any health document',
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.translate,
                      title: 'Explain Medical Terms',
                      description: 'Understand complex medical terminology',
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.compare_arrows,
                      title: 'Compare Results',
                      description: 'Track changes in your lab results over time',
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.search,
                      title: 'Search Records',
                      description: 'Find information across all your documents',
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
        onTap: onTap ?? () {
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
