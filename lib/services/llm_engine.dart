import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/secure_logger.dart';
import '../models/model_option.dart';
import '../models/generation_parameters.dart';
import 'platform_detector.dart';
import 'token_counter_service.dart';
import 'analytics_service.dart';
import 'generation_parameters_service.dart';

/// Exception thrown by the LLMEngine.
class LLMEngineException implements Exception {
  final String message;
  final String? code;
  final bool isRecoverable;

  LLMEngineException(this.message, {this.code, this.isRecoverable = true});

  @override
  String toString() => 'LLMEngineException: $message (Code: $code)';
}

/// Metrics for model performance.
class ModelMetrics {
  final double loadTimeMs;
  final double tokensPerSecond;
  final int totalTokens;
  final double peakMemoryMb;
  final int contextTokens;
  final int maxContextTokens;

  ModelMetrics({
    required this.loadTimeMs,
    this.tokensPerSecond = 0,
    this.totalTokens = 0,
    this.peakMemoryMb = 0,
    this.contextTokens = 0,
    this.maxContextTokens = 0,
  });

  double get contextUsage =>
      maxContextTokens > 0 ? contextTokens / maxContextTokens : 0;
}

/// The core engine for GGUF model integration using llama_cpp.
class LLMEngine {
  static final LLMEngine _instance = LLMEngine._internal();
  factory LLMEngine() => _instance;
  LLMEngine._internal();

  LlamaParent? _llama;
  ModelOption? _currentModel;
  bool _isInitializing = false;
  final _initializationController = StreamController<double>.broadcast();
  final _metricsController = StreamController<ModelMetrics>.broadcast();
  final TokenCounterService _tokenCounter = TokenCounterService();

  int _maxContextTokens = 2048; // Default
  int get maxContextTokens => _maxContextTokens;

  /// Stream of initialization progress (0.0 to 1.0).
  Stream<double> get initializationProgress => _initializationController.stream;

  /// Stream of performance metrics updates.
  Stream<ModelMetrics> get metricsStream => _metricsController.stream;

  /// Performance metrics for the current session.
  ModelMetrics? _metrics;
  ModelMetrics? get metrics => _metrics;

  /// Lock for thread-safe access to the model.
  bool _isProcessing = false;

  /// The current active model.
  ModelOption? get currentModel => _currentModel;

