import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/exercise.dart';
import '../../models/student_exercise.dart';
import '../../utils/helpers.dart';
import 'teacher_exercise_detail.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyActive = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        var filteredExercises = provider.exercises.where((e) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch = e.title.toLowerCase().contains(query) ||
              e.description.toLowerCase().contains(query);
          final matchesActive = !_showOnlyActive || e.isActive;
          return matchesSearch && matchesActive;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis Ejercicios'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar ejercicio...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilterChip(
                          label: const Text('Solo activos'),
                          selected: _showOnlyActive,
                          onSelected: (v) => setState(() => _showOnlyActive = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.refreshExercises(),
            child: filteredExercises.isEmpty
                ? _buildEmptyState(context, provider)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      return _ExerciseCard(exercise: exercise, provider: provider);
                    },
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddExerciseDialog(context, provider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No hay ejercicios creados' : 'No se encontraron ejercicios',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Crea tu primer entrenamiento'
                  : 'Intenta con otro término de búsqueda',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddExerciseDialog(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('Crear ejercicio'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, AppProvider provider) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final instructionsController = TextEditingController();
    DifficultyLevel selectedDifficulty = DifficultyLevel.medium;
    int duration = 30;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo ejercicio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: instructionsController,
                  decoration: const InputDecoration(labelText: 'Instrucciones *'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DifficultyLevel>(
                  value: selectedDifficulty,
                  decoration: const InputDecoration(labelText: 'Dificultad por defecto'),
                  items: DifficultyLevel.values.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Row(
                        children: [
                          Icon(difficultyIcon(d), color: difficultyColor(d), size: 20),
                          const SizedBox(width: 8),
                          Text(difficultyLabel(d)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedDifficulty = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: duration.toString(),
                  decoration: const InputDecoration(labelText: 'Duración estimada (min)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => duration = int.tryParse(v) ?? 30,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty ||
                          instructionsController.text.trim().isEmpty) {
                        showSnackBar(context, 'Título e instrucciones son obligatorios', isError: true);
                        return;
                      }
                      setState(() => isLoading = true);
                      await provider.createExercise(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        instructions: instructionsController.text.trim(),
                        defaultDifficulty: selectedDifficulty,
                        estimatedDurationMinutes: duration,
                      );
                      if (context.mounted) {
                        setState(() => isLoading = false);
                        Navigator.pop(context);
                        showSnackBar(context, 'Ejercicio creado');
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final AppProvider provider;

  const _ExerciseCard({required this.exercise, required this.provider});

  @override
  Widget build(BuildContext context) {
    // Contar asignaciones
    final assignments = provider.studentExercises
        .where((se) => se.exerciseId == exercise.id)
        .toList();
    final completed = assignments.where((se) => se.status == ExerciseStatus.completed).length;

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TeacherExerciseDetail(exercise: exercise)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: difficultyColor(exercise.defaultDifficulty).withOpacity(0.2),
                    child: Icon(difficultyIcon(exercise.defaultDifficulty), color: difficultyColor(exercise.defaultDifficulty)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${exercise.estimatedDurationMinutes} min · ${assignments.length} asignados · $completed completados',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  buildDifficultyChip(exercise.defaultDifficulty),
                ],
              ),
              const SizedBox(height: 8),
              Text(exercise.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAssignDialog(context),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Asignar'),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Editar')])),
                      PopupMenuItem(
                        value: exercise.isActive ? 'deactivate' : 'activate',
                        child: Row(children: [
                          Icon(exercise.isActive ? Icons.visibility_off : Icons.visibility, size: 20),
                          const SizedBox(width: 8),
                          Text(exercise.isActive ? 'Desactivar' : 'Activar'),
                        ]),
                      ),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    if (action == 'edit') {
      _showEditDialog(context);
    } else if (action == 'deactivate' || action == 'activate') {
      _toggleActive(context);
    } else if (action == 'delete') {
      _confirmDelete(context);
    }
  }

  void _showAssignDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    final students = provider.students;
    final assignedStudentIds = provider.studentExercises
        .where((se) => se.exerciseId == exercise.id)
        .map((se) => se.studentId)
        .toSet();

    final selectedIds = <int>{};

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Asignar "${exercise.title}"'),
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
                        onChanged: isAssigned
                            ? null
                            : (v) {
                                setState(() {
                                  if (v == true) {
                                    selectedIds.add(student.id!);
                                  } else {
                                    selectedIds.remove(student.id);
                                  }
                                });
                              },
                        secondary: isAssigned
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: selectedIds.isEmpty
                  ? null
                  : () async {
                      await provider.assignExerciseToStudents(exercise.id!, selectedIds.toList());
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

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: exercise.title);
    final descriptionController = TextEditingController(text: exercise.description);
    final instructionsController = TextEditingController(text: exercise.instructions);
    DifficultyLevel selectedDifficulty = exercise.defaultDifficulty;
    int duration = exercise.estimatedDurationMinutes;
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
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: instructionsController,
                  decoration: const InputDecoration(labelText: 'Instrucciones *'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DifficultyLevel>(
                  value: selectedDifficulty,
                  decoration: const InputDecoration(labelText: 'Dificultad por defecto'),
                  items: DifficultyLevel.values.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Row(
                        children: [
                          Icon(difficultyIcon(d), color: difficultyColor(d), size: 20),
                          const SizedBox(width: 8),
                          Text(difficultyLabel(d)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedDifficulty = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: duration.toString(),
                  decoration: const InputDecoration(labelText: 'Duración estimada (min)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => duration = int.tryParse(v) ?? 30,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty ||
                          instructionsController.text.trim().isEmpty) {
                        showSnackBar(context, 'Título e instrucciones son obligatorios', isError: true);
                        return;
                      }
                      setState(() => isLoading = true);
                      final updated = Exercise(
                        id: exercise.id,
                        teacherId: exercise.teacherId,
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        instructions: instructionsController.text.trim(),
                        defaultDifficulty: selectedDifficulty,
                        estimatedDurationMinutes: duration,
                        createdAt: exercise.createdAt,
                        isActive: exercise.isActive,
                      );
                      await provider.updateExercise(updated);
                      if (context.mounted) {
                        setState(() => isLoading = false);
                        Navigator.pop(context);
                        showSnackBar(context, 'Ejercicio actualizado');
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleActive(BuildContext context) async {
    final updated = Exercise(
      id: exercise.id,
      teacherId: exercise.teacherId,
      title: exercise.title,
      description: exercise.description,
      instructions: exercise.instructions,
      defaultDifficulty: exercise.defaultDifficulty,
      estimatedDurationMinutes: exercise.estimatedDurationMinutes,
      createdAt: exercise.createdAt,
      isActive: !exercise.isActive,
    );
    await provider.updateExercise(updated);
    if (context.mounted) {
      showSnackBar(context, exercise.isActive ? 'Ejercicio desactivado' : 'Ejercicio activado');
    }
  }

  void _confirmDelete(BuildContext context) {
    showConfirmDialog(
      context,
      title: 'Eliminar ejercicio',
      content: '¿Eliminar "${exercise.title}"? Se borrarán todas sus asignaciones.',
      confirmText: 'Eliminar',
      isDestructive: true,
      onConfirm: () async {
        await provider.deleteExercise(exercise.id!);
        if (context.mounted) {
          showSnackBar(context, 'Ejercicio eliminado');
        }
      },
    );
  }
}