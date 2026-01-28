import 'package:flutter/material.dart';
import '../models/document_extraction.dart';
import '../models/health_record.dart';
import '../services/ui_target_resolver.dart';
import '../ui/mobile/screens/document_categorization_screen_mobile.dart';
import '../ui/desktop/screens/document_categorization_screen_desktop.dart';
import '../utils/design_constants.dart';

class DocumentCategorizationScreen extends StatelessWidget {
  final DocumentExtraction extraction;
  final HealthCategory? suggestedCategory;
  final double confidence;
  final String reasoning;

  const DocumentCategorizationScreen({
    super.key,
    required this.extraction,
    required this.suggestedCategory,
    required this.confidence,
    required this.reasoning,
  });

  @override
  Widget build(BuildContext context) {
    if (DesignConstants.isDesktop(context)) {
      return DocumentCategorizationScreenDesktop(
        extraction: extraction,
        suggestedCategory: suggestedCategory,
        confidence: confidence,
        reasoning: reasoning,
      );
    } else {
      return DocumentCategorizationScreenMobile(
        extraction: extraction,
        suggestedCategory: suggestedCategory,
        confidence: confidence,
        reasoning: reasoning,
      );
    }
  }
}
