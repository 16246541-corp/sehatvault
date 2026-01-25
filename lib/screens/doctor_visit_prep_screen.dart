import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/follow_up_item.dart';
import '../services/local_storage_service.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_button.dart';
import '../widgets/design/glass_card.dart';
import '../services/risk_mitigation_service.dart';

class DoctorVisitPrepScreen extends StatefulWidget {
  final LocalStorageService? storageService;

  const DoctorVisitPrepScreen({
    super.key,
    this.storageService,
  });

  @override
  State<DoctorVisitPrepScreen> createState() => _DoctorVisitPrepScreenState();
}

class _DoctorVisitPrepScreenState extends State<DoctorVisitPrepScreen> {
  late final LocalStorageService _storageService;
  List<FollowUpItem> _pendingItems = [];
  final Set<String> _selectedItemIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? LocalStorageService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Auto-include pending items logic
    final allItems = _storageService.getAllFollowUpItems();
    final pending = allItems.where((item) => !item.isCompleted).toList();

    // Sort by due date (ascending) then priority
    pending.sort((a, b) {
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      return 0; // Keep existing order
    });

    setState(() {
      _pendingItems = pending;
      // Auto-select all pending items by default for the agenda
      _selectedItemIds.addAll(pending.map((e) => e.id));
      _isLoading = false;
    });
  }

  Future<void> _generateAgenda() async {
    final selectedItems = _pendingItems
        .where((item) => _selectedItemIds.contains(item.id))
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items selected for agenda')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Generate Risk Mitigation Questions
    final combinedText = selectedItems.map((e) => e.description).join(' ');
    final riskQuestions = await RiskMitigationService()
        .generateRiskMitigationQuestions(combinedText);

    final buffer = StringBuffer();
    buffer.writeln('Doctor Visit Agenda');
    buffer.writeln('Generated on ${DateTime.now().toString().split(' ')[0]}');
    buffer.writeln();

    buffer.writeln('--- Follow-Up Items ---');
    for (final item in selectedItems) {
      buffer.writeln(
          '• [${item.category.toDisplayString()}] ${item.description}');
      if (item.dueDate != null) {
        buffer.writeln('  Due: ${item.dueDate.toString().split(' ')[0]}');
      }
    }

    if (riskQuestions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('--- Discussion Prompts (Risk Mitigation) ---');
      for (final q in riskQuestions) {
        buffer.writeln('• $q');
      }
    }

    // TODO: Add recent health summary or other sections here if needed

    final agendaText = buffer.toString();

    if (mounted) {
      setState(() => _isLoading = false);

      // Show dialog with generated text
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Visit Agenda'),
          content: SingleChildScrollView(
            child: SelectableText(agendaText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: agendaText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Agenda copied to clipboard')),
                );
                Navigator.pop(context);
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Doctor Visit Prep'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Select items to include in your visit agenda.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Expanded(
                    child: _pendingItems.isEmpty
                        ? Center(
                            child: Text(
                              'No pending items found.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.disabledColor,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _pendingItems.length,
                            itemBuilder: (context, index) {
                              final item = _pendingItems[index];
                              final isSelected =
                                  _selectedItemIds.contains(item.id);

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedItemIds.add(item.id);
                                    } else {
                                      _selectedItemIds.remove(item.id);
                                    }
                                  });
                                },
                                title: Text(item.description),
                                subtitle: Text(
                                  '${item.category.toDisplayString()} • ${item.priority == FollowUpPriority.high ? 'High Priority' : 'Normal'}',
                                ),
                                secondary: Icon(
                                  item.category.icon,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.disabledColor,
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GlassButton(
                      label: 'Generate Agenda',
                      icon: Icons.assignment_turned_in_outlined,
                      onPressed: _generateAgenda,
                      isProminent: true,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
