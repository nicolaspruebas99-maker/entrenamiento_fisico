import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/exercise.dart';
import '../../models/student_exercise.dart';
import '../../utils/helpers.dart';

class StudentExerciseDetail extends StatefulWidget {
  final StudentExercise studentExercise;

  const StudentExerciseDetail({super.key, required this.studentExercise});

  @override
  State<StudentExerciseDetail> createState() => _StudentExerciseDetailState();
}

class _StudentExerciseDetailState extends State<StudentExerciseDetail> {
  late StudentExercise _se;
  Exercise? _exercise;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _se = widget.studentExercise;
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    final provider = context.read<AppProvider>();
    final exercise = await provider.getExerciseById(_se.exerciseId);
    if (mounted) {
      setState(() {
        _exercise = exercise;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ejercicio')),
        body: const Center(child: Text('Ejercicio no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise!.title),
        actions: [
          if (_se.status == ExerciseStatus.completed)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _showRestartDialog(context),
              tooltip: 'Reiniciar',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Card(
              color: exerciseStatusColor(_se.status).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: exerciseStatusColor(_se.status).withOpacity(0.2),
                      child: Icon(exerciseStatusIcon(_se.status), color: exerciseStatusColor(_se.status)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_exercise!.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Estado: ${exerciseStatusLabel(_se.status)}', style: TextStyle(color: exerciseStatusColor(_se.status), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    buildStatusChip(_se.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info del ejercicio
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(difficultyIcon(_exercise!.defaultDifficulty), color: difficultyColor(_exercise!.defaultDifficulty)),
                        const SizedBox(width: 8),
                        Text('Dificultad base: ', style: Theme.of(context).textTheme.titleMedium),
                        buildDifficultyChip(_exercise!.defaultDifficulty),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Duración estimada: ${_exercise!.estimatedDurationMinutes} minutos'),
                    const SizedBox(height: 16),
                    Text('Descripción', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(_exercise!.description),
                    const SizedBox(height: 16),
                    Text('Instrucciones', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(_exercise!.instructions),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Acciones según estado
            _buildActions(),
            const SizedBox(height: 24),

            // Resultados (si completado)
            if (_se.status == ExerciseStatus.completed) ...[
              Text('Tu resultado', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildResults(),
              const SizedBox(height: 24),
            ],

            // Nota del profesor (si existe y está completado)
            if (_se.status == ExerciseStatus.completed && _se.teacherPrivateNotes != null && _se.teacherPrivateNotes!.isNotEmpty) ...[
              Card(
                color: Colors.blue.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text('Comentario del profesor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_se.teacherPrivateNotes!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    switch (_se.status) {
      case ExerciseStatus.assigned:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => _startExercise(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Comenzar ejercicio'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _skipExercise(),
              icon: const Icon(Icons.skip_next),
              label: const Text('Omitir (no lo haré)'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        );

      case ExerciseStatus.inProgress:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showCompleteDialog(),
              icon: const Icon(Icons.check),
              label: const Text('Finalizar y evaluar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _skipExercise(),
              icon: const Icon(Icons.skip_next),
              label: const Text('Omitir'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        );

      case ExerciseStatus.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showRestartDialog(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a hacer'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        );

      case ExerciseStatus.skipped:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => _restartExercise(),
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar ahora'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_se.rating != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tu nota: ', style: Theme.of(context).textTheme.titleMedium),
                  Text('${_se.rating}/10', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 8),
              buildRatingStars(_se.rating!, size: 32),
              const SizedBox(height: 16),
            ],
            if (_se.difficultyFelt != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Dificultad sentida: ', style: Theme.of(context).textTheme.titleMedium),
                  buildDifficultyChip(_se.difficultyFelt!),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_se.studentNotes != null && _se.studentNotes!.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text('Tus notas:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_se.studentNotes!),
            ],
            if (_se.completedAt != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text('Completado: ${formatDateTime(_se.completedAt!)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startExercise() async {
    final provider = context.read<AppProvider>();
    final success = await provider.startExercise(_se.id!);
    if (mounted) {
      if (success) {
        setState(() {
          _se = _se.copyWith(status: ExerciseStatus.inProgress, startedAt: DateTime.now());
        });
        showSnackBar(context, '¡Ejercicio iniciado! ¡Buena suerte!');
      } else {
        showSnackBar(context, 'Error al iniciar', isError: true);
      }
    }
  }

  void _showCompleteDialog() {
    DifficultyLevel? selectedDifficulty;
    int rating = 5;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Finalizar ejercicio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('¿Cómo te sentiste?', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                // Dificultad
                Text('Dificultad sentida'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: DifficultyLevel.values.map((d) {
                    final isSelected = selectedDifficulty == d;
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(difficultyIcon(d), color: difficultyColor(d), size: 18),
                          const SizedBox(width: 4),
                          Text(difficultyLabel(d)),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: difficultyColor(d).withOpacity(0.2),
                      checkmarkColor: difficultyColor(d),
                      onSelected: (_) => setState(() => selectedDifficulty = d),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Nota
                Text('Tu nota (1-10)'),
                const SizedBox(height: 8),
                Slider(
                  value: rating.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: rating.toString(),
                  onChanged: (v) => setState(() => rating = v.round()),
                ),
                buildRatingStars(rating, size: 28),
                const SizedBox(height: 16),
                // Notas
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Tus notas (opcional)',
                    hintText: '¿Qué tal te fue? ¿Qué mejorarías?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: selectedDifficulty == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _completeExercise(selectedDifficulty!, rating, notesController.text.trim());
                    },
              child: const Text('Guardar resultado'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeExercise(DifficultyLevel difficulty, int rating, String notes) async {
    final provider = context.read<AppProvider>();
    final success = await provider.completeExercise(
      studentExerciseId: _se.id!,
      difficultyFelt: difficulty,
      rating: rating,
      studentNotes: notes.isEmpty ? null : notes,
    );
    if (mounted) {
      if (success) {
        setState(() {
          _se = _se.copyWith(
            status: ExerciseStatus.completed,
            completedAt: DateTime.now(),
            difficultyFelt: difficulty,
            rating: rating,
            studentNotes: notes.isEmpty ? null : notes,
          );
        });
        showSnackBar(context, '¡Ejercicio completado! Resultado guardado.');
      } else {
        showSnackBar(context, 'Error al guardar', isError: true);
      }
    }
  }

  Future<void> _skipExercise() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Omitir ejercicio',
      content: '¿Seguro que quieres omitir este ejercicio?',
      confirmText: 'Omitir',
      isDestructive: true,
    );
    if (confirm == true) {
      final provider = context.read<AppProvider>();
      final success = await provider.skipExercise(_se.id!);
      if (mounted) {
        if (success) {
          setState(() => _se = _se.copyWith(status: ExerciseStatus.skipped));
          showSnackBar(context, 'Ejercicio omitido');
        } else {
          showSnackBar(context, 'Error', isError: true);
        }
      }
    }
  }

  void _showRestartDialog(BuildContext context) {
    showConfirmDialog(
      context,
      title: 'Reiniciar ejercicio',
      content: '¿Quieres volver a hacer este ejercicio? Se borrará tu resultado anterior.',
      confirmText: 'Reiniciar',
      isDestructive: true,
      onConfirm: _restartExercise,
    );
  }

  Future<void> _restartExercise() async {
    final provider = context.read<AppProvider>();
    // Resetear a asignado
    final updated = _se.copyWith(
      status: ExerciseStatus.assigned,
      startedAt: null,
      completedAt: null,
      difficultyFelt: null,
      rating: null,
      studentNotes: null,
    );
    final success = await provider.updateStudentExercise(updated);
    if (mounted) {
      if (success) {
        setState(() => _se = updated);
        showSnackBar(context, 'Ejercicio reiniciado');
      } else {
        showSnackBar(context, 'Error', isError: true);
      }
    }
  }
}