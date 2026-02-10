import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

/// AnalyticsScreen - Statistics display
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final analytics = profile?.analytics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardSurfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Performance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          label: 'Total Viewed',
                          value: '${analytics?.totalViewed ?? 0}',
                          color: context.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          label: 'Correct',
                          value: '${analytics?.totalCorrect ?? 0}',
                          color: context.successColor,
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          label: 'Wrong',
                          value: '${analytics?.totalWrong ?? 0}',
                          color: context.errorColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Accuracy bar
                  Row(
                    children: [
                      Text(
                        'Accuracy',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(analytics?.overallAccuracy ?? 0).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (analytics?.overallAccuracy ?? 0) / 100,
                      backgroundColor: context.borderColor,
                      valueColor: AlwaysStoppedAnimation(context.successColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Subject-wise breakdown
            Text(
              'Subject-wise Performance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 12),

            if (analytics?.subjectWise.isEmpty ?? true)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Text(
                  'No subject data yet.\nStart practicing to see analytics!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textSecondaryColor),
                ),
              )
            else
              ...analytics!.subjectWise.entries.map((entry) {
                final subject = entry.key;
                final stats = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardSurfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${stats.accuracy.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: stats.accuracy >= 70
                                  ? context.successColor
                                  : stats.accuracy >= 40
                                  ? context.warningColor
                                  : context.errorColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stats.accuracy / 100,
                          backgroundColor: context.borderColor,
                          valueColor: AlwaysStoppedAnimation(
                            stats.accuracy >= 70
                                ? context.successColor
                                : stats.accuracy >= 40
                                ? context.warningColor
                                : context.errorColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${stats.correct}/${stats.viewed} correct',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
        ),
      ],
    );
  }
}
