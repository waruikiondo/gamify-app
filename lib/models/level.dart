class Level {
  final String id;
  final String title;
  final String? description;
  final int levelOrder;
  final int passingPercentage;

  Level({
    required this.id,
    required this.title,
    this.description,
    required this.levelOrder,
    required this.passingPercentage,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String?,
      levelOrder: json['level_order'] as int,
      passingPercentage: json['passing_percentage'] as int? ?? 80,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'level_order': levelOrder,
      'passing_percentage': passingPercentage,
    };
  }
}