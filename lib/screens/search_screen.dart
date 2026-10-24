import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/theme/app_icons.dart';
import '../widgets/theme/brand_header.dart';
import '../widgets/theme/paper_background.dart';
import '../providers/curations_provider.dart';
import '../widgets/curation_card.dart';
import '../config/theme.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider(_query));

    return Scaffold(
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
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: tr('search.hint'),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _debounce?.cancel();
                                  _controller.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) {
                        _debounce?.cancel();
                        if (v.isEmpty) {
                          setState(() => _query = '');
                          return;
                        }
                        if (v.length < 2) return;
                        _debounce = Timer(const Duration(milliseconds: 350), () {
                          if (mounted) setState(() => _query = v.trim());
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.isEmpty
          ? RepaintBoundary(child: _buildEmptyState())
          : resultsAsync.when(
              loading: () => RepaintBoundary(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => RepaintBoundary(
                child: Center(child: Text('Error: $e')),
              ),
              data: (curations) {
                if (curations.isEmpty) {
                  return RepaintBoundary(
                    child: Center(
                      child: Text('No results for "$_query"'),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: curations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final curation = curations[index];
                    return RepaintBoundary(
                      child: CurationCard(
                        curation: curation,
                        onTap: () => context.go('/home/detail/${curation.id}'),
                      ),
                    );
                  },
                );
              },
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppIconChip(AppGlyph.search, size: 80),
          const SizedBox(height: 16),
          Text(
            tr('search.empty_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            tr('search.empty_hint'),
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
