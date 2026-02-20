class UserProgress {
  final String userId; //
  final String levelId; //
  final bool unlocked; //
  final bool completed; //

  UserProgress({
    required this.userId,
    required this.levelId,
    required this.unlocked,
    required this.completed,
  });

  // Creates a UserProgress object from Supabase JSON
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['user_id'].toString(),
      levelId: json['level_id'].toString(),
      unlocked: json['unlocked'] as bool? ?? false, 
      completed: json['completed'] as bool? ?? false,
    );
  }

  // Converts a UserProgress object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'level_id': levelId,
      'unlocked': unlocked,
      'completed': completed,
    };
  }
}