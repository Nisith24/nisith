import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../mcq/ui/widgets/mcq_card.dart';
import '../providers/bookmark_provider.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  String? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    final allBookmarks = ref.watch(bookmarkStateProvider);

    // Grouping for chips
    final subjects =
        allBookmarks.map((e) => e.subject ?? 'General').toSet().toList()
          ..sort();

    // Filter logic
    final displayedBookmarks = _selectedSubject == null
        ? allBookmarks
        : allBookmarks.where((q) => q.subject == _selectedSubject).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookmarks',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (displayedBookmarks.isNotEmpty)
            IconButton(
              icon: const Icon(
                LucideIcons.playCircle,
                color: Colors.blueAccent,
              ),
              tooltip: 'Review these as Deck',
              onPressed: () {
                final uri = Uri(
                  path: '/bookmarks/deck',
                  queryParameters: _selectedSubject != null
                      ? {'subject': _selectedSubject}
                      : null,
                );
                context.push(uri.toString());
              },
            ),
        ],
      ),
      body: allBookmarks.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // Filter Chips
                if (subjects.isNotEmpty)
                  Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: subjects.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isSelected = _selectedSubject == null;
                          return ChoiceChip(
                            label: const Text('All'),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedSubject = null);
                            },
                          );
                        }
                        final subject = subjects[index - 1];
                        final isSelected = _selectedSubject == subject;
                        return ChoiceChip(
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(
                              () => _selectedSubject = val ? subject : null,
                            );
                          },
                        );
                      },
                    ),
                  ),

                // List Content
                Expanded(
                  child: displayedBookmarks.isEmpty
                      ? const Center(
                          child: Text('No bookmarks for this subject'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: displayedBookmarks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 24),
                          itemBuilder: (context, index) {
                            final mcq = displayedBookmarks[index];
                            return AspectRatio(
                              aspectRatio: 0.8,
                              child: MCQCard(
                                key: ValueKey(mcq.id),
                                mcq: mcq,
                                mode: MCQCardMode.learn,
                                isBookmarked: true,
                                onToggleBookmark: () {
                                  ref
                                      .read(bookmarkStateProvider.notifier)
                                      .removeBookmark(mcq.id, null);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            style: TextStyle(color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}
