class Question {
  final String id;
  final String levelId;
  final String? skillAreaId;
  final String questionText;
  final String correctAnswer;
  final List<String> answerOptions;
  final String? explanation;
  final String? imageUrl; // <-- ADDED THIS FOR YOUR PDF FIGURES

  Question({
    required this.id,
    required this.levelId,
    this.skillAreaId,
    required this.questionText,
    required this.correctAnswer,
    required this.answerOptions,
    this.explanation,
    this.imageUrl, // <-- ADDED THIS
  });

  // Creates a Question object from Supabase JSON
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'].toString(),
      levelId: json['level_id'].toString(),
      skillAreaId: json['skill_area_id']?.toString(),
      questionText: json['question_text'] as String,
      correctAnswer: json['correct_answer'] as String,
      // Supabase returns arrays as List<dynamic>, so we cast to List<String>
      answerOptions: List<String>.from(json['answer_options'] ?? []),
      explanation: json['explanation'] as String?,
      imageUrl: json['image_url'] as String?, // <-- ADDED THIS
    );
  }

  // Converts a Question object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level_id': levelId,
      'skill_area_id': skillAreaId,
      'question_text': questionText,
      'correct_answer': correctAnswer,
      'answer_options': answerOptions,
      'explanation': explanation,
      'image_url': imageUrl, // <-- ADDED THIS
    };
  }
}