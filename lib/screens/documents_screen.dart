import 'package:flutter/material.dart';
import 'dart:math';
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
import '../widgets/cards/conversation_grid_card.dart';
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
  final TextEditingController _searchController = TextEditingController();

  List<HealthRecord> _documents = [];
  List<HealthRecord> _filteredDocuments = [];
  List<FollowUpItem> _filteredFollowUps = [];
  List<SearchEntry> _conversationResults = [];
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
    if (_filteredDocuments.isEmpty &&
        _filteredFollowUps.isEmpty &&
        _conversationResults.isEmpty) {
      return _buildEmptyState(context);
    }

    return CustomScrollView(
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
                return _buildConversationResultCard(entry);
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

  Widget _buildConversationResultCard(SearchEntry entry) {
    final query = _searchController.text.trim();
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
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

    if (matchIndexInSnippet == -1)
      return Text('$prefix$snippet$suffix',
          style: Theme.of(context).textTheme.bodySmall);

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
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
