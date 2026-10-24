import 'package:flutter/material.dart';

import 'brand_header.dart';
import 'paper_background.dart';

/// Sub-screen scaffold: [BrandHeader] with the title (and a back button when
/// the route can be popped) over a [PaperBackground]. [actions] are shown at
/// the right of the header; give them white icons/text. [bottom] (e.g. a
/// `TabBar`) sits on the paper just below the header.
class BrandScaffold extends StatelessWidget {
  const BrandScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.bottom,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  /// Shown between the header and [body], e.g. a `TabBar`.
  final Widget? bottom;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: PaperBackground(
        child: Column(
          children: [
            BrandHeader(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  Expanded(child: BrandHeaderTitle(title: title)),
                  ...actions,
                ],
              ),
            ),
            if (bottom != null) bottom!,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
