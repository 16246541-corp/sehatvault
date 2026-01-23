import 'package:flutter/material.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_button.dart';
import '../widgets/design/glass_text_field.dart';
import '../utils/design_constants.dart';
import 'document_scanner_screen.dart';
import '../services/vault_service.dart';
import '../services/search_service.dart';
import '../services/local_storage_service.dart';
import '../models/health_record.dart';
import '../widgets/cards/document_grid_card.dart';
import '../widgets/dashboard/follow_up_dashboard.dart';
import 'document_detail_screen.dart';
import 'follow_up_list_screen.dart';
import '../models/follow_up_item.dart';
import '../widgets/follow_up_card.dart';
import '../widgets/dialogs/follow_up_edit_dialog.dart';
import '../services/follow_up_reminder_service.dart';

/// Documents Screen - Health documents storage
class DocumentsScreen extends StatefulWidget {
  final VoidCallback? onTasksTap;

  const DocumentsScreen({
    super.key,
    this.onTasksTap,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final VaultService _vaultService = VaultService(LocalStorageService());
  late final SearchService _searchService;
  final TextEditingController _searchController = TextEditingController();

  List<HealthRecord> _documents = [];
  List<HealthRecord> _filteredDocuments = [];
  List<FollowUpItem> _filteredFollowUps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchService = SearchService(LocalStorageService());
    _searchController.addListener(_performSearch);
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final results = await _vaultService.getAllDocuments();
      setState(() {
        _documents = results.map((e) => e.record).toList();
        // Sort by date descending
        _documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _filteredDocuments = List.from(_documents);
        _isLoading = false;
      });
      // Re-apply search if exists
      if (_searchController.text.isNotEmpty) {
        _performSearch();
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
      setState(() => _isLoading = false);
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (_filteredDocuments.length != _documents.length) {
        setState(() {
          _filteredDocuments = List.from(_documents);
          _filteredFollowUps = [];
        });
      }
      return;
    }

    // Get document IDs that match the search query (fuzzy search on extracted text)
    final matchingExtractionIds = _searchService.search(query);

    setState(() {
      _filteredDocuments = _documents.where((doc) {
        // 1. Check if document's extraction ID is in the search results
        bool contentMatch = false;
        if (doc.extractionId != null) {
          contentMatch = matchingExtractionIds.contains(doc.extractionId);
        }

        // 2. Check metadata (title, category, notes)
        final titleMatch =
            doc.title.toLowerCase().contains(query.toLowerCase());
        final categoryMatch =
            doc.category.toLowerCase().contains(query.toLowerCase());
        final notesMatch =
            doc.notes?.toLowerCase().contains(query.toLowerCase()) ?? false;

        return contentMatch || titleMatch || categoryMatch || notesMatch;
      }).toList();

      // Filter follow-ups
      final allFollowUps = LocalStorageService().getAllFollowUpItems();
      _filteredFollowUps = allFollowUps.where((item) {
        // 1. Check index
        bool indexMatch = matchingExtractionIds.contains(item.id);

        // 2. Check metadata
        bool metaMatch =
            item.description.toLowerCase().contains(query.toLowerCase()) ||
                item.verb.toLowerCase().contains(query.toLowerCase()) ||
                (item.object?.toLowerCase().contains(query.toLowerCase()) ??
                    false) ||
                item.category
                    .toString()
                    .split('.')
                    .last
                    .toLowerCase()
                    .contains(query.toLowerCase());

        return indexMatch || metaMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
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
                    onPressed: _loadDocuments,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dashboard
              FollowUpDashboard(
                onTap: () async {
                  if (widget.onTasksTap != null) {
                    widget.onTasksTap!();
                  } else {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FollowUpListScreen(),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: DesignConstants.sectionSpacing),

              // Search Bar
              GlassTextField(
                controller: _searchController,
                hintText: 'Search documents...',
                prefixIcon: Icons.search,
              ),

              const SizedBox(height: DesignConstants.sectionSpacing),

              // Content Area
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchController.text.isNotEmpty
                        ? _buildSearchResults(context)
                        : _filteredDocuments.isNotEmpty
                            ? _buildDocumentsGrid(context)
                            : _buildEmptyState(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_filteredDocuments.isEmpty && _filteredFollowUps.isEmpty) {
      return _buildEmptyState(context);
    }

    return CustomScrollView(
      slivers: [
        if (_filteredFollowUps.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Follow-Ups',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _filteredFollowUps[index];
                return FollowUpCard(
                  item: item,
                  onTap: () => _showEditDialog(item),
                  onMarkComplete: () => _toggleCompletion(item),
                  onEdit: () => _showEditDialog(item),
                );
              },
              childCount: _filteredFollowUps.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
        if (_filteredDocuments.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Documents',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = _filteredDocuments[index];
                return DocumentGridCard(
                  record: doc,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentDetailScreen(
                          healthRecordId: doc.id,
                        ),
                      ),
                    );
                    _loadDocuments(); // Refresh grid on return (in case of deletion)
                  },
                );
              },
              childCount: _filteredDocuments.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: DesignConstants.gridSpacing,
              crossAxisSpacing: DesignConstants.gridSpacing,
              childAspectRatio: 0.75, // Taller cards for images
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _toggleCompletion(FollowUpItem item) async {
    setState(() {
      item.isCompleted = !item.isCompleted;
      item.save();
    });

    // Update reminder status
    if (item.isCompleted) {
      await FollowUpReminderService().cancelReminder(item.id);
    } else {
      await FollowUpReminderService().scheduleReminder(item);
    }
  }

  void _showEditDialog(FollowUpItem item) {
    showDialog(
      context: context,
      builder: (context) => FollowUpEditDialog(
        item: item,
        onSave: (updatedItem) async {
          await LocalStorageService().saveFollowUpItem(updatedItem);
          _performSearch();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // If searching and no results, show different empty state
    if (_searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              'No matching documents found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.document_scanner_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Documents Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan your medical records to keep them safe\nand accessible anytime.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          GlassButton(
            label: 'Scan Document',
            icon: Icons.camera_alt_outlined,
            isProminent: true,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DocumentScannerScreen(),
                ),
              );
              _loadDocuments();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: DesignConstants.gridSpacing,
        crossAxisSpacing: DesignConstants.gridSpacing,
        childAspectRatio: 0.75, // Taller cards for images
      ),
      itemCount: _filteredDocuments.length,
      itemBuilder: (context, index) {
        final doc = _filteredDocuments[index];
        return DocumentGridCard(
          record: doc,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentDetailScreen(
                  healthRecordId: doc.id,
                ),
              ),
            );
            _loadDocuments(); // Refresh grid on return (in case of deletion)
          },
        );
      },
    );
  }
}
