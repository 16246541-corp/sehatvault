import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/widgets/compliance/emergency_use_banner.dart';

void main() {
  testWidgets('EmergencyUseBanner renders in light and dark themes',
      (WidgetTester tester) async {
    Future<void> pumpWithTheme(ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: EmergencyUseBanner(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Not for Medical Emergencies'), findsOneWidget);
    }

    await pumpWithTheme(ThemeData.light());
    await pumpWithTheme(ThemeData.dark());
  });

  testWidgets('EmergencyUseBanner opens details dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmergencyUseBanner(),
        ),
      ),
    );
    await tester.tap(find.text('Not for Medical Emergencies'));
    await tester.pumpAndSettle();
    expect(find.text('Important Safety Notice'), findsOneWidget);
    expect(find.text('I Understand'), findsOneWidget);
  });
}