  /// Initializes the LLM engine with a specific model.
  Future<void> initialize(ModelOption model, {bool forceReload = false}) async {
    if (_isInitializing) return;
    if (_currentModel?.id == model.id && _llama != null && !forceReload) return;

    _isInitializing = true;
    _initializationController.add(0.0);
    final stopwatch = Stopwatch()..start();

    try {
      SecureLogger.log("Initializing LLMEngine with model: ${model.name}");

      // 1. Validation: Checksum verification
      _initializationController.add(0.1);
      try {
        await _verifyChecksum(model);
      } catch (e) {
        if (e is LLMEngineException && e.code == 'CHECKSUM_MISMATCH') {
          throw LLMEngineException(
            "Model file corrupted. Please re-download.",
            code: 'CHECKSUM_MISMATCH',
            isRecoverable: false,
          );
        }
        rethrow;
      }
      _initializationController.add(0.3);

      // 2. Memory Management: Check resources
      final capabilities = await PlatformDetector().getCapabilities();

      // Determine context size based on RAM
      _maxContextTokens = 4096; // Standard
      if (capabilities.ramGB < 8) {
        _maxContextTokens = 2048;
      }
      if (capabilities.ramGB < 4) {
        _maxContextTokens = 1024;
      }

      if (capabilities.ramGB < model.ramRequired) {
        SecureLogger.log(
            "Warning: Device RAM (${capabilities.ramGB}GB) is below recommended (${model.ramRequired}GB)");
        if (capabilities.ramGB < model.ramRequired * 0.7) {
          throw LLMEngineException(
            "Insufficient RAM for this model. Required: ${model.ramRequired}GB, Available: ${capabilities.ramGB}GB",
            code: 'INSUFFICIENT_RAM',
            isRecoverable: false,
          );
        }
      }

      // 3. Fallback strategies for low-resource devices
      _initializationController.add(0.4);
      final contextParams = ContextParams();
      contextParams.nCtx = _maxContextTokens;

      // 4. Load the model using llama_cpp_dart's LlamaParent (Managed Isolate)
      _initializationController.add(0.5);

      // Get model path
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/models/${model.id}/model.gguf';
      final modelFile = File(modelPath);

      if (!await modelFile.exists()) {
        throw LLMEngineException("Model file not found at $modelPath",
            code: 'FILE_NOT_FOUND');
      }

      final genParams = GenerationParametersService().currentParameters;
      final samplerParams = SamplerParams();
      samplerParams.temp = genParams.temperature;
      samplerParams.topP = genParams.topP;
      samplerParams.topK = genParams.topK;
      // Note: presence/frequency penalty and seed might need to be handled during generation
      // depending on llama_cpp_dart version, but setting them here if supported.

      final loadCommand = LlamaLoad(
        path: modelPath,
        modelParams: ModelParams(),
        contextParams: contextParams,
        samplingParams: samplerParams,
      );

      try {
        _llama = LlamaParent(loadCommand, ChatMLFormat());
        await _llama!.init();
      } catch (e) {
        throw LLMEngineException(
          "Failed to initialize Llama backend: $e",
          code: 'BACKEND_INIT_FAILED',
          isRecoverable: true,
        );
      }

      _currentModel = model;
      stopwatch.stop();
      _metrics = ModelMetrics(
        loadTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
        maxContextTokens: _maxContextTokens,
      );

      _initializationController.add(1.0);
      SecureLogger.log(
          "LLMEngine initialized successfully in ${stopwatch.elapsedMilliseconds}ms with context size $_maxContextTokens");
    } catch (e) {
      SecureLogger.log("LLMEngine initialization failed: $e");
      _llama = null;
      _currentModel = null;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Strategic context management: Truncates history while preserving core content.
  String manageContext(String systemPrompt, List<Map<String, String>> history,
      String currentInput) {
    int systemTokens = _tokenCounter.countTokens(systemPrompt);
    int inputTokens = _tokenCounter.countTokens(currentInput);

    // Reserved tokens for response (approx 25% of context or at least 512)
    int reservedTokens = (_maxContextTokens * 0.25).round();
    if (reservedTokens < 512) reservedTokens = 512;

    int availableTokens =
        _maxContextTokens - systemTokens - inputTokens - reservedTokens;

    if (availableTokens <= 0) {
      SecureLogger.log("Critical context pressure: Input too large");
      // If even with zero history we are over, we must truncate input
      if (systemTokens + inputTokens + reservedTokens > _maxContextTokens) {
        int truncatedInputLen =
            (_maxContextTokens - systemTokens - reservedTokens) * 4;
        currentInput = currentInput.substring(
            0, truncatedInputLen.clamp(0, currentInput.length));
        availableTokens = 0;
      }
    }

    List<Map<String, String>> preservedHistory = [];
    int historyTokens = 0;

    // Add history from newest to oldest until we hit the limit
    for (var i = history.length - 1; i >= 0; i--) {
      String msgContent = history[i]['content'] ?? "";
      int msgTokens = _tokenCounter.countTokens(msgContent);

      if (historyTokens + msgTokens < availableTokens) {
        preservedHistory.insert(0, history[i]);
        historyTokens += msgTokens;
      } else {
        // Strategic Truncation: If it's a long message, try to keep the beginning and end
        if (preservedHistory.isEmpty &&
            msgTokens > availableTokens &&
            availableTokens > 100) {
          String truncated =
              _truncatePreservingEnds(msgContent, availableTokens);
          preservedHistory
              .insert(0, {'role': history[i]['role']!, 'content': truncated});
          historyTokens += availableTokens;
        }
        break; // Stop adding history
      }
    }

    // Analytics for context usage patterns
    AnalyticsService().logEvent(
      'token_usage_pattern',
      parameters: {
        'tokens': systemTokens + historyTokens + inputTokens,
        'max_tokens': _maxContextTokens,
        'usage_ratio': _metrics?.contextUsage ?? 0,
        'history_count': preservedHistory.length,
        'truncated': preservedHistory.length < history.length,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Update metrics
    _metrics = ModelMetrics(
      loadTimeMs: _metrics?.loadTimeMs ?? 0,
      tokensPerSecond: _metrics?.tokensPerSecond ?? 0,
      totalTokens: _metrics?.totalTokens ?? 0,
      contextTokens: systemTokens + historyTokens + inputTokens,
      maxContextTokens: _maxContextTokens,
    );

    // Notify listeners about metrics update
    _metricsController.add(_metrics!);

    // Format for ChatML (assuming the model expects this)
    StringBuffer prompt = StringBuffer();
    prompt.writeln("<|im_start|>system\n$systemPrompt<|im_end|>");
    for (var msg in preservedHistory) {
      prompt.writeln("<|im_start|>${msg['role']}\n${msg['content']}<|im_end|>");
    }
    prompt.writeln("<|im_start|>user\n$currentInput<|im_end|>");
    prompt.writeln("<|im_start|>assistant");

    return prompt.toString();
  }

  String _truncatePreservingEnds(String text, int targetTokens) {
    // Keep 40% from start, 40% from end, add ellipsis
    int targetChars = targetTokens * 4;
    int keepStart = (targetChars * 0.4).round();
    int keepEnd = (targetChars * 0.4).round();

    if (text.length <= targetChars) return text;

    return "${text.substring(0, keepStart)}\n... [truncated] ...\n${text.substring(text.length - keepEnd)}";
  }

  /// Compresses repetitive content in the context.
  String compressContent(String text) {
    // Simple deduplication of consecutive identical lines or phrases
    List<String> lines = text.split('\n');
    if (lines.length < 5) return text;

    List<String> compressed = [];
    String? lastLine;
    int repeatCount = 0;

    for (var line in lines) {
      String trimmed = line.trim();
      if (trimmed == lastLine) {
        repeatCount++;
        continue;
      }

      if (repeatCount > 0) {
        compressed.add("[Repeated $repeatCount times]");
        repeatCount = 0;
      }

      compressed.add(line);
      lastLine = trimmed;
    }

    return compressed.join('\n');
  }

  /// Verifies the checksum of the model file.
  Future<void> _verifyChecksum(ModelOption model) async {
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = '${directory.path}/models/${model.id}/model.gguf';
    final file = File(modelPath);
    if (!await file.exists()) return;

    SecureLogger.log("Verifying checksum for ${model.name}...");
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;
    final actualChecksum = hash.toString();

    // Check if checksum matches (removing 'sha256:' prefix if present)
    final expected = model.metadata.checksum.replaceFirst('sha256:', '');

    if (actualChecksum != expected) {
      throw LLMEngineException(
        "Checksum verification failed. Model file might be corrupted.",
        code: 'CHECKSUM_MISMATCH',
      );
    }
    SecureLogger.log("Checksum verified successfully.");
  }

  /// Generates a response stream for a given prompt.
  Stream<String> generate(String prompt) async* {
    if (_llama == null) {
      throw LLMEngineException("Engine not initialized",
          code: 'NOT_INITIALIZED');
    }

    if (_isProcessing) {
      throw LLMEngineException("Engine is already processing a request",
          code: 'BUSY');
    }

    _isProcessing = true;
    final stopwatch = Stopwatch()..start();
    int tokenCount = 0;

    try {
      try {
        _llama!.sendPrompt(prompt);
      } catch (e) {
        throw LLMEngineException(
          "Failed to send prompt to model: $e",
          code: 'INFERENCE_FAILED',
          isRecoverable: true,
        );
      }

      await for (final response in _llama!.stream) {
        tokenCount++;
        yield response;
      }

      stopwatch.stop();
      final seconds = stopwatch.elapsedMilliseconds / 1000.0;
      final tps = seconds > 0 ? tokenCount / seconds : 0.0;

      _metrics = ModelMetrics(
        loadTimeMs: _metrics?.loadTimeMs ?? 0,
        tokensPerSecond: tps,
        totalTokens: tokenCount,
        contextTokens: _metrics?.contextTokens ?? 0,
        maxContextTokens: _maxContextTokens,
      );

      SecureLogger.log(
          "Generation complete: $tokenCount tokens in ${seconds.toStringAsFixed(2)}s (${tps.toStringAsFixed(2)} tps)");
    } catch (e) {
      SecureLogger.log("Error during generation: $e");
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  /// Disposes of the model and resources.
  Future<void> dispose() async {
    SecureLogger.log("Disposing LLMEngine resources");
    await _llama?.dispose();
    _llama = null;
    _currentModel = null;
    _isProcessing = false;
  }

  /// Graceful degradation: Check if we should switch to a lighter model.
  bool shouldDegrade() {
    // Logic to determine if we are struggling (e.g., low TPS or memory pressure)
    if (_metrics != null &&
        _metrics!.tokensPerSecond < 1.0 &&
        _metrics!.tokensPerSecond > 0) {
      return true;
    }
    return false;
  }
}
