import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/culture_content.dart';
import '../providers/daily_culture_provider.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';

class DailyCultureCard extends ConsumerWidget {
  const DailyCultureCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(dailyCultureProvider);
    final hasRead = ref.watch(dailyCultureReadTodayProvider);
    final language = ref.watch(languageProvider);
    final isEnglish = language == Language.en;

    return GestureDetector(
      onTap: () => _onTap(context, ref, content, hasRead),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: hasRead
              ? const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: (hasRead ? Colors.green : Colors.red).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category emoji / status icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: hasRead
                      ? const Icon(Icons.check_circle, color: Colors.white, size: 26)
                      : Text(
                          _categoryEmoji(content.categoryId),
                          style: const TextStyle(fontSize: 22),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '📅 ',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          hasRead ? "Today's Culture — Read ✓" : "Today's Culture",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      content.getTitle(isEnglish),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      content.getSubtitle(isEnglish),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    hasRead ? Icons.arrow_forward_ios : Icons.menu_book,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${content.readTime}m',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(
    BuildContext context,
    WidgetRef ref,
    CultureContent content,
    bool hasRead,
  ) {
    // Mark as read today (daily tracking)
    if (!hasRead) {
      ref.read(cultureReadProvider.notifier).markDailyRead(content.id);
    }
    context.push('/culture/${content.id}');
  }

  String _categoryEmoji(String categoryId) {
    switch (categoryId) {
      case 'culture': return '🏮';
      case 'food': return '🍱';
      case 'region': return '🗾';
      case 'art': return '🎨';
      case 'language': return '📖';
      case 'sport': return '🥋';
      case 'regions': return '🗾';
      default: return '🇯🇵';
    }
  }
}
