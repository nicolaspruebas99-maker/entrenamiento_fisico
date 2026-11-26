import 'exercise.dart';

class StudentExercise {
  final int? id;
  final int studentId;
  final int exerciseId;
  final int teacherId;
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DifficultyLevel? difficultyFelt; // Lo que sintió el alumno
  final int? rating; // Nota 1-10 visible para ambos
  final String? studentNotes; // Comentarios del alumno
  final String? teacherPrivateNotes; // Anotaciones privadas del profesor
  final ExerciseStatus status;

  StudentExercise({
    this.id,
    required this.studentId,
    required this.exerciseId,
    required this.teacherId,
    DateTime? assignedAt,
    this.startedAt,
    this.completedAt,
    this.difficultyFelt,
    this.rating,
    this.studentNotes,
    this.teacherPrivateNotes,
    this.status = ExerciseStatus.assigned,
  }) : assignedAt = assignedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'exercise_id': exerciseId,
      'teacher_id': teacherId,
      'assigned_at': assignedAt.millisecondsSinceEpoch,
      'started_at': startedAt?.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'difficulty_felt': difficultyFelt?.index,
      'rating': rating,
      'student_notes': studentNotes,
      'teacher_private_notes': teacherPrivateNotes,
      'status': status.index,
    };
  }

  factory StudentExercise.fromMap(Map<String, dynamic> map) {
    return StudentExercise(
      id: map['id'],
      studentId: map['student_id'],
      exerciseId: map['exercise_id'],
      teacherId: map['teacher_id'],
      assignedAt: DateTime.fromMillisecondsSinceEpoch(map['assigned_at']),
      startedAt: map['started_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['started_at'])
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
          : null,
      difficultyFelt: map['difficulty_felt'] != null
          ? DifficultyLevel.values[map['difficulty_felt']]
          : null,
      rating: map['rating'],
      studentNotes: map['student_notes'],
      teacherPrivateNotes: map['teacher_private_notes'],
      status: ExerciseStatus.values[map['status']],
    );
  }

  StudentExercise copyWith({
    int? id,
    int? studentId,
    int? exerciseId,
    int? teacherId,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DifficultyLevel? difficultyFelt,
    int? rating,
    String? studentNotes,
    String? teacherPrivateNotes,
    ExerciseStatus? status,
  }) {
    return StudentExercise(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      exerciseId: exerciseId ?? this.exerciseId,
      teacherId: teacherId ?? this.teacherId,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      difficultyFelt: difficultyFelt ?? this.difficultyFelt,
      rating: rating ?? this.rating,
      studentNotes: studentNotes ?? this.studentNotes,
      teacherPrivateNotes: teacherPrivateNotes ?? this.teacherPrivateNotes,
      status: status ?? this.status,
    );
  }
}

enum ExerciseStatus { assigned, inProgress, completed, skipped }