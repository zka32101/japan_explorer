import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders the [RepaintBoundary] behind [boundaryKey] to a PNG and opens the
/// OS share sheet with it. Returns false when there was nothing to capture.
Future<bool> shareBoundaryAsImage(
  GlobalKey boundaryKey, {
  String? text,
  String? subject,
  double pixelRatio = 3,
}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return false;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) return false;
  final dir = await getTemporaryDirectory();
  final file = File(
      '${dir.path}/showglobe_card_${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(data.buffer.asUint8List());
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png')],
    text: text,
    subject: subject,
  );
  return true;
}
