import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../models/student_exercise.dart';

String difficultyLabel(DifficultyLevel level) {
  switch (level) {
    case DifficultyLevel.easy:
      return 'Fácil';
    case DifficultyLevel.medium:
      return 'Medio';
    case DifficultyLevel.hard:
      return 'Difícil';
  }
}

Color difficultyColor(DifficultyLevel level) {
  switch (level) {
    case DifficultyLevel.easy:
      return Colors.green;
    case DifficultyLevel.medium:
      return Colors.orange;
    case DifficultyLevel.hard:
      return Colors.red;
  }
}

IconData difficultyIcon(DifficultyLevel level) {
  switch (level) {
    case DifficultyLevel.easy:
      return Icons.sentiment_very_satisfied;
    case DifficultyLevel.medium:
      return Icons.sentiment_neutral;
    case DifficultyLevel.hard:
      return Icons.sentiment_very_dissatisfied;
  }
}

String exerciseStatusLabel(ExerciseStatus status) {
  switch (status) {
    case ExerciseStatus.assigned:
      return 'Asignado';
    case ExerciseStatus.inProgress:
      return 'En progreso';
    case ExerciseStatus.completed:
      return 'Completado';
    case ExerciseStatus.skipped:
      return 'Omitido';
  }
}

Color exerciseStatusColor(ExerciseStatus status) {
  switch (status) {
    case ExerciseStatus.assigned:
      return Colors.blue;
    case ExerciseStatus.inProgress:
      return Colors.orange;
    case ExerciseStatus.completed:
      return Colors.green;
    case ExerciseStatus.skipped:
      return Colors.grey;
  }
}

IconData exerciseStatusIcon(ExerciseStatus status) {
  switch (status) {
    case ExerciseStatus.assigned:
      return Icons.assignment;
    case ExerciseStatus.inProgress:
      return Icons.directions_run;
    case ExerciseStatus.completed:
      return Icons.check_circle;
    case ExerciseStatus.skipped:
      return Icons.skip_next;
  }
}

String formatDateTime(DateTime dt) {
  return DateFormat('dd/MM/yyyy HH:mm').format(dt);
}

String formatDate(DateTime dt) {
  return DateFormat('dd/MM/yyyy').format(dt);
}

String formatTime(DateTime dt) {
  return DateFormat('HH:mm').format(dt);
}

Widget buildDifficultyChip(DifficultyLevel level, {double? fontSize}) {
  return Chip(
    label: Text(
      difficultyLabel(level),
      style: TextStyle(fontSize: fontSize ?? 12, color: Colors.white),
    ),
    backgroundColor: difficultyColor(level),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

Widget buildStatusChip(ExerciseStatus status, {double? fontSize}) {
  return Chip(
    label: Text(
      exerciseStatusLabel(status),
      style: TextStyle(fontSize: fontSize ?? 12, color: Colors.white),
    ),
    backgroundColor: exerciseStatusColor(status),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

Widget buildRatingStars(int rating, {double size = 20}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      return Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: size,
      );
    }),
  );
}

void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
  bool isDestructive = false,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
            onConfirm?.call();
          },
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result;
}