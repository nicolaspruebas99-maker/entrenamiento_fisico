import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/exercise.dart';
import '../../models/student_exercise.dart';
import '../../models/user.dart';
import '../../utils/helpers.dart';

class TeacherExerciseDetail extends StatefulWidget {
  final Exercise exercise;

  const TeacherExerciseDetail({super.key, required this.exercise});

  @override
  State<TeacherExerciseDetail> createState() => _TeacherExerciseDetailState();
}

class _TeacherExerciseDetailState extends State<TeacherExerciseDetail> {
  late List<StudentExercise> _assignments;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  void _loadAssignments() {
    final provider = context.read<AppProvider>();
    _assignments = provider.studentExercises
        .where((se) => se.exerciseId == widget.exercise.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        _assignments = provider.studentExercises
            .where((se) => se.exerciseId == widget.exercise.id)
            .toList();

        final completed = _assignments.where((se) => se.status == ExerciseStatus.completed).length;
        final inProgress = _assignments.where((se) => se.status == ExerciseStatus.inProgress).length;
        final pending = _assignments.where((se) => se.status == ExerciseStatus.assigned).length;
        final skipped = _assignments.where((se) => se.status == ExerciseStatus.skipped).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.exercise.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context, provider),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info del ejercicio
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: difficultyColor(widget.exercise.defaultDifficulty).withOpacity(0.2),
                              child: Icon(difficultyIcon(widget.exercise.defaultDifficulty), color: difficultyColor(widget.exercise.defaultDifficulty)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.exercise.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  Text('Duración estimada: ${widget.exercise.estimatedDurationMinutes} min', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            buildDifficultyChip(widget.exercise.defaultDifficulty),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Descripción', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(widget.exercise.description),
                        const SizedBox(height: 16),
                        Text('Instrucciones', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(widget.exercise.instructions),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Estadísticas
                Text('Estadísticas', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatItem(label: 'Asignados', value: _assignments.length.toString(), color: Colors.blue)),
                    Expanded(child: _StatItem(label: 'En progreso', value: inProgress.toString(), color: Colors.orange)),
                    Expanded(child: _StatItem(label: 'Completados', value: completed.toString(), color: Colors.green)),
                    Expanded(child: _StatItem(label: 'Omitidos', value: skipped.toString(), color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 24),

                // Lista de alumnos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Alumnos asignados', style: Theme.of(context).textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: () => _showAssignDialog(context, provider),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Asignar más'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_assignments.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('No hay alumnos asignados a este ejercicio'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAssignDialog(context, provider),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Asignar alumnos'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _assignments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final se = _assignments[index];
                      final student = provider.students.firstWhere(
                        (s) => s.id == se.studentId,
                        orElse: () => User(id: se.studentId, username: 'desconocido', passwordHash: '', fullName: 'Desconocido', role: UserRole.student),
                      );
                      return _AssignmentTile(se: se, student: student, provider: provider);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, AppProvider provider) {
    final titleController = TextEditingController(text: widget.exercise.title);
    final descriptionController = TextEditingController(text: widget.exercise.description);
    final instructionsController = TextEditingController(text: widget.exercise.instructions);
    DifficultyLevel selectedDifficulty = widget.exercise.defaultDifficulty;
    int duration = widget.exercise.estimatedDurationMinutes;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar ejercicio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'Título *')),
                const SizedBox(height: 12),
                TextFormField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
                const SizedBox(height: 12),
                TextFormField(controller: instructionsController, decoration: const InputDecoration(labelText: 'Instrucciones *'), maxLines: 3),
                const SizedBox(height: 16),
                DropdownButtonFormField<DifficultyLevel>(
                  value: selectedDifficulty,
                  decoration: const InputDecoration(labelText: 'Dificultad por defecto'),
                  items: DifficultyLevel.values.map((d) => DropdownMenuItem(value: d, child: Row(children: [Icon(difficultyIcon(d), color: difficultyColor(d), size: 20), const SizedBox(width: 8), Text(difficultyLabel(d))]))).toList(),
                  onChanged: (v) => setState(() => selectedDifficulty = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(initialValue: duration.toString(), decoration: const InputDecoration(labelText: 'Duración estimada (min)'), keyboardType: TextInputType.number, onChanged: (v) => duration = int.tryParse(v) ?? 30),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (titleController.text.trim().isEmpty || instructionsController.text.trim().isEmpty) {
                  showSnackBar(context, 'Título e instrucciones son obligatorios', isError: true);
                  return;
                }
                setState(() => isLoading = true);
                final updated = Exercise(
                  id: widget.exercise.id,
                  teacherId: widget.exercise.teacherId,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  instructions: instructionsController.text.trim(),
                  defaultDifficulty: selectedDifficulty,
                  estimatedDurationMinutes: duration,
                  createdAt: widget.exercise.createdAt,
                  isActive: widget.exercise.isActive,
                );
                await provider.updateExercise(updated);
                if (context.mounted) {
                  setState(() => isLoading = false);
                  Navigator.pop(context);
                  showSnackBar(context, 'Ejercicio actualizado');
                }
              },
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, AppProvider provider) {
    final students = provider.students;
    final assignedStudentIds = _assignments.map((se) => se.studentId).toSet();
    final selectedIds = <int>{};

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Asignar "${widget.exercise.title}"'),
          content: SizedBox(
            width: double.maxFinite,
            child: students.isEmpty
                ? const Text('No hay alumnos registrados')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final isAssigned = assignedStudentIds.contains(student.id);
                      return CheckboxListTile(
                        title: Text(student.fullName),
                        subtitle: Text('@${student.username}'),
                        value: isAssigned || selectedIds.contains(student.id),
                        onChanged: isAssigned ? null : (v) {
                          setState(() {
                            if (v == true) selectedIds.add(student.id!);
                            else selectedIds.remove(student.id);
                          });
                        },
                        secondary: isAssigned ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: selectedIds.isEmpty ? null : () async {
                await provider.assignExerciseToStudents(widget.exercise.id!, selectedIds.toList());
                if (context.mounted) {
                  Navigator.pop(context);
                  showSnackBar(context, 'Ejercicio asignado a ${selectedIds.length} alumno(s)');
                }
              },
              child: const Text('Asignar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final StudentExercise se;
  final User student;
  final AppProvider provider;

  const _AssignmentTile({required this.se, required this.student, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getStatusColor(se.status).withOpacity(0.1),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(se.status).withOpacity(0.2),
          child: Icon(exerciseStatusIcon(se.status), color: _getStatusColor(se.status)),
        ),
        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('@${student.username}'),
        trailing: buildStatusChip(se.status),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow('Estado', exerciseStatusLabel(se.status)),
                if (se.assignedAt != null) _DetailRow('Asignado', formatDateTime(se.assignedAt!)),
                if (se.startedAt != null) _DetailRow('Iniciado', formatDateTime(se.startedAt!)),
                if (se.completedAt != null) _DetailRow('Completado', formatDateTime(se.completedAt!)),
                if (se.difficultyFelt != null) _DetailRow('Dificultad sentida', difficultyLabel(se.difficultyFelt!)),
                if (se.rating != null) ...[
                  const SizedBox(height: 8),
                  _DetailRow('Nota', '${se.rating}/10'),
                  buildRatingStars(se.rating!),
                ],
                if (se.studentNotes != null && se.studentNotes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Notas del alumno:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(se.studentNotes!),
                ],
                const SizedBox(height: 16),
                const Text('Tu nota privada:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                TextFormField(
                  initialValue: se.teacherPrivateNotes,
                  decoration: const InputDecoration(
                    hintText: 'Escribe anotaciones privadas (solo tú las ves)...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onFieldSubmitted: (value) => _savePrivateNote(value),
                ),
                const SizedBox(height: 8),
                if (se.teacherPrivateNotes != null && se.teacherPrivateNotes!.isNotEmpty)
                  Text('Guardado automáticamente', style: TextStyle(fontSize: 12, color: Colors.green[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ExerciseStatus status) {
    return exerciseStatusColor(status);
  }

  void _savePrivateNote(String note) async {
    await provider.updateTeacherPrivateNotes(se.id!, note.trim());
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}