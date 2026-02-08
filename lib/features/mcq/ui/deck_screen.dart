import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../bookmarks/providers/bookmark_provider.dart';
import '../providers/deck_provider.dart';
import 'widgets/swipeable_card.dart';
import 'widgets/mcq_card.dart';
import '../../../core/utils/constants.dart';

/// DeckScreen - Main swipeable MCQ card screen
class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key});

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  // Local debouncer
  bool _isSwiping = false;

  void _handleSwipeComplete(bool isUp, DeckState deckState) async {
    if (_isSwiping) return;
    _isSwiping = true;

    // DeckNotifier.nextCard() handles marking as viewed internally
    ref.read(deckProvider.notifier).nextCard();

    // Unlock swipe after a brief buffer
    await Future.delayed(const Duration(milliseconds: 200));
    _isSwiping = false;
  }

  void _handleToggleBookmark(MCQ mcq) {
    final bookmarks = ref.read(bookmarkStateProvider.notifier);

    if (bookmarks.isBookmarked(mcq.id)) {
      bookmarks.removeBookmark(mcq.id, null);
    } else {
      bookmarks.addBookmark(mcq, null);
    }
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckState = ref.watch(deckProvider);
    final cards = deckState.cards;
    final activeIndex = deckState.activeIndex;
    final isLoading = deckState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Deck',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (deckState.selectedSubject != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        deckState.selectedSubject!,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showFilterOptions(context),
                    icon: Icon(
                      LucideIcons.settings,
                      color: context.iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 58), // Width of Navicon (50) + gap (8)
                ],
              ),
            ),

            // Card stack
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : cards.isEmpty
                      ? _buildEmptyState()
                      : _buildCardStack(cards, activeIndex, deckState),
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
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: context.successColor,
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Come back later for more questions',
            style: TextStyle(color: context.textSecondaryColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(deckProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(
      List<MCQ> cards, int activeIndex, DeckState deckState) {
    // Render up to 10 cards ahead for smoothness
    const visibleCount = 10;

    // We only take what is available
    final available = cards.skip(activeIndex).take(visibleCount).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
      child: Stack(
        children: available
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key; // 0 to 9 ideally
              final mcq = entry.value;
              final isBookmarked = ref.watch(isBookmarkedProvider(mcq.id));

              // We only render the first 4 fully interactive or visible
              // The rest can be simplified or hidden to save resources, but
              // keeping them in the tree prevents "pop-in" of state.
              // SwipeableCard will handle the visual stacking logic using 'index'

              return SwipeableCard(
                key: ValueKey(mcq.id),
                index: index,
                activeIndex: 0, // In this sub-list, the top card is always 0
                onSwipeUp: () => _handleSwipeComplete(true, deckState),
                onSwipeDown: () => _handleSwipeComplete(false, deckState),
                // Only enable touch for the top card
                enabled: index == 0,
                child: MCQCard(
                  mcq: mcq,
                  mode: MCQCardMode.learn,
                  isBookmarked: isBookmarked,
                  onToggleBookmark: () => _handleToggleBookmark(mcq),
                  onNext: () => _handleSwipeComplete(true, deckState),
                ),
              );
            })
            .toList()
            .reversed // Stack: last in list is top visually if using Z-order?
            // NO. In Stack, last child is ON TOP.
            // So we must reverse: index 0 (Top card) should be LAST child.
            // List is [0, 1, 2...]. Reversed is [..., 2, 1, 0].
            // 0 is last -> 0 is Top. Correct.
            .toList(),
      ),
    );
  }
}

class _FilterOptionsSheet extends ConsumerWidget {
  static const _subjects = [
    'Anatomy',
    'Physiology',
    'Biochemistry',
    'Pharmacology',
    'Pathology',
    'Microbiology',
    'Forensic Medicine',
    'SPM',
    'ENT',
    'Ophthalmology',
    'Medicine',
    'Surgery',
    'OBG',
    'Pediatrics',
    'Orthopedics',
    'Psychiatry',
    'Dermatology',
    'Radiology',
    'Anesthesia'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckState = ref.watch(deckProvider);
    final selectedSubject = deckState.selectedSubject;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.dark.background
            : AppColors.light.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deck Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton.icon(
                  onPressed: () {
                    ref.read(deckProvider.notifier).refresh();
                    Navigator.pop(context);
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Subject',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All Subjects'),
                        selected: selectedSubject == null,
                        onSelected: (_) {
                          ref
                              .read(deckProvider.notifier)
                              .setSubjectFilter(null);
                          Navigator.pop(context);
                        },
                        backgroundColor: context.isDark
                            ? AppColors.dark.cardSurface
                            : AppColors.light.cardSurface,
                        selectedColor:
                            context.primaryColor.withValues(alpha: 0.2),
                        // Checkmark color implicitly handled but can force if needed
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: selectedSubject == null
                              ? context.primaryColor
                              : context.textColor,
                          fontWeight: selectedSubject == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: selectedSubject == null
                                ? context.primaryColor
                                : (context.isDark
                                    ? AppColors.dark.border
                                    : AppColors.light.border),
                          ),
                        ),
                      ),
                      ..._subjects.map((subject) {
                        final isSelected = selectedSubject == subject;
                        return FilterChip(
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(deckProvider.notifier)
                                .setSubjectFilter(subject);
                            Navigator.pop(context);
                          },
                          backgroundColor: context.isDark
                              ? AppColors.dark.cardSurface
                              : AppColors.light.cardSurface,
                          selectedColor:
                              context.primaryColor.withValues(alpha: 0.2),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? context.primaryColor
                                : context.textColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? context.primaryColor
                                  : (context.isDark
                                      ? AppColors.dark.border
                                      : AppColors.light.border),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
