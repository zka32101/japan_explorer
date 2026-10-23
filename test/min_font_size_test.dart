import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:japan_explorer/config/theme.dart';

/// Keeps text readable: no literal font size below [kMinFontSize] in lib/.
void main() {
  test('no fontSize literal smaller than kMinFontSize', () {
    final pattern = RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)');
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final m in pattern.allMatches(lines[i])) {
          if (double.parse(m.group(1)!) < kMinFontSize) {
            offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
