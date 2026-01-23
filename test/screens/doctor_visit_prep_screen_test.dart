import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/follow_up_item.dart';
import 'package:sehatlocker/screens/doctor_visit_prep_screen.dart';
import 'package:sehatlocker/services/local_storage_service.dart';

// Fake LocalStorageService
class FakeLocalStorageService implements LocalStorageService {
  final List<FollowUpItem> _items;

  FakeLocalStorageService(this._items);

  @override
  List<FollowUpItem> getAllFollowUpItems() {
    return _items;
  }

  // Stub other methods as needed, or use noSuchMethod if we want to be lazy (but typed is better)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('DoctorVisitPrepScreen shows pending items and generates agenda',
      (WidgetTester tester) async {
    // Setup test data
    final item1 = FollowUpItem(
      id: '1',
      category: FollowUpCategory.medication,
      verb: 'take',
      object: 'pills',
      description: 'Take pills',
      priority: FollowUpPriority.normal,
      sourceConversationId: 'c1',
      createdAt: DateTime.now(),
      isCompleted: false,
    );

    final item2 = FollowUpItem(
      id: '2',
      category: FollowUpCategory.appointment,
      verb: 'schedule',
      object: 'visit',
      description: 'Schedule visit',
      priority: FollowUpPriority.high,
      sourceConversationId: 'c1',
      createdAt: DateTime.now(),
      isCompleted: true, // Completed item should not show
    );

    final item3 = FollowUpItem(
      id: '3',
      category: FollowUpCategory.test,
      verb: 'do',
      object: 'test',
      description: 'Do blood test',
      priority: FollowUpPriority.normal,
      sourceConversationId: 'c1',
      createdAt: DateTime.now(),
      isCompleted: false,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    );

    final fakeService = FakeLocalStorageService([item1, item2, item3]);

    await tester.pumpWidget(MaterialApp(
      home: DoctorVisitPrepScreen(storageService: fakeService),
    ));
    await tester.pumpAndSettle();

    // Verify items
    expect(find.text('Take pills'), findsOneWidget);
    expect(find.text('Schedule visit'), findsNothing); // Completed
    expect(find.text('Do blood test'), findsOneWidget);

    // Verify Checkboxes are checked by default
    final checkbox1 = tester.widget<Checkbox>(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, 'Take pills'),
        matching: find.byType(Checkbox),
      ),
    );
    expect(checkbox1.value, true);

    // Tap "Generate Agenda"
    await tester.tap(find.text('Generate Agenda'));
    await tester.pumpAndSettle();

    // Verify Dialog content
    expect(find.text('Visit Agenda'), findsOneWidget);
    expect(find.textContaining('Doctor Visit Agenda'), findsOneWidget);

    // Check for items inside the dialog content (which is a SelectableText)
    // Since 'Take pills' is also in the background list, we might find multiple.
    // We want to ensure it is present in the generated text.
    expect(find.textContaining('Take pills'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Do blood test'), findsAtLeastNWidgets(1));

    // Close dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });
}
