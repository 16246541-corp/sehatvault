import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/health_record.dart';
import 'package:sehatlocker/widgets/cards/document_grid_card.dart';

void main() {
  testWidgets('DocumentGridCard displays title and category', (WidgetTester tester) async {
    final record = HealthRecord(
      id: '1',
      title: 'Test Document',
      category: 'Lab Results',
      createdAt: DateTime.now(),
      filePath: null, // No image for test
      recordType: HealthRecord.typeDocumentExtraction,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocumentGridCard(
            record: record,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Document'), findsOneWidget);
    expect(find.text('LAB RESULTS'), findsOneWidget); // CategoryBadge uppercases it
  });
}
