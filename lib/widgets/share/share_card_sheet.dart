import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/share_card_service.dart';
import 'share_card_frame.dart';

/// Bottom sheet that previews a share card, lets the user pick a seasonal
/// frame (defaulting to the current season) and shares the card as an image.
///
/// [cardBuilder] builds the whole card (usually a [ShareCardFrame]) for the
/// chosen [CardFrameStyle].
Future<void> showShareCardSheet(
  BuildContext context, {
  required Widget Function(BuildContext context, CardFrameStyle style)
      cardBuilder,
  String? shareText,
  String? subject,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ShareCardSheet(
      cardBuilder: cardBuilder,
      shareText: shareText,
      subject: subject,
    ),
  );
}

class _ShareCardSheet extends StatefulWidget {
  const _ShareCardSheet({
    required this.cardBuilder,
    this.shareText,
    this.subject,
  });

  final Widget Function(BuildContext context, CardFrameStyle style) cardBuilder;
  final String? shareText;
  final String? subject;

  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet> {
  final _boundaryKey = GlobalKey();
  CardFrameStyle _style = CardFrameStyleX.forDate(DateTime.now());
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await shareBoundaryAsImage(
        _boundaryKey,
        text: widget.shareText,
        subject: widget.subject,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final s in CardFrameStyle.values)
                  ChoiceChip(
                    label: Text(s.emoji),
                    selected: _style == s,
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    onSelected: (_) => setState(() => _style = s),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AspectRatio(
                aspectRatio: ShareCardFrame.width / ShareCardFrame.height,
                child: FittedBox(
                  // The boundary keeps the card's own 360×450 size, so the
                  // captured image does not depend on the preview scale.
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: widget.cardBuilder(context, _style),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sharing ? null : _share,
                icon: const Icon(Icons.ios_share),
                label: Text(tr('common.share')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
