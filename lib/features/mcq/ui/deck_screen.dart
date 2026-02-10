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
      builder: (context) => const _FilterOptionsSheet(),
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

class _FilterOptionsSheet extends ConsumerStatefulWidget {
  const _FilterOptionsSheet();

  @override
  ConsumerState<_FilterOptionsSheet> createState() =>
      _FilterOptionsSheetState();
}

class _FilterOptionsSheetState extends ConsumerState<_FilterOptionsSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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

  static final Map<String, IconData> _subjectIcons = {
    'Anatomy': LucideIcons.bone,
    'Physiology': LucideIcons.activity,
    'Biochemistry': LucideIcons.flaskConical,
    'Pharmacology': LucideIcons.pill,
    'Pathology': LucideIcons.microscope,
    'Microbiology': LucideIcons.microscope,
    'Forensic Medicine': LucideIcons.scale,
    'SPM': LucideIcons.users,
    'ENT': LucideIcons.ear,
    'Ophthalmology': LucideIcons.eye,
    'Medicine': LucideIcons.stethoscope,
    'Surgery': LucideIcons.scissors,
    'OBG': LucideIcons.baby,
    'Pediatrics': LucideIcons.baby,
    'Orthopedics': LucideIcons.accessibility,
    'Psychiatry': LucideIcons.brain,
    'Dermatology': LucideIcons.sparkles,
    'Radiology': LucideIcons.scan,
    'Anesthesia': LucideIcons.syringe,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deckState = ref.watch(deckProvider);
    final selectedSubject = deckState.selectedSubject;

    final filteredSubjects = _subjects
        .where((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.dark.background
            : AppColors.light.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deck Settings',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                    ),
                    Text(
                      'Filter by subject or refresh data',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    ref.read(deckProvider.notifier).refresh();
                    Navigator.pop(context);
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search subjects...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: context.isDark
                    ? AppColors.dark.cardSurface
                    : AppColors.light.cardSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, indent: 24, endIndent: 24),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              children: [
                // All Subjects Tile
                _buildSubjectTile(
                  context: context,
                  title: 'All Subjects',
                  icon: LucideIcons.layers,
                  isSelected: selectedSubject == null,
                  onTap: () {
                    ref.read(deckProvider.notifier).setSubjectFilter(null);
                    Navigator.pop(context);
                  },
                  isSpecial: true,
                ),

                const SizedBox(height: 16),
                Text(
                  'ALL SUBJECTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),

                ...filteredSubjects.map((subject) {
                  final isSelected = selectedSubject == subject;
                  return _buildSubjectTile(
                    context: context,
                    title: subject,
                    icon: _subjectIcons[subject] ?? LucideIcons.book,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(deckProvider.notifier).setSubjectFilter(subject);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? context.primaryColor.withValues(alpha: 0.1)
            : (context.isDark
                ? AppColors.dark.cardSurface
                : AppColors.light.cardSurface),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.primaryColor
                        : (context.isDark
                            ? Colors.grey[850]
                            : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : context.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color:
                          isSelected ? context.primaryColor : context.textColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(LucideIcons.checkCircle2,
                      size: 20, color: context.primaryColor)
                else
                  Icon(LucideIcons.chevronRight,
                      size: 18,
                      color: context.textSecondaryColor.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
