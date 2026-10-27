import 'package:flutter/material.dart';

import '../models/curation.dart';

/// スポットの画像が無い/読み込み前/失敗のときの共通の枠。
/// 暗い背景に合う紺色のグラデーションに、カテゴリの絵文字を置く。
class CurationImagePlaceholder extends StatelessWidget {
  const CurationImagePlaceholder({
    super.key,
    required this.category,
    this.emojiSize = 40,
  });

  final String category;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2F4A), Color(0xFF1B1E33)],
        ),
      ),
      child: Center(
        child: Text(
          CurationCategory.emoji(category),
          style: TextStyle(fontSize: emojiSize),
        ),
      ),
    );
  }
}
