import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/follow_up_item.dart';

class FollowUpEditDialog extends StatefulWidget {
  final FollowUpItem item;
  final Function(FollowUpItem) onSave;

  const FollowUpEditDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<FollowUpEditDialog> createState() => _FollowUpEditDialogState();
}

class _FollowUpEditDialogState extends State<FollowUpEditDialog> {
  late TextEditingController _descriptionController;
  late FollowUpCategory _category;
  late FollowUpPriority _priority;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.item.description);
    _category = widget.item.category;
    _priority = widget.item.priority;
    _dueDate = widget.item.dueDate;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _save() {
    final updatedItem = FollowUpItem(
      id: widget.item.id,
      category: _category,
      verb: widget.item.verb,
      object: widget.item.object,
      description: _descriptionController.text,
      priority: _priority,
      dueDate: _dueDate,
      timeframeRaw: widget.item.timeframeRaw,
      frequency: widget.item.frequency,
      sourceConversationId: widget.item.sourceConversationId,
      createdAt: widget.item.createdAt,
      isCompleted: widget.item.isCompleted,
      calendarEventId: widget.item.calendarEventId,
      isPotentialDuplicate: widget.item.isPotentialDuplicate,
      linkedRecordId: widget.item.linkedRecordId,
      linkedEntityName: widget.item.linkedEntityName,
      linkedContext: widget.item.linkedContext,
    );

    widget.onSave(updatedItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Follow-Up',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<FollowUpCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: FollowUpCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(category.icon,
                            size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(category.toDisplayString()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Due Date & Priority Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dueDate != null
                                  ? DateFormat('MMM d, y').format(_dueDate!)
                                  : 'Set Date',
                              style: _dueDate != null
                                  ? theme.textTheme.bodyMedium
                                  : theme.textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Priority Toggle
                  InkWell(
                    onTap: () {
                      setState(() {
                        _priority = _priority == FollowUpPriority.high
                            ? FollowUpPriority.normal
                            : FollowUpPriority.high;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 48, // Match input height approx
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _priority == FollowUpPriority.high
                              ? Colors.red
                              : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: _priority == FollowUpPriority.high
                            ? Colors.red.withValues(alpha: 0.1)
                            : null,
                      ),
                      child: Center(
                        child: Row(
                          children: [
                            Icon(
                              Icons.priority_high,
                              size: 20,
                              color: _priority == FollowUpPriority.high
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            if (_priority == FollowUpPriority.high) ...[
                              const SizedBox(width: 4),
                              const Text(
                                'High',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
