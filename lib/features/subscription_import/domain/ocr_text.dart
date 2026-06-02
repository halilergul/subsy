/// Plain recognized text from one source — the [OcrService] output.
///
/// Deliberately minimal (no bounding boxes in v1) so the parser stays pure and
/// the OCR implementation stays swappable (research.md D1, D6). The recognized
/// [lines] are in reading order and already trimmed.
class OcrText {
  const OcrText({required this.lines});

  /// Convenience for whole-blob scans.
  factory OcrText.fromRaw(String raw) {
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
    return OcrText(lines: lines);
  }

  final List<String> lines;

  /// Full recognized text (lines joined by newlines).
  String get raw => lines.join('\n');

  /// True when nothing readable was recognized.
  bool get isEmpty => lines.isEmpty;

  static const OcrText empty = OcrText(lines: []);
}
