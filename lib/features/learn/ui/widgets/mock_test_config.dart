import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../mcq/providers/question_pack_provider.dart';

class MockTestConfig extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  // In a real app, we'd pass config back to a controller or start the test directly
  // For now, we'll just simulate the RN 'onStart' by navigating or printing
  final Function(Map<String, dynamic>)? onStart;

  const MockTestConfig({super.key, required this.onBack, this.onStart});

  @override
  ConsumerState<MockTestConfig> createState() => _MockTestConfigState();
}

class _MockTestConfigState extends ConsumerState<MockTestConfig>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State
  String _selectedMode = 'rapid';
  int _selectedCount = 10;
  final List<String> _selectedSubjects = [];

  static const modes = [
    {
      'id': 'blaze',
      'title': 'Blaze Mode',
      'subtitle': '10s per question',
      'color': Color(0xFFf59e0b),
      'icon': LucideIcons.zap
    },
    {
      'id': 'rapid',
      'title': 'Rapid Fire',
      'subtitle': '30s per question',
      'color': Color(0xFF3b82f6),
      'icon': LucideIcons.clock
    },
    {
      'id': 'calm',
      'title': 'Calm Mode',
      'subtitle': 'No time limit',
      'color': Color(0xFF10b981),
      'icon': LucideIcons.coffee
    },
  ];

  static const counts = [10, 20, 30, 50];
  static const subjects = [
    'Anatomy',
    'Physiology',
    'Biochemistry',
    'Pathology',
    'Pharmacology'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _handleStart() {
    widget.onStart?.call({
      'mode': _selectedMode,
      'count': _selectedCount,
      'subjects': _selectedSubjects.isEmpty ? subjects : _selectedSubjects,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(LucideIcons.arrowLeft, color: context.textColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'New Test',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: context.borderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: context.textColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelColor: context.cardSurfaceColor,
                  unselectedLabelColor: context.textSecondaryColor,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Custom'),
                    Tab(text: 'Packs'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCustomTab(),
                  _buildPacksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionTitle('SELECT MODE'),
        ...modes.map((mode) {
          final isSelected = _selectedMode == mode['id'];
          final color = mode['color'] as Color;

          return GestureDetector(
            onTap: () => setState(() => _selectedMode = mode['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardSurfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(mode['icon'] as IconData,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          mode['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.check,
                          color: Colors.white, size: 12),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        _buildSectionTitle('NUMBER OF QUESTIONS'),
        Row(
          children: counts.map((count) {
            final isSelected = _selectedCount == count;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedCount = count),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.primaryColor
                        : context.cardSurfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.borderColor),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : context.textSecondaryColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('SELECT SUBJECTS'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subjects.map((subject) {
            final isSelected = _selectedSubjects.contains(subject);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedSubjects.remove(subject);
                } else {
                  if (!_selectedSubjects.contains(subject)) {
                    _selectedSubjects.add(subject);
                  }
                }
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.primaryColor
                      : context.cardSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white : context.textSecondaryColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.textColor, // Dark button
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              elevation: 8,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Start Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 8),
                Icon(LucideIcons.chevronRight),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPacksTab() {
    final packsAsync = ref.watch(questionPacksProvider);

    return packsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (packs) {
        if (packs.isEmpty) {
          return const Center(child: Text('No packs available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: packs.length,
          itemBuilder: (context, index) {
            final pack = packs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.cardSurfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text(
                  pack.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: context.textColor),
                ),
                subtitle: Text(
                  '${pack.subject} • ${pack.questions.length} Questions',
                  style: TextStyle(color: context.textSecondaryColor),
                ),
                trailing: Icon(LucideIcons.chevronRight,
                    color: context.textSecondaryColor),
                onTap: () {
                  // Handle pack start
                  widget.onStart?.call({'pack': pack});
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94a3b8),
          letterSpacing: 1,
        ),
      ),
    );
  }
}
