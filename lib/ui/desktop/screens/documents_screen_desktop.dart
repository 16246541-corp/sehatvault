import 'package:flutter/material.dart';

import '../../../models/health_record.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/storage_usage_service.dart';
import '../../../services/vault_service.dart';
import '../../../ui/desktop/widgets/file_drop_zone.dart';
import '../../../ui/desktop/widgets/health_insights_sidebar.dart';
import '../../../utils/design_constants.dart';
import '../../../widgets/cards/document_grid_card.dart';
import '../../../widgets/design/glass_card.dart';
import '../../../widgets/design/glass_text_field.dart';
import '../../../widgets/design/liquid_glass_background.dart';
import '../../../widgets/design/responsive_center.dart';
import '../../../screens/document_detail_screen.dart';

class DesktopDocumentsScreen extends StatefulWidget {
  final VoidCallback? onRecordTap;

  const DesktopDocumentsScreen({
    super.key,
    this.onRecordTap,
  });

  @override
  State<DesktopDocumentsScreen> createState() => _DesktopDocumentsScreenState();
}

class _DesktopDocumentsScreenState extends State<DesktopDocumentsScreen> {
  final LocalStorageService _storage = LocalStorageService();
  late final VaultService _vaultService;
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
    _vaultService = VaultService(_storage);
    _storageUsageService = StorageUsageService(_storage);
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

  int _calculateColumnCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 650) return 2;
    return 2;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: FileDropZone(
        vaultService: _vaultService,
        settings: _storage.getAppSettings(),
        child: ResponsiveCenter(
          maxContentWidth: 1600,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sidebarWidth = constraints.maxWidth >= 1100 ? 420.0 : 360.0;
                  final columnCount =
                      _calculateColumnCount(constraints.maxWidth - sidebarWidth);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      'Your health records, stored locally',
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
                                  backgroundColor: theme
                                      .colorScheme.errorContainer
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
                            GlassTextField(
                              controller: _searchController,
                              hintText: 'Search documents...',
                              prefixIcon: Icons.search,
                            ),
                            const SizedBox(height: DesignConstants.sectionSpacing),
                            Expanded(
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _filteredDocuments.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No documents found',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        )
                                      : _buildDocumentsGrid(columnCount),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 800,
                          minWidth: sidebarWidth,
                        ),
                        child: const HealthInsightsSidebar(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsGrid(int columnCount) {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: DesignConstants.gridSpacing,
        mainAxisSpacing: DesignConstants.gridSpacing,
        childAspectRatio: 1.05,
      ),
      itemCount: _filteredDocuments.length,
      itemBuilder: (context, index) {
        final doc = _filteredDocuments[index];
        return DocumentGridCard(
          record: doc,
          onTap: () => _openDocument(doc),
        );
      },
    );
  }
}

