/// Exception thrown when attempting to access unverified health data.
/// 
/// This exception ensures FDA compliance by preventing access to health metrics
/// before Phase 1 completion (user verification of documents).
class UnverifiedDataException implements Exception {
  final String message;
  
  UnverifiedDataException(this.message);
  
  @override
  String toString() => 'UnverifiedDataException: $message';
}