class HallucinationFilter {
  bool isHallucinated(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return true;
    }

    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length < 6) {
      return false;
    }

    final unique = words.toSet().length;
    final ratio = unique / words.length;
    return ratio < 0.3;
  }
}
