import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import '../../../models/app_settings.dart';
import '../../../models/health_pattern_insight.dart';
import '../../../services/file_drop_service.dart';
import '../../../services/health_intelligence_engine.dart';
import '../../../services/local_audit_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/medical_field_extractor.dart';
import '../../../services/reference_range_service.dart';
import '../../../services/safety_filter_service.dart';
import '../../../services/session_manager.dart';
import '../../../shared/widgets/health_insight_card.dart';
import '../../../widgets/auth_gate.dart';
import '../../../widgets/compliance/emergency_use_banner.dart';
import '../../../widgets/compliance/fda_disclaimer_widget.dart';
import '../../../widgets/design/glass_card.dart';
import '../../../widgets/design/responsive_center.dart';

class HealthInsightsSidebar extends StatefulWidget {
  const HealthInsightsSidebar({super.key});

  @override
  State<HealthInsightsSidebar> createState() => _HealthInsightsSidebarState();
}

class _HealthInsightsSidebarState extends State<HealthInsightsSidebar> {
  final LocalStorageService _storage = LocalStorageService();
  final FileDropService _fileDropService = FileDropService();

  bool _isDragging = false;
  bool _isLoading = true;
  String? _error;
  List<HealthPatternInsight> _insights = const [];
  List<HealthPatternInsight>? _ephemeralInsights;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _ephemeralInsights = null;
    });

    try {
      final engine = HealthIntelligenceEngine(
        storage: _storage,
        fieldExtractor: MedicalFieldExtractor(),
        referenceRanges: ReferenceRangeService(),
        safetyFilter: SafetyFilterService(),
        auditLogger: LocalAuditService(_storage, SessionManager()),
      );

      final insights = await engine.detectAndPersistInsights(force: force);
      if (!mounted) return;
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeEphemeralFile(File file, AppSettings settings) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _ephemeralInsights = null;
    });

    try {
      final text = await _fileDropService.extractTextForOneTimeAnalysis(
        file,
        settings: settings,
      );
      final engine = HealthIntelligenceEngine(
        storage: _storage,
        fieldExtractor: MedicalFieldExtractor(),
        referenceRanges: ReferenceRangeService(),
        safetyFilter: SafetyFilterService(),
        auditLogger: LocalAuditService(_storage, SessionManager()),
      );

      final ephemeral = await engine.detectInsightsForEphemeralText(
        sourceTitle: p.basename(file.path),
        sourceDate: DateTime.now(),
        extractedText: text,
      );

      if (!mounted) return;
      setState(() {
        _ephemeralInsights = ephemeral;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, _, __) {
        final settings = _storage.getAppSettings();
        return AuthGate(
          enabled: settings
              .enhancedPrivacySettings.requireBiometricsForSensitiveData,
          reason: 'Authenticate to access Health Insights',
          child: ResponsiveCenter(
            maxContentWidth: 800,
            child: DropTarget(
              onDragEntered: (_) => setState(() => _isDragging = true),
              onDragExited: (_) => setState(() => _isDragging = false),
              onDragDone: (details) async {
                setState(() => _isDragging = false);
                if (details.files.isEmpty) return;
                await _analyzeEphemeralFile(
                    File(details.files.first.path), settings);
              },
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EmergencyUseBanner(),
                        const SizedBox(height: 8),
                        const FdaDisclaimerWidget(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Health Insights',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            IconButton(
                              onPressed:
                                  _isLoading ? null : () => _load(force: true),
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Analyze again',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Drop a PDF/TXT/Image here for one-time analysis',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildBody(settings),
                        ),
                      ],
                    ),
                  ),
                  if (_isDragging) _buildDropOverlay(settings),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(AppSettings settings) {
    if (!settings.enhancedPrivacySettings.showHealthInsights) {
      return Text(
        'Health Insights are turned off in Privacy settings.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Text(
        _error!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      );
    }

    final items = _ephemeralInsights ?? _insights;
    if (items.isEmpty) {
      return Text(
        'No insights available yet.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return ListView.builder(
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 24),
            child: FdaDisclaimerWidget(),
          );
        }
        final insight = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HealthInsightCard(insight: insight),
        );
      },
    );
  }

  Widget _buildDropOverlay(AppSettings settings) {
    return Positioned.fill(
      child: Center(
        child: GlassCard(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.upload_file_rounded, size: 56),
              const SizedBox(height: 12),
              Text(
                'Drop for one-time analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'PDF, TXT, JPG, PNG (Max ${settings.maxFileUploadSizeMB}MB)',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
