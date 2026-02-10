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
  final TextEditingController _customCountController = TextEditingController();

  static const modes = [
    {
      'id': 'blaze',
      'title': 'Blaze Mode',
      'subtitle': '10s per question',
      'color': Color(0xFFf59e0b),
      'icon': LucideIcons.zap,
    },
    {
      'id': 'rapid',
      'title': 'Rapid Fire',
      'subtitle': '30s per question',
      'color': Color(0xFF3b82f6),
      'icon': LucideIcons.clock,
    },
    {
      'id': 'calm',
      'title': 'Calm Mode',
      'subtitle': 'No time limit',
      'color': Color(0xFF10b981),
      'icon': LucideIcons.coffee,
    },
  ];

  static const counts = [10, 20, 30, 50, 100];
  static const subjects = [
    'Anatomy',
    'Physiology',
    'Biochemistry',
    'Pathology',
    'Microbiology',
    'Pharmacology',
    'Forensic Medicine',
    'Community Medicine',
    'ENT',
    'Ophthalmology',
    'Medicine',
    'Surgery',
    'OBG',
    'Pediatrics',
    'Psychiatry',
    'Radiology',
    'Dermatology',
    'Anesthesia',
    'Orthopedics',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _tabController.indexIsChanging) {
        // Prevent switching to Packs tab
        _tabController.index = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Packs are currently disabled.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
    _customCountController.text = _selectedCount.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customCountController.dispose();
    super.dispose();
  }

  void _handleStart() {
    final count = int.tryParse(_customCountController.text) ?? _selectedCount;
    widget.onStart?.call({
      'mode': _selectedMode,
      'count': count,
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
                  tabs: [
                    const Tab(text: 'Custom'),
                    Tab(
                      child: Opacity(
                        opacity: 0.5,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Packs'),
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.lock,
                              size: 12,
                              color: context.textSecondaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildCustomTab(), _buildPacksTab()],
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
        SizedBox(
          height: 65,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mode = modes[index];
              final isSelected = _selectedMode == mode['id'];
              final color = mode['color'] as Color;

              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedMode = mode['id'] as String),
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardSurfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : context.borderColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          mode['icon'] as IconData,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (mode['title'] as String).split(' ').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.textColor,
                              ),
                            ),
                            Text(
                              mode['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('NUMBER OF QUESTIONS'),
        Row(
          children: counts.map((count) {
            final isSelected = _selectedCount == count;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedCount = count;
                  _customCountController.text = count.toString();
                }),
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
        const SizedBox(height: 16),
        TextField(
          controller: _customCountController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Custom Amount (e.g. 75)',
            hintStyle: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              LucideIcons.hash,
              color: context.primaryColor,
              size: 20,
            ),
            filled: true,
            fillColor: context.cardSurfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
          ),
          onChanged: (val) {
            final n = int.tryParse(val);
            if (n != null && counts.contains(n)) {
              setState(() => _selectedCount = n);
            } else {
              setState(() => _selectedCount = -1); // Deselect presets
            }
          },
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
                    color: isSelected
                        ? Colors.white
                        : context.textSecondaryColor,
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
                borderRadius: BorderRadius.circular(28),
              ),
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
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
                subtitle: Text(
                  '${pack.subject} • ${pack.questions.length} Questions',
                  style: TextStyle(color: context.textSecondaryColor),
                ),
                trailing: Icon(
                  LucideIcons.chevronRight,
                  color: context.textSecondaryColor,
                ),
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
