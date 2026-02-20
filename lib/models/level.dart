class Level {
  final String id; //
  final String title; //
  final int order; //
  final String? description; //

  Level({
    required this.id,
    required this.title,
    required this.order,
    this.description,
  });

  // Creates a Level object from Supabase JSON
  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'].toString(),
      title: json['title'] as String,
      order: json['order'] as int,
      description: json['description'] as String?,
    );
  }

  // Converts a Level object back to JSON for Supabase inserts/updates
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'order': order,
      'description': description,
    };
  }
}