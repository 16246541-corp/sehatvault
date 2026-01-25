import 'package:flutter/material.dart';
import 'glass_button.dart';
import 'glass_effect_container.dart';
import '../../utils/theme.dart';
import '../../services/conversation_recorder_service.dart';

class RecordingControlWidget extends StatefulWidget {
  final ConversationRecorderService recorderService;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final bool isPaused;

  const RecordingControlWidget({
    super.key,
    required this.recorderService,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.isPaused,
  });

  @override
  State<RecordingControlWidget> createState() => _RecordingControlWidgetState();
}

class _RecordingControlWidgetState extends State<RecordingControlWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<RecorderProgress>(
      stream: widget.recorderService.onProgress,
      builder: (context, snapshot) {
        final duration = snapshot.hasData
            ? snapshot.data!.duration
            : const Duration(seconds: 0);
        final decibels = snapshot.hasData ? snapshot.data!.decibels : 0.0;

        // Normalize decibels for visualization (usually -160 to 0 or similar)
        // Let's assume a range and map it to 0.0 - 1.0
        // Typical speech might be around -30 to -10 dB?
        // FlutterSound might return different values depending on platform.
        // Let's use a dynamic visualizer that reacts to changes.
        final normalizedLevel = (decibels + 50).clamp(0.0, 50.0) / 50.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Timer & Visualizer
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Visual Mic Indicator (Pulse)
                  if (!widget.isPaused)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = 1.0 +
                            (normalizedLevel * 0.5 * _pulseController.value);
                        return Container(
                          width: 150 * pulse,
                          height: 150 * pulse,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentTeal
                                .withValues(alpha: 0.2 * normalizedLevel),
                          ),
                        );
                      },
                    ),

                  // Glass Container for Timer
                  GlassEffect(
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: 160,
                      height: 160,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accentTeal.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic,
                            size: 32,
                            color: widget.isPaused
                                ? theme.disabledColor
                                : AppTheme.accentTeal,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDuration(duration),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFeatures: [
                                const FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          if (widget.isPaused)
                            Text(
                              'PAUSED',
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.5,
                                color: theme.colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pause/Resume Button
                GlassButton(
                  label: widget.isPaused ? 'Resume' : 'Pause',
                  icon: widget.isPaused ? Icons.play_arrow : Icons.pause,
                  onPressed: widget.isPaused ? widget.onResume : widget.onPause,
                ),

                const SizedBox(width: 24),

                // Stop Button
                GlassButton(
                  label: 'Stop',
                  icon: Icons.stop,
                  isProminent: true,
                  tintColor: theme.colorScheme.error,
                  onPressed: widget.onStop,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
