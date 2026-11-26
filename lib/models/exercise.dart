enum DifficultyLevel { easy, medium, hard }

class Exercise {
  final int? id;
  final int teacherId;
  final String title;
  final String description;
  final String instructions;
  final DifficultyLevel defaultDifficulty;
  final int estimatedDurationMinutes;
  final DateTime createdAt;
  final bool isActive;

  Exercise({
    this.id,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.instructions,
    this.defaultDifficulty = DifficultyLevel.medium,
    this.estimatedDurationMinutes = 30,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'default_difficulty': defaultDifficulty.index,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      teacherId: map['teacher_id'],
      title: map['title'],
      description: map['description'],
      instructions: map['instructions'],
      defaultDifficulty: DifficultyLevel.values[map['default_difficulty']],
      estimatedDurationMinutes: map['estimated_duration_minutes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      isActive: map['is_active'] == 1,
    );
  }

  Exercise copyWith({
    int? id,
    int? teacherId,
    String? title,
    String? description,
    String? instructions,
    DifficultyLevel? defaultDifficulty,
    int? estimatedDurationMinutes,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Exercise(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}