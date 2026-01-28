import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/document_extraction.dart';
import 'package:sehatlocker/models/health_record.dart';
import 'package:sehatlocker/shared/widgets/document_categorization_content.dart';
import 'package:sehatlocker/ui/mobile/screens/document_categorization_screen_mobile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final extraction = DocumentExtraction(
    extractedText: 'Sample medical text',
    structuredData: {},
    confidenceScore: 0.9,
    originalImagePath: 'path/to/image.jpg',
  );

  testWidgets('DocumentCategorizationContent displays information correctly',
      (WidgetTester tester) async {
    HealthCategory? savedCategory;
    bool cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocumentCategorizationContent(
            extraction: extraction,
            suggestedCategory: HealthCategory.labResults,
            confidence: 0.8,
            reasoning: 'Test reasoning',
            onSave: (cat) => savedCategory = cat,
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );

    // Verify text display
    expect(find.text('Sample medical text'), findsOneWidget);
    
    // Verify suggestion
    expect(find.text('Suggested: Lab Results'), findsOneWidget);
    expect(find.text('80% confidence'), findsOneWidget);

    // Verify actions
    await tester.tap(find.text('Discard'));
    expect(cancelled, true);

    await tester.tap(find.text('Add to Vault'));
    expect(savedCategory, HealthCategory.labResults); // Default selection matches suggestion
  });

  testWidgets('DocumentCategorizationScreenMobile returns category on save',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentCategorizationScreenMobile(
                    extraction: extraction,
                    suggestedCategory: HealthCategory.prescriptions,
                    confidence: 0.9,
                    reasoning: 'Meds detected',
                  ),
                ),
              );
            },
            child: const Text('Go'),
          ),
        ),
      ),
    );

    // Navigate
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    // Verify screen loaded
    expect(find.text('Review Document'), findsOneWidget);

    // Tap Add to Vault
    await tester.tap(find.text('Add to Vault'));
    await tester.pumpAndSettle();

    // Verify verification screen is pushed
    expect(find.text('Verify Extraction'), findsOneWidget);
  });
}
