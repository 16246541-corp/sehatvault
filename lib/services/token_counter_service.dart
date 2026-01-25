import '../utils/secure_logger.dart';

/// Service for estimating token counts in different languages.
/// This uses a heuristic-based approach for performance and local execution.
class TokenCounterService {
  static final TokenCounterService _instance = TokenCounterService._internal();
  factory TokenCounterService() => _instance;
  TokenCounterService._internal();

  /// Estimates the number of tokens in a given [text].
  /// Supports multilingual estimation based on character sets.
  int countTokens(String text) {
    if (text.isEmpty) return 0;

    // Heuristic breakdown:
    // 1. CJK (Chinese, Japanese, Korean): 1 character ≈ 1-1.5 tokens (often 1:1 in many tokenizers)
    // 2. Arabic/Hebrew: 1 character ≈ 0.3-0.5 tokens (3-4 chars per token)
    // 3. Latin/English: 1 character ≈ 0.25 tokens (4 chars per token)
    // 4. Whitespace/Punctuation: usually 1 token each or merged.

    double totalTokens = 0;
    
    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      
      if (_isCJK(charCode)) {
        totalTokens += 1.0;
      } else if (_isArabic(charCode) || _isHebrew(charCode)) {
        totalTokens += 0.4; // ~2.5 chars per token
      } else if (_isWhitespace(charCode)) {
        totalTokens += 0.5; // Whitespace often merges
      } else {
        totalTokens += 0.25; // Standard Latin/English
      }
    }

    // Add a small buffer for safety and round up
    return (totalTokens * 1.1).ceil();
  }

  /// Checks if a character is from CJK sets.
  bool _isCJK(int charCode) {
    return (charCode >= 0x4E00 && charCode <= 0x9FFF) || // CJK Unified Ideographs
           (charCode >= 0x3040 && charCode <= 0x309F) || // Hiragana
           (charCode >= 0x30A0 && charCode <= 0x30FF) || // Katakana
           (charCode >= 0xAC00 && charCode <= 0xD7AF);   // Hangul Syllables
  }

  /// Checks if a character is Arabic.
  bool _isArabic(int charCode) {
    return (charCode >= 0x0600 && charCode <= 0x06FF);
  }

  /// Checks if a character is Hebrew.
  bool _isHebrew(int charCode) {
    return (charCode >= 0x0590 && charCode <= 0x05FF);
  }

  /// Checks if a character is whitespace.
  bool _isWhitespace(int charCode) {
    return charCode == 32 || charCode == 9 || charCode == 10 || charCode == 13;
  }

  /// Estimates context usage percentage.
  double calculateUsagePercentage(int currentTokens, int maxTokens) {
    if (maxTokens <= 0) return 0.0;
    return (currentTokens / maxTokens).clamp(0.0, 1.0);
  }

  /// Formats token count for display.
  String formatTokenCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
