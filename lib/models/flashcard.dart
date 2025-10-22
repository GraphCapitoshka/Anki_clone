class Flashcard {
  int? id;
  int deckId;
  String question;
  String answer;
  DateTime nextReview;
  int interval;
  double ease;
  int correctStreak;

  Flashcard({
    this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    DateTime? nextReview,
    int? interval,
    double? ease,
    int? correctStreak,
  })  : nextReview = nextReview ?? DateTime.now(),
        interval = interval ?? 1,
        ease = ease ?? 2.5,
        correctStreak = correctStreak ?? 0;

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as int?,
      deckId: map['deck_id'] as int,
      question: map['question'] as String,
      answer: map['answer'] as String,
      nextReview: map['next_review'] != null
          ? DateTime.parse(map['next_review'] as String)
          : DateTime.now(),
      interval: map['interval'] != null ? map['interval'] as int : 1,
      ease: map['ease'] != null ? map['ease'] as double : 2.5,
      correctStreak:
      map['correct_streak'] != null ? map['correct_streak'] as int : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'question': question,
      'answer': answer,
      'next_review': nextReview.toIso8601String(),
      'interval': interval,
      'ease': ease,
      'correct_streak': correctStreak,
    };
  }
}
