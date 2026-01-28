import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/health_record.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/storage_usage_service.dart';
import '../../../services/vault_service.dart';
import '../../../ui/mobile/screens/health_insights_screen.dart';
import '../../../utils/design_constants.dart';
import '../../../widgets/cards/document_grid_card.dart';
import '../../../widgets/design/glass_card.dart';
import '../../../widgets/design/glass_text_field.dart';
import '../../../widgets/design/liquid_glass_background.dart';
import '../../../widgets/design/responsive_center.dart';
import '../../../widgets/compliance/emergency_use_banner.dart';
import '../../../widgets/compliance/fda_disclaimer_widget.dart';
import '../../../screens/document_detail_screen.dart';

class MobileDocumentsScreen extends StatefulWidget {
  final VoidCallback? onRecordTap;

  const MobileDocumentsScreen({
    super.key,
    this.onRecordTap,
  });

  @override
  State<MobileDocumentsScreen> createState() => _MobileDocumentsScreenState();
}

class _MobileDocumentsScreenState extends State<MobileDocumentsScreen> {
  final VaultService _vaultService = VaultService(LocalStorageService());
  late final StorageUsageService _storageUsageService;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<HealthRecord> _documents = [];
  List<HealthRecord> _filteredDocuments = [];
  StorageUsage? _storageUsage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _storageUsageService = StorageUsageService(LocalStorageService());
    _searchController.addListener(_performSearch);
    _loadDocuments();
    _checkStorage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkStorage() async {
    final usage = await _storageUsageService.calculateStorageUsage();
    if (mounted) {
      setState(() {
        _storageUsage = usage;
      });
    }
  }

  int _calculateColumnCount(double width) {
    if (width >= 600) return 2;
    return 2;
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final results = await _vaultService.getAllDocuments();
      setState(() {
        _documents = results.map((e) => e.record).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _filteredDocuments = List.from(_documents);
        _isLoading = false;
      });
      if (_searchController.text.isNotEmpty) {
        _performSearch();
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredDocuments = List.from(_documents));
      return;
    }

    setState(() {
      _filteredDocuments = _documents.where((doc) {
        final titleMatch = doc.title.toLowerCase().contains(query);
        final categoryMatch = doc.category.toLowerCase().contains(query);
        final notesMatch = doc.notes?.toLowerCase().contains(query) ?? false;
        return titleMatch || categoryMatch || notesMatch;
      }).toList();
    });
  }

  Future<void> _openDocument(HealthRecord doc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(healthRecordId: doc.id),
      ),
    );
    _loadDocuments();
    _checkStorage();
  }

  Future<void> _confirmDelete(HealthRecord doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
          'Are you sure you want to delete this document? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _vaultService.deleteDocument(doc.id);
      if (!mounted) return;
      await _loadDocuments();
      await _checkStorage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: ResponsiveCenter(
        maxContentWidth: 1000,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = _calculateColumnCount(constraints.maxWidth);
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(
                      DesignConstants.pageHorizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 84),
                        const SizedBox(height: DesignConstants.titleTopPadding),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Documents',
                                  style: theme.textTheme.displayMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Stored locally on your device',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                _loadDocuments();
                                _checkStorage();
                              },
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_storageUsage != null &&
                            _storageUsage!.usagePercentage > 0.8)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GlassCard(
                              backgroundColor: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.3),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: theme.colorScheme.error),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Storage low: ${(_storageUsage!.usagePercentage * 100).toStringAsFixed(1)}% used',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        _buildQuickActions(),
                        const SizedBox(height: 16),
                        GlassTextField(
                          controller: _searchController,
                          hintText: 'Search documents...',
                          prefixIcon: Icons.search,
                        ),
                        const SizedBox(height: DesignConstants.sectionSpacing),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _filteredDocuments.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No documents found',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    )
                                  : _buildDocumentsGrid(columnCount),
                        ),
                        const SizedBox(height: 16),
                        const FdaDisclaimerWidget(),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.pageHorizontalPadding,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EmergencyUseBanner(),
                            const SizedBox(height: 8),
                            const FdaDisclaimerWidget(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            onTap: widget.onRecordTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mic_none_outlined),
                const SizedBox(height: 10),
                Text(
                  'Conversations',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Record a doctor visit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HealthInsightsScreen(),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.insights_outlined),
                const SizedBox(height: 10),
                Text(
                  'Health Insights',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Non-diagnostic patterns',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsGrid(int columnCount) {
    final theme = Theme.of(context);

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: DesignConstants.gridSpacing,
        mainAxisSpacing: DesignConstants.gridSpacing,
        childAspectRatio: 0.92,
      ),
      itemCount: _filteredDocuments.length,
      itemBuilder: (context, index) {
        final doc = _filteredDocuments[index];
        final seed = doc.id.hashCode;
        final heightFactor = 0.9 + (Random(seed).nextDouble() * 0.25);
        return FractionallySizedBox(
          heightFactor: heightFactor,
          alignment: Alignment.topCenter,
          child: Stack(
            children: [
              Positioned.fill(
                child: DocumentGridCard(
                  record: doc,
                  onTap: () => _openDocument(doc),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Tooltip(
                  message: 'Delete',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _confirmDelete(doc),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.surface.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
