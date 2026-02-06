/// Subject Stats - Per-subject performance metrics
class SubjectStats {
  final int viewed;
  final int correct;
  final int wrong;

  const SubjectStats({
    required this.viewed,
    required this.correct,
    required this.wrong,
  });

  factory SubjectStats.fromJson(Map<String, dynamic> json) {
    return SubjectStats(
      viewed: json['viewed'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      wrong: json['wrong'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'viewed': viewed,
        'correct': correct,
        'wrong': wrong,
      };

  double get accuracy => viewed > 0 ? (correct / viewed) * 100 : 0;
}

/// User Analytics - Overall performance metrics
class UserAnalytics {
  final int totalViewed;
  final int totalCorrect;
  final int totalWrong;
  final Map<String, SubjectStats> subjectWise;

  const UserAnalytics({
    required this.totalViewed,
    required this.totalCorrect,
    required this.totalWrong,
    required this.subjectWise,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    final subjectWiseRaw = json['subjectWise'] as Map? ?? {};
    final subjectWise = subjectWiseRaw.map(
      (key, value) => MapEntry(key.toString(),
          SubjectStats.fromJson(Map<String, dynamic>.from(value as Map))),
    );

    return UserAnalytics(
      totalViewed: json['totalViewed'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      totalWrong: json['totalWrong'] as int? ?? 0,
      subjectWise: subjectWise,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalViewed': totalViewed,
        'totalCorrect': totalCorrect,
        'totalWrong': totalWrong,
        'subjectWise':
            subjectWise.map((key, value) => MapEntry(key, value.toJson())),
      };

  double get overallAccuracy =>
      totalViewed > 0 ? (totalCorrect / totalViewed) * 100 : 0;
}

/// User Profile - Matches React Native types/index.ts
class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final List<String> viewedMcqIds;
  final List<String> bookmarkedMcqIds;
  final int streakDays;
  final int lastActive;
  final UserAnalytics? analytics;

  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    required this.viewedMcqIds,
    required this.bookmarkedMcqIds,
    required this.streakDays,
    required this.lastActive,
    this.analytics,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      viewedMcqIds:
          (json['viewedMcqIds'] as List<dynamic>?)?.cast<String>() ?? [],
      bookmarkedMcqIds:
          (json['bookmarkedMcqIds'] as List<dynamic>?)?.cast<String>() ?? [],
      streakDays: json['streakDays'] as int? ?? 0,
      lastActive:
          json['lastActive'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      analytics: json['analytics'] != null
          ? UserAnalytics.fromJson(
              Map<String, dynamic>.from(json['analytics'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'viewedMcqIds': viewedMcqIds,
        'bookmarkedMcqIds': bookmarkedMcqIds,
        'streakDays': streakDays,
        'lastActive': lastActive,
        'analytics': analytics?.toJson(),
      };

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    List<String>? viewedMcqIds,
    List<String>? bookmarkedMcqIds,
    int? streakDays,
    int? lastActive,
    UserAnalytics? analytics,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      viewedMcqIds: viewedMcqIds ?? this.viewedMcqIds,
      bookmarkedMcqIds: bookmarkedMcqIds ?? this.bookmarkedMcqIds,
      streakDays: streakDays ?? this.streakDays,
      lastActive: lastActive ?? this.lastActive,
      analytics: analytics ?? this.analytics,
    );
  }

  /// Create default profile for new user
  factory UserProfile.createDefault({
    required String uid,
    String? email,
    String? displayName,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? 'User',
      viewedMcqIds: [],
      bookmarkedMcqIds: [],
      streakDays: 0,
      lastActive: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
