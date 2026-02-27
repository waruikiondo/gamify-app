class UserLevelProgress {
  final String userId;
  final String levelId;
  final bool unlocked;
  final bool completed;
  final double highestScorePercentage;

  UserLevelProgress({
    required this.userId,
    required this.levelId,
    required this.unlocked,
    required this.completed,
    required this.highestScorePercentage,
  });

  factory UserLevelProgress.fromJson(Map<String, dynamic> json) {
    return UserLevelProgress(
      userId: json['user_id'].toString(),
      levelId: json['level_id'].toString(),
      unlocked: json['unlocked'] as bool? ?? false, 
      completed: json['completed'] as bool? ?? false,
      highestScorePercentage: (json['highest_score_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'level_id': levelId,
      'unlocked': unlocked,
      'completed': completed,
      'highest_score_percentage': highestScorePercentage,
    };
  }
}