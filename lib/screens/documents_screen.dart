import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_text_field.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/desktop/file_drop_zone.dart';
import '../utils/design_constants.dart';
import '../services/vault_service.dart';
import '../services/search_service.dart';
import '../services/local_storage_service.dart';
import '../services/storage_usage_service.dart';
import '../services/batch_processing_service.dart';
import '../models/batch_task.dart';
import 'batch_processing_screen.dart';
import '../models/health_record.dart';
import '../widgets/cards/document_grid_card.dart';
import '../widgets/dashboard/follow_up_dashboard.dart';
import 'document_detail_screen.dart';
import 'follow_up_list_screen.dart';
import 'conversation_transcript_screen.dart';
import '../models/follow_up_item.dart';
import '../models/search_entry.dart';
import '../widgets/follow_up_card.dart';
import '../widgets/dialogs/follow_up_edit_dialog.dart';
import '../services/follow_up_reminder_service.dart';
import '../widgets/empty_states/empty_conversations_state.dart';

/// Documents Screen - Health documents storage
class DocumentsScreen extends StatefulWidget {
  final VoidCallback? onTasksTap;
  final VoidCallback? onRecordTap;

  const DocumentsScreen({
    super.key,
    this.onTasksTap,
    this.onRecordTap,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final VaultService _vaultService = VaultService(LocalStorageService());
  late final SearchService _searchService;
  late final StorageUsageService _storageUsageService;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<HealthRecord> _documents = [];
  List<HealthRecord> _filteredDocuments = [];
  List<FollowUpItem> _filteredFollowUps = [];
  List<SearchEntry> _conversationResults = [];
  StorageUsage? _storageUsage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchService = SearchService(LocalStorageService());
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
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 2;
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
      if (_filteredDocuments.length != _documents.length ||
          _conversationResults.isNotEmpty ||
          _filteredFollowUps.isNotEmpty) {
        setState(() {
          _filteredDocuments = List.from(_documents);
          _conversationResults = [];
          _filteredFollowUps = [];
        });
      }
      return;
    }

    // Get indexed results from SearchService
    final results = _searchService.search(query);

    // Group results by type
    final searchDocIds = results
        .where((e) => e.type == 'document')
        .map((e) => e.sourceId)
        .toSet();
    final searchFollowUpIds = results
        .where((e) => e.type == 'followup')
        .map((e) => e.sourceId)
        .toSet();
    final conversationResults =
        results.where((e) => e.type == 'conversation').toList();

    setState(() {
      _conversationResults = conversationResults;

      // Filter documents (metadata match OR index match)
      _filteredDocuments = _documents.where((doc) {
        final titleMatch =
            doc.title.toLowerCase().contains(query.toLowerCase());
        final categoryMatch =
            doc.category.toLowerCase().contains(query.toLowerCase());
        final notesMatch =
            doc.notes?.toLowerCase().contains(query.toLowerCase()) ?? false;
        final indexMatch =
            doc.extractionId != null && searchDocIds.contains(doc.extractionId);

        return titleMatch || categoryMatch || notesMatch || indexMatch;
      }).toList();

      // Filter follow-ups (metadata match OR index match)
      final allFollowUps = LocalStorageService().getAllFollowUpItems();
      _filteredFollowUps = allFollowUps.where((item) {
        final metaMatch = item.description
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            item.verb.toLowerCase().contains(query.toLowerCase()) ||
            (item.object?.toLowerCase().contains(query.toLowerCase()) ?? false);
        final indexMatch = searchFollowUpIds.contains(item.id);

        return metaMatch || indexMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: FileDropZone(
        vaultService: _vaultService,
        settings: LocalStorageService().getAppSettings(),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final columnCount = _calculateColumnCount(constraints.maxWidth);

            return Padding(
              padding:
                  const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
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

                  // Storage Warning
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Storage space low',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'You have used ${(_storageUsage!.usagePercentage * 100).toStringAsFixed(1)}% of your device storage.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Batch Processing Status
                  StreamBuilder<List<BatchTask>>(
                    stream: BatchProcessingService().tasksStream,
                    builder: (context, snapshot) {
                      final tasks = snapshot.data ?? [];
                      final activeTasks = tasks
                          .where((t) =>
                              t.status == BatchTaskStatus.pending ||
                              t.status == BatchTaskStatus.processing)
                          .toList();

                      if (activeTasks.isEmpty) return const SizedBox.shrink();

                      final processingTask = tasks.firstWhere(
                        (t) => t.status == BatchTaskStatus.processing,
                        orElse: () => activeTasks.first,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BatchProcessingScreen(),
                              ),
                            );
                          },
                          backgroundColor: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: processingTask.status ==
                                          BatchTaskStatus.processing
                                      ? processingTask.progress
                                      : null,
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Processing ${activeTasks.length} documents...',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Currently: ${processingTask.title}',
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

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
                    child: FocusTraversalGroup(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _searchController.text.isNotEmpty
                              ? _buildSearchResults(context, columnCount)
                              : _filteredDocuments.isNotEmpty
                                  ? _buildDocumentsGrid(context, columnCount)
                                  : _buildEmptyState(context),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, int columnCount) {
    if (_filteredDocuments.isEmpty &&
        _filteredFollowUps.isEmpty &&
        _conversationResults.isEmpty) {
      return _buildEmptyState(context);
    }

    return AnimationLimiter(
      child: CustomScrollView(
        controller: _scrollController,
        key: const PageStorageKey('documents_search_scroll'),
        slivers: [
          if (_conversationResults.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Conversations',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = _conversationResults[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: FadeInAnimation(
                      child: _buildConversationResultCard(entry),
                    ),
                  );
                },
                childCount: _conversationResults.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
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
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: FadeInAnimation(
                      child: FollowUpCard(
                        item: item,
                        onTap: () => _showEditDialog(item),
                        onMarkComplete: () => _toggleCompletion(item),
                        onEdit: () => _showEditDialog(item),
                      ),
                    ),
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
            SliverMasonryGrid.count(
              crossAxisCount: columnCount,
              mainAxisSpacing: DesignConstants.gridSpacing,
              crossAxisSpacing: DesignConstants.gridSpacing,
              itemBuilder: (context, index) {
                final doc = _filteredDocuments[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: columnCount,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _buildDocumentCard(doc),
                    ),
                  ),
                );
              },
              childCount: _filteredDocuments.length,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard(HealthRecord doc) {
    return FocusableActionDetector(
      onShowFocusHighlight: (value) {},
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) => _openDocument(doc),
        ),
      },
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
      },
      child: DocumentGridCard(
        record: doc,
        onTap: () => _openDocument(doc),
      ),
    );
  }

  Future<void> _openDocument(HealthRecord doc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(
          healthRecordId: doc.id,
        ),
      ),
    );
    _loadDocuments();
    _checkStorage();
  }

  Widget _buildConversationResultCard(SearchEntry entry) {
    final query = _searchController.text.trim();
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.5)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final conversation =
              LocalStorageService().getDoctorConversation(entry.sourceId);
          if (conversation != null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ConversationTranscriptScreen(conversation: conversation),
                ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation not found')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (entry.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(entry.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
              ],
              const SizedBox(height: 8),
              _buildExcerpt(entry.content, query),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExcerpt(String content, String query) {
    if (query.isEmpty) return const SizedBox.shrink();

    final lowerContent = content.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerContent.indexOf(lowerQuery);

    if (index == -1) {
      return Text(content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall);
    }

    final start = max(0, index - 30);
    final end = min(content.length, index + query.length + 60);

    final prefix = start > 0 ? '...' : '';
    final suffix = end < content.length ? '...' : '';

    final snippet = content.substring(start, end);
    final matchIndexInSnippet = snippet.toLowerCase().indexOf(lowerQuery);

    if (matchIndexInSnippet == -1) {
      return Text('$prefix$snippet$suffix',
          style: Theme.of(context).textTheme.bodySmall);
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(text: prefix + snippet.substring(0, matchIndexInSnippet)),
          TextSpan(
            text: snippet.substring(
                matchIndexInSnippet, matchIndexInSnippet + query.length),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          TextSpan(
              text: snippet.substring(matchIndexInSnippet + query.length) +
                  suffix),
        ],
      ),
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

    return EmptyConversationsState(
      onRecordTap: () async {
        if (widget.onRecordTap != null) {
          widget.onRecordTap!();
        } else {
          // Fallback if callback is not provided (though it should be)
          // We can try to find the AIScreen via route or just print warning
          debugPrint('onRecordTap callback not provided');
        }
      },
      showOnboarding: true, // TODO: Check if first time user
    );
  }

  Widget _buildDocumentsGrid(BuildContext context, int columnCount) {
    return AnimationLimiter(
      child: MasonryGridView.count(
        controller: _scrollController,
        key: const PageStorageKey('documents_grid_scroll'),
        crossAxisCount: columnCount,
        mainAxisSpacing: DesignConstants.gridSpacing,
        crossAxisSpacing: DesignConstants.gridSpacing,
        itemCount: _filteredDocuments.length,
        itemBuilder: (context, index) {
          final doc = _filteredDocuments[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: columnCount,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildDocumentCard(doc),
              ),
            ),
          );
        },
      ),
    );
  }
}
