import 'dart:async';
import 'package:flutter/material.dart';
import '../models/model_option.dart';
import '../services/model_warmup_service.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/design/glass_progress_bar.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../utils/design_constants.dart';

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
  final ModelWarmupService _warmupService = ModelWarmupService();
  late StreamSubscription<WarmupState> _stateSubscription;
  WarmupState _currentState = WarmupState.initial();

  @override
  void initState() {
    super.initState();
    _stateSubscription = _warmupService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });

        if (state.status == WarmupStatus.completed) {
          _onComplete();
        }
      }
    });

    // Start warmup automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmupService.startWarmup(widget.model);
    });
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    super.dispose();
  }

  void _onComplete() async {
    // Wait a bit to show 100% progress
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      widget.onComplete();
    }
  }

  Future<bool> _handlePop() async {
    if (_currentState.status == WarmupStatus.completed ||
        _currentState.status == WarmupStatus.failed ||
        _currentState.status == WarmupStatus.cancelled) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Warm-up?'),
        content: const Text(
            'The AI engine is currently preparing for your first session. Cancelling will delay your ability to use offline AI features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Warm-up'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Anyway',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _warmupService.cancelWarmup();
    }
    return result ?? false;
  }

  String _getStatusMessage() {
    final quantization = widget.model.metadata.quantization.label;
    switch (_currentState.status) {
      case WarmupStatus.idle:
        return "Preparing...";
      case WarmupStatus.initializing:
        return "Initializing AI engine...";
      case WarmupStatus.loading:
        return "Loading ${widget.model.name} ($quantization) into memory...";
      case WarmupStatus.verifying:
        return "Verifying model integrity...";
      case WarmupStatus.completed:
        return "AI Engine Ready!";
      case WarmupStatus.failed:
        return "Warm-up Failed";
      case WarmupStatus.cancelled:
        return "Warm-up Cancelled";
    }
  }

  String _getTimeEstimateString() {
    if (_currentState.status == WarmupStatus.completed) return "Ready";
    if (_currentState.status == WarmupStatus.failed) return "Error";
    if (_currentState.status == WarmupStatus.cancelled) return "Cancelled";

    final remaining = _currentState.estimatedTimeRemaining;
    if (remaining.inSeconds <= 0) return "Almost done...";

    return "Estimated: ${remaining.inSeconds}s remaining";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handlePop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: LiquidGlassBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignConstants.standardPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWarmupCard(),
                    const SizedBox(height: DesignConstants.sectionSpacing),
                    _buildEducationalContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarmupCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'model_icon_${widget.model.id}',
              child: Icon(
                _currentState.status == WarmupStatus.failed
                    ? Icons.error_outline
                    : Icons.psychology,
                size: 64,
                color: _currentState.status == WarmupStatus.failed
                    ? Colors.red
                    : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getStatusMessage(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getTimeEstimateString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 32),
            GlassProgressBar(
              value: _currentState.progress,
            ),
            if (_currentState.status == WarmupStatus.failed) ...[
              const SizedBox(height: 16),
              Text(
                _currentState.errorMessage ?? "An unknown error occurred",
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _warmupService.startWarmup(widget.model),
                child: const Text("Retry Warm-up"),
              ),
            ],
            if (_currentState.status != WarmupStatus.completed &&
                _currentState.status != WarmupStatus.failed &&
                _currentState.status != WarmupStatus.cancelled) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  final shouldPop = await _handlePop();
                  if (shouldPop && mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text("Cancel",
                    style: TextStyle(color: Colors.white60)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalContent() {
    return Column(
      children: [
        _buildEduItem(
          Icons.security,
          "Privacy First",
          "Your medical data never leaves your device. All AI processing happens locally.",
        ),
        const SizedBox(height: 16),
        _buildEduItem(
          Icons.wifi_off,
          "Works Offline",
          "Once warmed up, you can get AI insights without an internet connection.",
        ),
        const SizedBox(height: 16),
        _buildEduItem(
          Icons.speed,
          "Low Latency",
          "On-device AI provides faster responses compared to cloud-based solutions.",
        ),
        const SizedBox(height: 16),
        _buildEduItem(
          Icons.layers_outlined,
          "Smart Quantization",
          "We use ${widget.model.metadata.quantization.label} to balance intelligence and speed for your device.",
        ),
      ],
    );
  }

  Widget _buildEduItem(IconData icon, String title, String description) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.white70),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
