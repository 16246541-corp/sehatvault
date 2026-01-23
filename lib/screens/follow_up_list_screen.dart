import 'package:flutter/material.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../models/follow_up_item.dart';
import '../models/doctor_conversation.dart';
import '../services/local_storage_service.dart';
import '../widgets/follow_up_card.dart';
import '../widgets/dialogs/follow_up_edit_dialog.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../services/follow_up_reminder_service.dart';
import 'doctor_visit_prep_screen.dart';

class FollowUpListScreen extends StatefulWidget {
  const FollowUpListScreen({super.key});

  @override
  State<FollowUpListScreen> createState() => _FollowUpListScreenState();
}

class _FollowUpListScreenState extends State<FollowUpListScreen> {
  final LocalStorageService _storageService = LocalStorageService();

  // Filter state
  bool _showCompleted = false;

  // Data
  List<FollowUpItem> _allItems = [];
  Map<FollowUpCategory, List<FollowUpItem>> _groupedItems = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _allItems = _storageService.getAllFollowUpItems();
      _groupItems();
    });
  }

  void _groupItems() {
    _groupedItems = {};

    // Filter by completion status
    final filteredItems =
        _allItems.where((item) => item.isCompleted == _showCompleted).toList();

    // Group by category
    for (final item in filteredItems) {
      if (!_groupedItems.containsKey(item.category)) {
        _groupedItems[item.category] = [];
      }
      _groupedItems[item.category]!.add(item);
    }

    // Sort categories by default order (enum order)
    // Or we could sort by count? Let's keep enum order for consistency.
  }

  Future<void> _toggleCompletion(FollowUpItem item) async {
    setState(() {
      item.isCompleted = !item.isCompleted;
      item.save(); // HiveObject method, or use service
    });

    // If using service explicitly:
    await _storageService.saveFollowUpItem(item);

    // Update reminder status
    if (item.isCompleted) {
      await FollowUpReminderService().cancelReminder(item.id);
    } else {
      await FollowUpReminderService().scheduleReminder(item);
    }

    // Refresh list to move item to other tab/filter
    _loadItems();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              item.isCompleted ? 'Marked as completed' : 'Marked as pending'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _toggleCompletion(item),
          ),
        ),
      );
    }
  }

  Future<void> _updateItem(FollowUpItem oldItem, FollowUpItem newItem) async {
    if (oldItem.isInBox) {
      await oldItem.box!.put(oldItem.key, newItem);
    }

    // Reschedule reminder
    if (newItem.isCompleted) {
      await FollowUpReminderService().cancelReminder(newItem.id);
    } else {
      await FollowUpReminderService().scheduleReminder(newItem);
    }

    _loadItems();
  }

  Future<void> _addToCalendar(FollowUpItem item) async {
    if (item.dueDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot add to calendar: No due date set'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Get conversation context
    String notes = '';
    try {
      final conversation =
          _storageService.getDoctorConversation(item.sourceConversationId);
      if (conversation != null) {
        notes = 'From conversation: ${conversation.title}\n\n';
      }
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
    }
    notes += 'Description: ${item.description}';

    final event = Event(
      title: item.description,
      description: notes,
      location: 'Sehat Locker App',
      startDate: item.dueDate!,
      endDate: item.dueDate!.add(const Duration(hours: 1)),
      allDay: item.frequency == null,
    );

    await Add2Calendar.addEvent2Cal(event);
  }

  void _showEditDialog(FollowUpItem item) {
    showDialog(
      context: context,
      builder: (context) => FollowUpEditDialog(
        item: item,
        onSave: (updatedItem) => _updateItem(item, updatedItem),
      ),
    );
  }

  Color _getCategoryColor(FollowUpCategory category) {
    // Reusing color logic from FollowUpCard or defining here
    // Ideally this should be in a centralized theme/utils
    switch (category) {
      case FollowUpCategory.medication:
        return Colors.blue;
      case FollowUpCategory.appointment:
        return Colors.purple;
      case FollowUpCategory.test:
        return Colors.orange;
      case FollowUpCategory.lifestyle:
        return Colors.green;
      case FollowUpCategory.monitoring:
        return Colors.teal;
      case FollowUpCategory.warning:
        return Colors.red;
      case FollowUpCategory.decision:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sort categories for display
    final sortedCategories = _groupedItems.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Follow-Up Items', style: theme.textTheme.titleLarge),
          actions: [
            // Visit Prep Button
            IconButton(
              icon: const Icon(Icons.medical_services_outlined),
              tooltip: 'Doctor Visit Prep',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorVisitPrepScreen(),
                  ),
                );
              },
            ),
            // Filter Toggle
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ToggleButtons(
                isSelected: [!_showCompleted, _showCompleted],
                onPressed: (index) {
                  setState(() {
                    _showCompleted = index == 1;
                    _groupItems();
                  });
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 32, minWidth: 80),
                fillColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                selectedColor: theme.colorScheme.primary,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Pending'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _allItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checklist, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No follow-up items found',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : filteredListIsEmpty()
                ? Center(
                    child: Text(
                      _showCompleted
                          ? 'No completed items'
                          : 'No pending items',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: sortedCategories.length,
                    itemBuilder: (context, index) {
                      final category = sortedCategories[index];
                      final items = _groupedItems[category]!;
                      final color = _getCategoryColor(category);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 0,
                        color: theme.cardColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Theme(
                          data:
                              theme.copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  Icon(category.icon, color: color, size: 20),
                            ),
                            title: Text(
                              category.toDisplayString(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${items.length}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.expand_more),
                              ],
                            ),
                            children: items
                                .map((item) => FollowUpCard(
                                      item: item,
                                      onMarkComplete: () =>
                                          _toggleCompletion(item),
                                      onTap: () => _showEditDialog(item),
                                      onEdit: () => _showEditDialog(item),
                                    ))
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Add manual item creation
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  bool filteredListIsEmpty() {
    return _groupedItems.values.every((list) => list.isEmpty);
  }
}
