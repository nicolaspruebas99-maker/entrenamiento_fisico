import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/user.dart';
import '../../models/student_exercise.dart';
import '../../utils/helpers.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final filteredStudents = provider.students.where((s) {
          final query = _searchQuery.toLowerCase();
          return s.fullName.toLowerCase().contains(query) ||
              s.username.toLowerCase().contains(query);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis Alumnos'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar alumno...',
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
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.refreshStudents(),
            child: filteredStudents.isEmpty
                ? _buildEmptyState(context, provider)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredStudents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return _StudentCard(student: student, provider: provider);
                    },
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddStudentDialog(context, provider),
            child: const Icon(Icons.person_add),
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
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No hay alumnos registrados' : 'No se encontraron alumnos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Añade tu primer estudiante para empezar'
                  : 'Intenta con otro término de búsqueda',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddStudentDialog(context, provider),
                icon: const Icon(Icons.person_add),
                label: const Text('Añadir alumno'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, AppProvider provider) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo alumno'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre completo *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Usuario *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña *'),
                  obscureText: true,
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
                      if (nameController.text.trim().isEmpty ||
                          usernameController.text.trim().isEmpty ||
                          passwordController.text.isEmpty) {
                        showSnackBar(context, 'Todos los campos son obligatorios', isError: true);
                        return;
                      }
                      setState(() => isLoading = true);
                      final user = await provider.registerStudent(
                        username: usernameController.text.trim(),
                        password: passwordController.text,
                        fullName: nameController.text.trim(),
                      );
                      if (context.mounted) {
                        setState(() => isLoading = false);
                        if (user != null) {
                          Navigator.pop(context);
                          showSnackBar(context, 'Alumno creado correctamente');
                        } else {
                          showSnackBar(context, 'El usuario ya existe', isError: true);
                        }
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

class _StudentCard extends StatelessWidget {
  final User student;
  final AppProvider provider;

  const _StudentCard({required this.student, required this.provider});

  @override
  Widget build(BuildContext context) {
    // Obtener ejercicios de este alumno
    final studentExercises = provider.studentExercises
        .where((se) => se.studentId == student.id)
        .toList();
    
    final completed = studentExercises.where((se) => se.status == ExerciseStatus.completed).length;
    final inProgress = studentExercises.where((se) => se.status == ExerciseStatus.inProgress).length;
    final pending = studentExercises.where((se) => se.status == ExerciseStatus.assigned).length;

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: Text(
            student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('@${student.username}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Editar')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))])),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                Row(
                  children: [
                    _MiniStat(label: 'Asignados', value: (pending + inProgress).toString(), color: Colors.blue),
                    const SizedBox(width: 16),
                    _MiniStat(label: 'En progreso', value: inProgress.toString(), color: Colors.orange),
                    const SizedBox(width: 16),
                    _MiniStat(label: 'Completados', value: completed.toString(), color: Colors.green),
                  ],
                ),
                const SizedBox(height: 16),
                // Ejercicios
                if (studentExercises.isEmpty)
                  Text('Sin ejercicios asignados', style: TextStyle(color: Colors.grey[600]))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: studentExercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final se = studentExercises[index];
                      return _StudentExerciseTile(se: se, provider: provider);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    if (action == 'delete') {
      _confirmDelete(context);
    } else if (action == 'edit') {
      _showEditDialog(context);
    }
  }

  void _confirmDelete(BuildContext context) {
    showConfirmDialog(
      context,
      title: 'Eliminar alumno',
      content: '¿Eliminar a ${student.fullName}? Se borrarán todos sus ejercicios y notas.',
      confirmText: 'Eliminar',
      isDestructive: true,
      onConfirm: () async {
        await provider.deleteStudent(student.id!);
        if (context.mounted) {
          showSnackBar(context, 'Alumno eliminado');
        }
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: student.fullName);
    final usernameController = TextEditingController(text: student.username);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar alumno'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      final updated = student.copyWith(
                        fullName: nameController.text.trim(),
                        username: usernameController.text.trim(),
                      );
                      await provider.updateUser(updated);
                      if (context.mounted) {
                        setState(() => isLoading = false);
                        Navigator.pop(context);
                        showSnackBar(context, 'Alumno actualizado');
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
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StudentExerciseTile extends StatelessWidget {
  final StudentExercise se;
  final AppProvider provider;

  const _StudentExerciseTile({required this.se, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getStatusColor(se.status).withOpacity(0.1),
      child: ListTile(
        leading: Icon(exerciseStatusIcon(se.status), color: _getStatusColor(se.status)),
        title: Text(se.exerciseId.toString()), // TODO: mostrar título del ejercicio
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado: ${exerciseStatusLabel(se.status)}'),
            if (se.rating != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  buildRatingStars(se.rating!, size: 16),
                  const SizedBox(width: 8),
                  if (se.difficultyFelt != null)
                    buildDifficultyChip(se.difficultyFelt!, fontSize: 10),
                ],
              ),
            ],
          ],
        ),
        trailing: se.status == ExerciseStatus.completed
            ? IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                onPressed: () => _showDetailDialog(context),
                tooltip: 'Ver detalles',
              )
            : null,
        onTap: se.status == ExerciseStatus.completed ? () => _showDetailDialog(context) : null,
      ),
    );
  }

  Color _getStatusColor(ExerciseStatus status) {
    return exerciseStatusColor(status);
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ejercicio #${se.exerciseId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('Estado', exerciseStatusLabel(se.status)),
            if (se.startedAt != null) _DetailRow('Iniciado', formatDateTime(se.startedAt!)),
            if (se.completedAt != null) _DetailRow('Completado', formatDateTime(se.completedAt!)),
            if (se.difficultyFelt != null) _DetailRow('Dificultad sentida', difficultyLabel(se.difficultyFelt!)),
            if (se.rating != null) _DetailRow('Nota', '${se.rating}/10'),
            if (se.studentNotes != null && se.studentNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Notas del alumno:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(se.studentNotes!),
            ],
            if (se.teacherPrivateNotes != null && se.teacherPrivateNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Tus notas privadas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Text(se.teacherPrivateNotes!),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          if (se.teacherPrivateNotes == null || se.teacherPrivateNotes!.isEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddPrivateNoteDialog(context);
              },
              child: const Text('Añadir nota privada'),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditPrivateNoteDialog(context);
              },
              child: const Text('Editar nota privada'),
            ),
        ],
      ),
    );
  }

  void _showAddPrivateNoteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nota privada del profesor'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Anotación (solo tú la ves)',
            hintText: 'Ej: Mejorar técnica de zancada, revisar rodilla...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await provider.updateTeacherPrivateNotes(se.id!, controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  showSnackBar(context, 'Nota guardada');
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditPrivateNoteDialog(BuildContext context) {
    final controller = TextEditingController(text: se.teacherPrivateNotes);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar nota privada'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Anotación (solo tú la ves)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await provider.updateTeacherPrivateNotes(se.id!, controller.text.trim());
              if (context.mounted) {
                Navigator.pop(dialogContext);
                showSnackBar(context, 'Nota actualizada');
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
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