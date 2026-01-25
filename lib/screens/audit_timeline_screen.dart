import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_audit_service.dart';
import '../services/export_service.dart';
import '../services/session_manager.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../utils/design_constants.dart';
import '../main.dart';

class AuditTimelineScreen extends StatefulWidget {
  const AuditTimelineScreen({super.key});

  @override
  State<AuditTimelineScreen> createState() => _AuditTimelineScreenState();
}

class _AuditTimelineScreenState extends State<AuditTimelineScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String? _selectedSensitivity;
  IntegrityResult? _integrityResult;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _verifyIntegrity();
  }

  Future<void> _verifyIntegrity() async {
    setState(() => _isVerifying = true);
    final service = LocalAuditService(storageService, SessionManager());
    final result = await service.verifyIntegrity();
    if (mounted) {
      setState(() {
        _integrityResult = result;
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = LocalAuditService(storageService, SessionManager());
    final entries = service.getEntries(
      searchTerm: _searchTerm,
      sensitivity: _selectedSensitivity,
    );

    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Security Audit Log'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _verifyIntegrity,
            ),
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: () => ExportService().exportAuditLogReport(context),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildIntegrityBanner(theme),
            _buildFilters(theme),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'No audit entries found',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(
                          DesignConstants.pageHorizontalPadding),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat.yMMMd()
                                          .add_jms()
                                          .format(entry.timestamp),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                    _buildSensitivityBadge(entry.sensitivity),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  entry.action
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDetails(entry.details, theme),
                                const SizedBox(height: 8),
                                Text(
                                  'Session: ${entry.sessionId != null && entry.sessionId!.length >= 8 ? entry.sessionId!.substring(0, 8) : entry.sessionId ?? "N/A"}...',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  'Hash: ${entry.hash.substring(0, 16)}...',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontSize: 8,
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
    );
  }

  Widget _buildIntegrityBanner(ThemeData theme) {
    if (_isVerifying) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.blue.withValues(alpha: 0.1),
        child: const Center(
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_integrityResult == null) return const SizedBox.shrink();

    final isValid = _integrityResult!.isValid;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: (isValid ? Colors.green : Colors.red).withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.verified_user : Icons.gpp_maybe,
            color: isValid ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isValid
                  ? 'Audit Log Integrity Verified'
                  : 'INTEGRITY CHECK FAILED at index ${_integrityResult!.failingIndex}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isValid ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search audit logs...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchTerm = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => _searchTerm = value),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                _buildFilterChip('Info', 'info'),
                const SizedBox(width: 8),
                _buildFilterChip('Warning', 'warning'),
                const SizedBox(width: 8),
                _buildFilterChip('Critical', 'critical'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedSensitivity == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedSensitivity = selected ? value : null);
      },
    );
  }

  Widget _buildSensitivityBadge(String sensitivity) {
    Color color;
    switch (sensitivity) {
      case 'critical':
        color = Colors.red;
        break;
      case 'warning':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        sensitivity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetails(Map<String, String> details, ThemeData theme) {
    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${e.key}: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                TextSpan(
                  text: e.value,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
