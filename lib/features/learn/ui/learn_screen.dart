import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'widgets/flashcard_deck.dart';
import 'widgets/mock_test_config.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../exam/providers/exam_provider.dart';

/// LearnScreen - Flashcards and Mock Test configuration
/// Matches React Native (tabs)/learn.tsx
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  String _view = 'menu'; // menu, flashcards, mocktest_config

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_view) {
      case 'flashcards':
        return FlashcardDeck(onBack: () => setState(() => _view = 'menu'));
      case 'mocktest_config':
        return MockTestConfig(
          onBack: () => setState(() => _view = 'menu'),
          onStart: (config) {
            final notifier = ref.read(examStateProvider.notifier);

            if (config.containsKey('pack')) {
              notifier.startTestWithPack(config['pack'] as QuestionPack);
            } else {
              notifier.startTestWithConfig(config);
            }

            context.push('/exam');
            setState(() => _view = 'menu');
          },
        );
      default:
        return _MenuView(
          onFlashcards: () => setState(() => _view = 'flashcards'),
          onMockTest: () => setState(() => _view = 'mocktest_config'),
        );
    }
  }
}

class _MenuView extends StatelessWidget {
  final VoidCallback onFlashcards;
  final VoidCallback onMockTest;

  const _MenuView({
    required this.onFlashcards,
    required this.onMockTest,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learn',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _MenuCard(
            icon: LucideIcons.layers,
            title: 'Flashcards',
            description: 'Quick revision with flip cards',
            color: const Color(0xFF6366f1),
            onTap: onFlashcards,
          ),
          const SizedBox(height: 16),
          _MenuCard(
            icon: LucideIcons.brainCircuit,
            title: 'Mock Test',
            description: 'Timed practice with scoring',
            color: const Color(0xFFf59e0b),
            onTap: onMockTest,
          ),
          const SizedBox(height: 16),
          _MenuCard(
            icon: LucideIcons.bookmark,
            title: 'Bookmarks',
            description: 'Review saved questions',
            color: const Color(0xFF22c55e),
            onTap: () {
              context.push('/bookmarks');
            },
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardSurfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: context.iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
