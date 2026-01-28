import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/document_extraction.dart';
import 'package:sehatlocker/shared/widgets/verification/verified_extraction_card.dart';

void main() {
  final extraction = DocumentExtraction(
    extractedText: 'Hemoglobin: 14.5 g/dL',
    structuredData: {
      'lab_values': [
        {
          'field': 'Hemoglobin',
          'value': '14.5',
          'unit': 'g/dL',
        }
      ],
      'medications': [],
      'vitals': [],
      'dates': [],
    },
    confidenceScore: 0.9,
    originalImagePath: 'dummy_path.jpg',
  );

  testWidgets('VerifiedExtractionCard displays extracted data',
      (WidgetTester tester) async {
    Map<String, dynamic>? changes;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VerifiedExtractionCard(
              extraction: extraction,
              onDataChanged: (data) => changes = data,
              patientGender: 'male',
            ),
          ),
        ),
      ),
    );

    // Verify Lab Values header
    expect(find.text('Lab Values'), findsOneWidget);

    // Verify field and value
    expect(find.text('Hemoglobin'), findsOneWidget);
    expect(find.text('14.5'), findsOneWidget);
    expect(find.text('g/dL'), findsOneWidget);

    // Edit value
    await tester.enterText(find.widgetWithText(TextField, '14.5'), '15.0');
    await tester.pump();

    expect(changes, isNotNull);
    final labValues = changes!['lab_values'] as List;
    expect((labValues[0] as Map)['value'], '15.0');
  });

  testWidgets('VerifiedExtractionCard allows adding new lab value',
      (WidgetTester tester) async {
    Map<String, dynamic>? changes;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VerifiedExtractionCard(
              extraction: extraction,
              onDataChanged: (data) => changes = data,
              patientGender: 'male',
            ),
          ),
        ),
      ),
    );

    // Find add button (icon button with add icon)
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
    await tester.pump();

    // Should have 2 items now (original + new empty one)
    final labValues = changes!['lab_values'] as List;
    expect(labValues.length, 2);
  });
}
