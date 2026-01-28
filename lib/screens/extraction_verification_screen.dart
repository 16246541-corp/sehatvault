import 'package:flutter/material.dart';
import '../models/document_extraction.dart';
import '../models/health_record.dart';
import '../utils/design_constants.dart';
import '../ui/mobile/screens/extraction_verification_screen_mobile.dart';
import '../ui/desktop/screens/extraction_verification_screen_desktop.dart';

class ExtractionVerificationScreen extends StatelessWidget {
  final DocumentExtraction extraction;
  final HealthCategory category;

  const ExtractionVerificationScreen({
    super.key,
    required this.extraction,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    if (DesignConstants.isDesktop(context)) {
      return ExtractionVerificationScreenDesktop(
        extraction: extraction,
        category: category,
      );
    } else {
      return ExtractionVerificationScreenMobile(
        extraction: extraction,
        category: category,
      );
    }
  }
}
