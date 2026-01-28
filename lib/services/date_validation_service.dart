import 'package:intl/intl.dart';

/// Service for validating document dates and ensuring chronological plausibility
class DateValidationService {
  static const int _maxDaysBeforeCapture = 7;
  static const int _maxDaysAfterCapture = 1;
  static const int _maxDaysInFuture = 365;
  static final DateTime _minValidDate = DateTime(1900);

  /// Validates if an extracted document date is chronologically plausible
  /// relative to when the document was captured/scanned
  bool isChronologicallyPlausible(DateTime extracted, DateTime captureTime) {
    // Reject dates >7 days before capture (scanned old document) OR >1 day after capture (future date error)
    return extracted.isAfter(captureTime.subtract(const Duration(days: _maxDaysBeforeCapture))) &&
        extracted.isBefore(captureTime.add(const Duration(days: _maxDaysAfterCapture)));
  }

  /// Validates if a document date is within acceptable bounds
  bool isValidDocumentDate(DateTime date) {
    final now = DateTime.now();
    final maxFutureDate = now.add(const Duration(days: _maxDaysInFuture));
    
    // Date must be after 1900 and not more than 1 year in the future
    return date.isAfter(_minValidDate) && date.isBefore(maxFutureDate);
  }

  /// Gets the effective document date (user corrected or extracted)
  DateTime? getEffectiveDocumentDate(DateTime? extractedDate, DateTime? userCorrectedDate) {
    return userCorrectedDate ?? extractedDate;
  }

  /// Formats a date for display in the UI
  String formatDateForDisplay(DateTime? date) {
    if (date == null) return 'Not available';
    return DateFormat('MMM d, y').format(date);
  }

  /// Validates date extraction confidence based on context
  bool isHighConfidenceDate(String rawText, String dateText) {
    // High confidence if date appears in header/footer context
    final lowerText = rawText.toLowerCase();
    final lowerDate = dateText.toLowerCase();
    
    // Look for contextual indicators of document date
    final headerIndicators = ['report date', 'date:', 'created:', 'issued:', 'prepared:'];
    final footerIndicators = ['dated', 'date'];
    
    // Check if date appears near header indicators (within first 20% of text)
    final headerSection = lowerText.substring(0, (lowerText.length * 0.2).round());
    final hasHeaderContext = headerIndicators.any((indicator) => 
        headerSection.contains(indicator) && headerSection.contains(lowerDate));
    
    // Check if date appears near footer indicators (within last 10% of text)  
    final footerSection = lowerText.substring((lowerText.length * 0.9).round());
    final hasFooterContext = footerIndicators.any((indicator) => 
        footerSection.contains(indicator) && footerSection.contains(lowerDate));
    
    return hasHeaderContext || hasFooterContext;
  }
}