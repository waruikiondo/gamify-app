class Level {
  final String id;
  final String title;
  final String? description;
  final int levelOrder;
  final int passingPercentage;
  final String? contentMarkdown; // <-- NEW FIELD

  Level({
    required this.id,
    required this.title,
    this.description,
    required this.levelOrder,
    required this.passingPercentage,
    this.contentMarkdown, // <-- ADD TO CONSTRUCTOR
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String?,
      levelOrder: json['level_order'] as int,
      passingPercentage: json['passing_percentage'] as int? ?? 80,
      contentMarkdown: json['content_markdown'] as String?, // <-- PARSE IT
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'level_order': levelOrder,
      'passing_percentage': passingPercentage,
      'content_markdown': contentMarkdown, // <-- EXPORT IT
    };
  }
}