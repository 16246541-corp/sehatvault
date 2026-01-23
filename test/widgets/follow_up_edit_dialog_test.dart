import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/follow_up_item.dart';
import 'package:sehatlocker/widgets/dialogs/follow_up_edit_dialog.dart';

void main() {
  testWidgets('FollowUpEditDialog allows editing fields',
      (WidgetTester tester) async {
    final item = FollowUpItem(
      id: '1',
      category: FollowUpCategory.medication,
      verb: 'take',
      object: 'pills',
      description: 'Take pills',
      priority: FollowUpPriority.normal,
      sourceConversationId: 'conv1',
      createdAt: DateTime.now(),
      isCompleted: false,
    );

    FollowUpItem? savedItem;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => FollowUpEditDialog(
                  item: item,
                  onSave: (newItem) {
                    savedItem = newItem;
                  },
                ),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    ));

    // Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify initial state
    expect(find.text('Take pills'), findsOneWidget);
    expect(find.text('Medication'), findsOneWidget);

    // Edit description
    await tester.enterText(
        find.widgetWithText(TextField, 'Description'), 'Take pills daily');

    // Toggle priority
    // Initially priority is normal, so 'High' text is NOT visible.
    // Find the InkWell that contains the priority icon
    final priorityToggle = find.ancestor(
      of: find.byIcon(Icons.priority_high),
      matching: find.byType(InkWell),
    );
    await tester.tap(priorityToggle);
    await tester.pump();

    // Now 'High' text should be visible
    expect(find.text('High'), findsOneWidget);

    // Change category
    await tester.tap(find.text('Medication')); // Opens dropdown
    await tester.pumpAndSettle();
    await tester.tap(find
        .text('Test')
        .last); // Selects 'Test' (last because one in dropdown list)
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(savedItem, isNotNull);
    expect(savedItem!.description, 'Take pills daily');
    expect(savedItem!.priority, FollowUpPriority.high);
    expect(savedItem!.category, FollowUpCategory.test);
  });
}
