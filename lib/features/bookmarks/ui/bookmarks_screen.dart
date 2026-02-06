import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mcq/ui/widgets/mcq_card.dart';
import '../providers/bookmark_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookmarks',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bookmark,
                    size: 64,
                    color: context.textSecondaryColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarks yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save questions to review them later',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: bookmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final mcq = bookmarks[index];
                return MCQCard(
                  key: ValueKey(mcq.id),
                  mcq: mcq,
                  // Show answer immediately for review? Or let them try?
                  // "Review saved questions" usually implies studying. Learn mode is appropriate.
                  mode: MCQCardMode.learn,
                  isBookmarked: true,
                  onToggleBookmark: () {
                    final userId = ref.read(currentUserProvider)?.uid;
                    ref
                        .read(bookmarkStateProvider.notifier)
                        .removeBookmark(mcq.id, userId);
                  },
                );
              },
            ),
    );
  }
}
