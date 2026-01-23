import 'dart:math';

class StringUtils {
  /// Calculates the Levenshtein distance between two strings.
  /// 
  /// The Levenshtein distance is the minimum number of single-character edits 
  /// (insertions, deletions or substitutions) required to change one word into the other.
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) {
      return 0;
    }
    if (s1.isEmpty) {
      return s2.length;
    }
    if (s2.isEmpty) {
      return s1.length;
    }

    List<int> v0 = List<int>.filled(s2.length + 1, 0);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s2.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j < s2.length + 1; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }

  /// Calculates the similarity between two strings based on Levenshtein distance.
  /// 
  /// Returns a value between 0.0 (completely different) and 1.0 (identical).
  static double calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) {
      return 1.0;
    }
    if (s1.isEmpty || s2.isEmpty) {
      return 0.0;
    }

    int distance = levenshteinDistance(s1, s2);
    int maxLength = max(s1.length, s2.length);

    return 1.0 - (distance / maxLength);
  }
}
