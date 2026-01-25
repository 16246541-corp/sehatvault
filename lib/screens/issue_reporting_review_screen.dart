import 'package:flutter/material.dart';
import '../models/issue_report.dart';
import '../services/export_service.dart';
import '../services/issue_reporting_service.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/design/liquid_glass_background.dart';

class IssueReportingReviewScreen extends StatefulWidget {
  final String description;
  final List<String>? logs;
  final bool isEmergency;

  const IssueReportingReviewScreen({
    super.key,
    required this.description,
    this.logs,
    this.isEmergency = false,
  });

  @override
  State<IssueReportingReviewScreen> createState() =>
      _IssueReportingReviewScreenState();
}

class _IssueReportingReviewScreenState
    extends State<IssueReportingReviewScreen> {
  final IssueReportingService _service = IssueReportingService();
  bool _includeLogs = true;
  bool _includeDeviceMetrics = true;
  bool _isSubmitting = false;
  IssueReport? _generatedReport;

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    setState(() {
      _generatedReport = null;
    });

    final report = await _service.previewReport(
      description: widget.description,
      logs: widget.logs,
      includeLogs: _includeLogs,
      includeDeviceMetrics: _includeDeviceMetrics,
    );

    if (mounted) {
      setState(() {
        _generatedReport = report;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final report = await _service.createReport(
        description: widget.description,
        logs: widget.logs,
        includeLogs: _includeLogs,
        includeDeviceMetrics: _includeDeviceMetrics,
      );
      await _service.submitReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _export() async {
    if (_generatedReport == null) return;
    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Export Format'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ExportFormat.pdf),
            child: const Text('PDF'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ExportFormat.encryptedJson),
            child: const Text('JSON (Encrypted)'),
          ),
        ],
      ),
    );
    if (format == null || !mounted) return;
    await _service.exportReport(context, _generatedReport!, format: format);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _generatedReport == null
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.isEmergency)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Colors.red),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Emergency Stop Triggered. Please review this report.',
                                        style: TextStyle(
                                            color: Colors.red[800],
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Redacted Description Preview',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(_generatedReport!.description,
                                        style: const TextStyle(
                                            fontFamily: 'Courier')),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GlassCard(
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: const Text('Include Device Metrics'),
                                    subtitle: const Text(
                                        'Battery, OS version, Model (Anonymized)'),
                                    value: _includeDeviceMetrics,
                                    onChanged: (val) {
                                      setState(
                                          () => _includeDeviceMetrics = val);
                                      _generatePreview();
                                    },
                                  ),
                                  SwitchListTile(
                                    title: const Text('Include Logs'),
                                    subtitle: const Text(
                                        'Recent app logs (Redacted)'),
                                    value: _includeLogs,
                                    onChanged: (val) {
                                      setState(() => _includeLogs = val);
                                      _generatePreview();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Data Verification',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            GlassCard(
                              child: Column(
                                children: [
                                  _buildHashRow('Original Hash',
                                      _generatedReport!.originalHash),
                                  const Divider(),
                                  _buildHashRow('Redacted Hash',
                                      _generatedReport!.redactedHash),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Review Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance back button
        ],
      ),
    );
  }

  Widget _buildHashRow(String label, String hash) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              Text(hash,
                  style: const TextStyle(
                      fontSize: 10, fontFamily: 'Courier', color: Colors.grey)),
            ],
          ),
        ),
        const Icon(Icons.verified_user_outlined, color: Colors.green, size: 16),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.share),
              label: const Text('Export'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
