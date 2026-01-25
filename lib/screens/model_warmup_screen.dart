import 'package:flutter/material.dart';
import '../models/model_option.dart';
import '../services/llm_engine.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/design/glass_progress_bar.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../utils/design_constants.dart';
import '../utils/theme.dart';

class ModelWarmupScreen extends StatefulWidget {
  final ModelOption model;
  final VoidCallback onComplete;

  const ModelWarmupScreen({
    super.key,
    required this.model,
    required this.onComplete,
  });

  @override
  State<ModelWarmupScreen> createState() => _ModelWarmupScreenState();
}

class _ModelWarmupScreenState extends State<ModelWarmupScreen> {
  final LLMEngine _engine = LLMEngine();
  String _statusMessage = "Preparing AI engine...";
  double _progress = 0.0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startWarmup();
  }

  Future<void> _startWarmup() async {
    try {
      // Listen to progress updates
      _engine.initializationProgress.listen((progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _updateStatusMessage(progress);
          });
        }
      });

      // Start initialization
      await _engine.initialize(widget.model);

      if (mounted) {
        // Wait a bit to show 100% progress
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _updateStatusMessage(double progress) {
    if (progress < 0.1) {
      _statusMessage = "Initializing engine...";
    } else if (progress < 0.3) {
      _statusMessage = "Verifying model integrity...";
    } else if (progress < 0.5) {
      _statusMessage = "Checking system resources...";
    } else if (progress < 0.8) {
      _statusMessage = "Loading model into memory...";
    } else if (progress < 1.0) {
      _statusMessage = "Finalizing configuration...";
    } else {
      _statusMessage = "Ready!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidGlassBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(DesignConstants.standardPadding),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(
                      DesignConstants.pageHorizontalPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.psychology,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: DesignConstants.standardPadding),
                      Text(
                        "Local AI Warmup",
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                      ),
                      const SizedBox(
                          height: DesignConstants.headlineBodySpacing / 2),
                      Text(
                        "Setting up ${widget.model.name} for secure offline processing.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                      ),
                      const SizedBox(height: DesignConstants.sectionSpacing),
                      if (_hasError) ...[
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.healthRed,
                          size: 48,
                        ),
                        const SizedBox(height: DesignConstants.standardPadding),
                        Text(
                          "Initialization Failed",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.healthRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(
                            height: DesignConstants.headlineBodySpacing / 2),
                        Text(
                          _errorMessage ?? "An unknown error occurred.",
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: DesignConstants.standardPadding),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Go Back"),
                        ),
                      ] else ...[
                        GlassProgressBar(
                          value: _progress,
                          activeColor: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: DesignConstants.standardPadding),
                        Text(
                          _statusMessage,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(
                            height: DesignConstants.headlineBodySpacing / 2),
                        Text(
                          "${(_progress * 100).toInt()}%",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
