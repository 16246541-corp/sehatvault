import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/privacy_manifest_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../utils/design_constants.dart';
import '../utils/theme.dart';
import '../main.dart'; // for storageService

class PrivacyManifestScreen extends StatefulWidget {
  const PrivacyManifestScreen({super.key});

  @override
  State<PrivacyManifestScreen> createState() => _PrivacyManifestScreenState();
}

class _PrivacyManifestScreenState extends State<PrivacyManifestScreen> {
  late final PrivacyManifestService _service;
  bool _isLoading = true;
  PrivacyManifestData? _data;
  bool _developerMode = false;

  @override
  void initState() {
    super.initState();
    _service = PrivacyManifestService(storageService);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.generateManifest();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading manifest: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Privacy Manifest'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _developerMode ? Icons.code_off : Icons.code,
              color: _developerMode ? AppTheme.primaryColor : Colors.white,
            ),
            tooltip: 'Developer Mode',
            onPressed: () => setState(() => _developerMode = !_developerMode),
          ),
          if (_data != null)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Export Manifest',
              onPressed: () => _service.exportManifest(_data!),
            ),
        ],
      ),
      body: LiquidGlassBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
                ? const Center(child: Text('Failed to load data'))
                : RefreshIndicator(
                    onRefresh: _loadData,
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
                          _buildStorageVisualization(),
                          const SizedBox(height: 24),
                          _buildSettingsSummary(),
                          const SizedBox(height: 24),
                          _buildAccessHistory(),
                          if (_developerMode) ...[
                            const SizedBox(height: 24),
                            _buildTechnicalDetails(),
                          ],
                          const SizedBox(height: 40), // Bottom padding
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final score = _data!.privacyScore;
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
              'Privacy Score',
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
              score >= 90
                  ? 'Your privacy configuration is excellent.'
                  : 'There is room for improvement in your privacy settings.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageVisualization() {
    final usage = _data!.storageUsage;
    final total = usage.totalBytes > 0 ? usage.totalBytes : 1;

    // Calculate percentages
    final convPct = usage.conversationsBytes / total;
    final docPct = usage.documentsBytes / total;
    final modelPct = usage.modelsBytes / total;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Storage Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _PieChartPainter(
                  slices: [
                    _PieSlice(convPct, AppTheme.primaryColor),
                    _PieSlice(docPct, AppTheme.accentTeal),
                    _PieSlice(modelPct, Colors.purpleAccent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLegendItem('Conversations', AppTheme.primaryColor,
                usage.conversationsBytes),
            _buildLegendItem(
                'Documents', AppTheme.accentTeal, usage.documentsBytes),
            _buildLegendItem('Models', Colors.purpleAccent, usage.modelsBytes),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int bytes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          Text(_formatBytes(bytes),
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSettingsSummary() {
    final settings = _data!.privacySettings;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Privacy Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to settings
                    // Assuming we can pop back or navigate to settings.
                    // For now, just show a message or rely on user knowing where settings are.
                    // Or better, Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
                    // But avoiding circular imports if possible.
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
            _buildSettingItem(
              'Biometrics for Sensitive Data',
              settings.requireBiometricsForSensitiveData,
            ),
            _buildSettingItem(
              'Biometrics for Export',
              settings.requireBiometricsForExport,
            ),
            _buildSettingItem(
              'Biometrics for Settings',
              settings.requireBiometricsForSettings,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Temp File Retention',
                      style: TextStyle(color: Colors.white70)),
                  Text('${settings.tempFileRetentionMinutes} min',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: Colors.white70))),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? AppTheme.healthGreen : Colors.redAccent,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessHistory() {
    final logs = _data!.recentAccessLogs.take(5).toList();
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Access History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (logs.isEmpty)
              const Text('No recent access logs found.',
                  style: TextStyle(color: Colors.white54))
            else
              ...logs.map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          log.success
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: log.success
                              ? AppTheme.healthGreen
                              : Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.action,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                              Text(
                                DateFormat('MMM dd, HH:mm')
                                    .format(log.timestamp),
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            if (logs.isNotEmpty)
              Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full history if available
                  },
                  child: const Text('View All History'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalDetails() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Technical Details (Developer Mode)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildTechRow('Total Bytes', '${_data!.storageUsage.totalBytes}'),
            _buildTechRow('Free Bytes', '${_data!.storageUsage.freeBytes}'),
            _buildTechRow('Conversation Count',
                '${_data!.storageUsage.conversationCount}'),
            _buildTechRow(
                'Document Count', '${_data!.storageUsage.documentCount}'),
            _buildTechRow('Encryption Algo', 'AES-256-GCM'),
            _buildTechRow('Key Store', 'Secure Enclave / Keystore'),
          ],
        ),
      ),
    );
  }

  Widget _buildTechRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontFamily: 'Courier')),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier')),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _PieSlice {
  final double value; // 0.0 to 1.0
  final Color color;

  _PieSlice(this.value, this.color);
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;

  _PieChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -3.14159 / 2; // Start from top

    for (final slice in slices) {
      final sweepAngle = 2 * 3.14159 * slice.value;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
