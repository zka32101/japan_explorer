import 'package:flutter/material.dart';

/// 記事本文用の軽量な表示。`**太字**` と行頭の `#` 見出しだけを扱い、
/// 記号がそのまま画面に出ないようにする。
class SimpleMarkdownText extends StatelessWidget {
  const SimpleMarkdownText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  static final _bold = RegExp(r'\*\*(.+?)\*\*');
  static final _heading = RegExp(r'^\s{0,3}#{1,6}\s+');

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      final isHeading = _heading.hasMatch(line);
      if (isHeading) line = line.replaceFirst(_heading, '');
      final lineStyle =
          isHeading ? base.copyWith(fontWeight: FontWeight.bold) : base;
      var pos = 0;
      for (final m in _bold.allMatches(line)) {
        if (m.start > pos) {
          spans.add(TextSpan(text: line.substring(pos, m.start), style: lineStyle));
        }
        spans.add(TextSpan(
          text: m.group(1),
          style: lineStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        pos = m.end;
      }
      if (pos < line.length) {
        spans.add(TextSpan(text: line.substring(pos), style: lineStyle));
      }
      if (i < lines.length - 1) spans.add(TextSpan(text: '\n', style: base));
    }
    return Text.rich(TextSpan(children: spans, style: base));
  }
}
