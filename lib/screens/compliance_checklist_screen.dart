import 'package:flutter/material.dart';
import '../services/compliance_service.dart';
import '../services/export_service.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../utils/design_constants.dart';
import '../utils/theme.dart';
import '../main_common.dart' show storageService;
import '../widgets/auth_gate.dart';
import 'package:url_launcher/url_launcher.dart';

class ComplianceChecklistScreen extends StatefulWidget {
  const ComplianceChecklistScreen({super.key});

  @override
  State<ComplianceChecklistScreen> createState() =>
      _ComplianceChecklistScreenState();
}

class _ComplianceChecklistScreenState extends State<ComplianceChecklistScreen> {
  late final ComplianceService _complianceService;
  final ExportService _exportService = ExportService();

  bool _isLoading = true;
  List<ComplianceCheckResult>? _results;
  ComplianceReport? _lastReport;

  @override
  void initState() {
    super.initState();
    _complianceService = ComplianceService(storageService);
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() => _isLoading = true);
    final results = await _complianceService.runComplianceChecks();
    final report = _complianceService.generateReport(results);
    if (mounted) {
      setState(() {
        _results = results;
        _lastReport = report;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportReport() async {
    if (_lastReport == null) return;
    await _exportService.exportComplianceChecklist(context, _lastReport!);
  }

  @override
  Widget build(BuildContext context) {
    return AuthGate(
      reason: 'Authenticate to access compliance checklist',
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Compliance Checklist'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _runChecks,
              tooltip: 'Run Checks',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _lastReport != null ? _exportReport : null,
              tooltip: 'Export Report',
            ),
          ],
        ),
        body: LiquidGlassBackground(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _runChecks,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      DesignConstants.standardPadding,
                      kToolbarHeight + DesignConstants.standardPadding,
                      DesignConstants.standardPadding,
                      DesignConstants.standardPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScoreCard(),
                        const SizedBox(height: 24),
                        const Text(
                          'Compliance Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildChecklist(),
                        const SizedBox(height: 24),
                        if (_lastReport != null) _buildSignatureCard(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    if (_lastReport == null) return const SizedBox.shrink();
    final score = _lastReport!.score;
    Color scoreColor;
    if (score >= 90) {
      scoreColor = AppTheme.healthGreen;
    } else if (score >= 70) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Compliance Score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              score == 100
                  ? 'System is fully compliant.'
                  : 'Action required for full compliance.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklist() {
    if (_results == null) return const SizedBox.shrink();

    return Column(
      children: _results!.map((result) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassCard(
            child: ListTile(
              leading: Icon(
                result.passed ? Icons.check_circle : Icons.error,
                color: result.passed ? AppTheme.healthGreen : Colors.red,
                size: 32,
              ),
              title: Text(
                result.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    result.details,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (result.documentationUrl != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _launchUrl(result.documentationUrl!),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link,
                              size: 16,
                              color: AppTheme.primaryColor.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            'Documentation',
                            style: TextStyle(
                              color: AppTheme.primaryColor.withOpacity(0.8),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSignatureCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Signature',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SHA-256: ${_lastReport!.signature}',
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Generated: ${_lastReport!.timestamp.toIso8601String()}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
