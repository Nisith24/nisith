import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../bookmarks/providers/bookmark_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Reactive provider for viewed MCQ IDs from local storage (Hive)
final viewedIdsProvider = StreamProvider<List<String>>((ref) async* {
  // Box is guaranteed opened in main.dart via LocalStorageService.init()
  final box = Hive.box<List<String>>('neetflow_progress');

  // Yield initial value
  yield box.get('viewed_mcq_ids') ?? [];

  // Yield new values whenever the key changes in Hive
  await for (final event in box.watch(key: 'viewed_mcq_ids')) {
    yield (event.value as List<dynamic>?)?.cast<String>() ?? [];
  }
});

/// Reactive provider for bookmarked MCQ count (already local-first)
final localBookmarkedCountProvider = Provider<int>((ref) {
  return ref.watch(bookmarkStateProvider).length;
});

/// Combined user stats provider for local-first UI
final localUserStatsProvider = Provider<UserStats>((ref) {
  final viewedIds = ref.watch(viewedIdsProvider).valueOrNull ?? [];
  final bookmarkCount = ref.watch(localBookmarkedCountProvider);
  final profile = ref.watch(userProfileProvider);

  return UserStats(
    viewedCount: viewedIds.length,
    bookmarkCount: bookmarkCount,
    streakDays: profile?.streakDays ?? 0,
  );
});

class UserStats {
  final int viewedCount;
  final int bookmarkCount;
  final int streakDays;

  UserStats({
    required this.viewedCount,
    required this.bookmarkCount,
    required this.streakDays,
  });
}
