import 'package:flutter/material.dart';
import '../../../models/document_extraction.dart';
import '../../../models/health_record.dart';
import '../../../shared/widgets/document_categorization_content.dart';
import '../../../screens/extraction_verification_screen.dart';

class DocumentCategorizationScreenMobile extends StatelessWidget {
  final DocumentExtraction extraction;
  final HealthCategory? suggestedCategory;
  final double confidence;
  final String reasoning;

  const DocumentCategorizationScreenMobile({
    super.key,
    required this.extraction,
    required this.suggestedCategory,
    required this.confidence,
    required this.reasoning,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Document'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: DocumentCategorizationContent(
          extraction: extraction,
          suggestedCategory: suggestedCategory,
          confidence: confidence,
          reasoning: reasoning,
          onSave: (category) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExtractionVerificationScreen(
                  extraction: extraction,
                  category: category,
                ),
              ),
            );
          },
          onCancel: () => Navigator.pop(context, null),
        ),
      ),
    );
  }
}
