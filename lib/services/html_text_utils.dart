/// Strips HTML (especially Open Food Facts allergen spans) from product text.
class HtmlTextUtils {
  HtmlTextUtils._();

  static final RegExp _tagPattern = RegExp(r'<[^>]*>', multiLine: true, dotAll: true);
  static final RegExp _whitespacePattern = RegExp(r'\s+');
  static final RegExp _markupPattern = RegExp(
    r'''<\s*/?\s*(span|div|p|br|b|i|em|strong|u)\b|class\s*=\s*["']?allergen''',
    caseSensitive: false,
  );

  static String _decodeEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }

  /// Removes tags and decodes common entities. Safe for ingredient matching.
  /// Decode first so `&lt;span&gt;tree nuts&lt;/span&gt;` still yields "tree nuts".
  static String strip(String? input) {
    if (input == null || input.isEmpty) return '';
    var text = _decodeEntities(input);
    text = text.replaceAll(_tagPattern, ' ');
    text = _decodeEntities(text).replaceAll(_tagPattern, ' ');
    return text.replaceAll(_whitespacePattern, ' ').trim();
  }

  /// Plain text for the UI. Empty when nothing readable remains after stripping.
  static String forDisplay(dynamic value) {
    var stripped = strip(value?.toString());
    if (stripped.isEmpty) return '';
    if (_markupPattern.hasMatch(stripped)) {
      stripped = strip(stripped.replaceAll(_markupPattern, ' '));
    }
    return stripped;
  }

  static List<String> forDisplayList(Iterable<dynamic> values) {
    return values.map(forDisplay).where((text) => text.isNotEmpty).toList();
  }
}
