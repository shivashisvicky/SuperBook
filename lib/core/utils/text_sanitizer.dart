extension TextSanitizer on String {
  String cleanOcr() {
    return replaceAll(RegExp(r'[_\^§\$#\|]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
