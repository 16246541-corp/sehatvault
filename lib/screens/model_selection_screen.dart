import 'package:flutter/material.dart';
import '../models/model_option.dart';
import '../models/app_settings.dart';
import '../services/model_manager.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../utils/design_constants.dart';
import '../utils/theme.dart';
import '../widgets/dialogs/model_error_dialog.dart';
import '../services/biometric_service.dart';
import '../services/consent_service.dart';
import '../services/local_audit_service.dart';
import '../services/session_manager.dart';
import '../main.dart' show storageService;

class ModelSelectionScreen extends StatefulWidget {
  const ModelSelectionScreen({super.key});

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  AppSettings? _settings;
  ModelOption? _recommendedModel;
  bool _isDownloading = false;
  String? _downloadingModelId;
  Map<String, bool> _downloadedModels = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = storageService.getAppSettings();
    final recommended = await ModelManager.getRecommendedModel();

    final downloaded = <String, bool>{};
    for (var model in ModelOption.availableModels) {
      final isDown = await ModelManager.isModelDownloaded(
        model.id,
        version: settings.modelMetadataMap[model.id]?.version,
      );
      downloaded[model.id] = isDown;
    }

    setState(() {
      _settings = settings;
      _recommendedModel = recommended;
      _downloadedModels = downloaded;
    });
  }

  void _onAutoSelectChanged(bool value) async {
    if (_settings == null) return;

    // Biometric Check
    if (_settings!.enhancedPrivacySettings.requireBiometricsForModelChange) {
      final biometricService = BiometricService();
      try {
        final authenticated = await biometricService.authenticate(
          reason: 'Authenticate to change AI model settings',
          sessionId: biometricService.sessionId,
        );
        if (!authenticated) return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Authentication failed: $e')),
          );
        }
        return;
      }
    }

    final hasConsent = await _ensureModelUsageConsent();
    if (!hasConsent) return;

    setState(() {
      _settings!.autoSelectModel = value;
      if (value && _recommendedModel != null) {
        _settings!.selectedModelId = _recommendedModel!.id;
      }
    });
    await storageService.saveAppSettings(_settings!);
    await LocalAuditService(storageService, SessionManager()).log(
      action: 'model_auto_select',
      details: {
        'enabled': value.toString(),
        'selectedModelId': _settings!.selectedModelId,
      },
      sensitivity: 'warning',
    );
  }

  void _onModelSelected(ModelOption model) async {
    if (_settings == null || _settings!.autoSelectModel || _isDownloading)
      return;

    // Biometric Check
    if (_settings!.enhancedPrivacySettings.requireBiometricsForModelChange) {
      final biometricService = BiometricService();
      try {
        final authenticated = await biometricService.authenticate(
          reason: 'Authenticate to change AI model',
          sessionId: biometricService.sessionId,
        );
        if (!authenticated) return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Authentication failed: $e')),
          );
        }
        return;
      }
    }

    final hasConsent = await _ensureModelUsageConsent();
    if (!hasConsent) return;

    setState(() {
      _isDownloading = true;
      _downloadingModelId = model.id;
    });

    try {
      final installedVersion = _settings!.modelMetadataMap[model.id]?.version;

      final success = await ModelManager.downloadModelIfNotExists(
        model,
        installedVersion: installedVersion,
      );

      if (success) {
        // Update stored metadata to reflect the currently installed version
        _settings!.modelMetadataMap[model.id] = model.metadata;
        _settings!.selectedModelId = model.id;
        await storageService.saveAppSettings(_settings!);
        await LocalAuditService(storageService, SessionManager()).log(
          action: 'model_change',
          details: {
            'selectedModelId': model.id,
            'autoSelect': _settings!.autoSelectModel.toString(),
          },
          sensitivity: 'warning',
        );

        // Update local download status
        setState(() {
          _downloadedModels[model.id] = true;
        });

        // Simulate background loading using compute()
        debugPrint('Initializing ${model.name} in background...');
        final loaded = await ModelManager.loadModel(model);

        if (loaded && mounted) {
          setState(() {}); // Refresh UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${model.name} is ready and loaded'),
              backgroundColor: AppTheme.healthGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final lighterModel = e is ModelLoadException && e.isStorageIssue
            ? _findLighterModel(model)
            : null;

        String title = 'Error';
        if (e is ModelLoadException) {
          if (e.isStorageIssue) title = 'Storage Full';
          if (e.isIntegrityIssue) title = 'Integrity Check Failed';
        }

        showDialog(
          context: context,
          builder: (context) => ModelErrorDialog(
            title: title,
            message: e is ModelLoadException
                ? e.message
                : 'An unexpected error occurred while loading the model.',
            lighterModel: lighterModel,
            onSwitch: lighterModel != null
                ? () => _onModelSelected(lighterModel)
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingModelId = null;
        });
      }
    }
  }

  ModelOption? _findLighterModel(ModelOption current) {
    // Find the largest model that is smaller than the current one
    final candidates = ModelOption.availableModels
        .where((m) => m.storageRequired < current.storageRequired)
        .toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.storageRequired.compareTo(a.storageRequired));
    return candidates.first;
  }

  Future<bool> _ensureModelUsageConsent() async {
    final consentService = ConsentService();
    if (consentService.hasValidConsent('model_usage')) {
      return true;
    }

    final content = await consentService.loadTemplate('model_usage', 'v1');
    if (!mounted) return false;

    final granted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('AI Model Usage Consent'),
            content: SingleChildScrollView(child: Text(content)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Deny'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Allow'),
              ),
            ],
          ),
        ) ??
        false;

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consent required to change models')),
        );
      }
      return false;
    }

    await consentService.recordConsent(
      templateId: 'model_usage',
      version: 'v1',
      userId: 'local_user',
      scope: 'model_usage',
      granted: true,
      content: content,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('AI Model Selection'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Auto-select Toggle
              Padding(
                padding:
                    const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
                child: GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-select',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Optimized for your device RAM',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Switch(
                        value: _settings!.autoSelectModel,
                        onChanged: _onAutoSelectChanged,
                        activeTrackColor:
                            AppTheme.accentTeal.withValues(alpha: 0.5),
                        activeThumbColor: AppTheme.accentTeal,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Scrollable List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.pageHorizontalPadding,
                    vertical: 16,
                  ),
                  itemCount: ModelOption.availableModels.length,
                  itemBuilder: (context, index) {
                    final model = ModelOption.availableModels[index];
                    final isSelected = _settings!.selectedModelId == model.id;
                    final isRecommended = _recommendedModel?.id == model.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassCard(
                        onTap: _settings!.autoSelectModel || _isDownloading
                            ? null
                            : () => _onModelSelected(model),
                        backgroundColor: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : null,
                        borderColor: isSelected ? AppTheme.primaryColor : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Radio Button / Status Icon
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _isDownloading &&
                                      _downloadingModelId == model.id
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                            AppTheme.primaryColor),
                                      ),
                                    )
                                  : _settings!.autoSelectModel
                                      ? isSelected
                                          ? const Icon(Icons.check_circle,
                                              color: AppTheme.healthGreen)
                                          : Icon(
                                              Icons.circle_outlined,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.3),
                                            )
                                      : GestureDetector(
                                          onTap: _settings!.autoSelectModel ||
                                                  _isDownloading
                                              ? null
                                              : () => _onModelSelected(model),
                                          child: Icon(
                                            isSelected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_unchecked,
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.5),
                                            size: 24,
                                          ),
                                        ),
                            ),
                            const SizedBox(width: 12),
                            // Model Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        model.name,
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : null,
                                        ),
                                      ),
                                      if (isRecommended) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.healthGreen
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Recommended',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: AppTheme.healthGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    model.description,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildSpecChip(
                                        context,
                                        Icons.memory,
                                        'RAM: ${model.ramRequired}GB',
                                      ),
                                      const SizedBox(width: 12),
                                      _buildSpecChip(
                                        context,
                                        Icons.storage,
                                        'Disk: ${model.storageRequired}GB',
                                      ),
                                      if (_downloadedModels[model.id] ==
                                          true) ...[
                                        const SizedBox(width: 12),
                                        _buildSpecChip(
                                          context,
                                          Icons.offline_pin_outlined,
                                          'Cached',
                                          color: AppTheme.healthGreen,
                                        ),
                                      ],
                                      if (model.isDesktopOnly) ...[
                                        const SizedBox(width: 12),
                                        _buildSpecChip(
                                          context,
                                          Icons.desktop_mac,
                                          'Desktop Only',
                                          color: AppTheme.warningOrange,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecChip(BuildContext context, IconData icon, String label,
      {Color? color}) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: chipColor.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: chipColor.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
