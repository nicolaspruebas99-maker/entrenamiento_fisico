import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/user.dart';
import '../../models/exercise.dart';
import '../../utils/helpers.dart';
import 'students_screen.dart';
import 'exercises_screen.dart';
import 'teacher_exercise_detail.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardHome(),
    const StudentsScreen(),
    const ExercisesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final teacher = provider.currentUser!;
        return Scaffold(
          appBar: AppBar(
            title: Text('Prof. ${teacher.fullName}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, provider),
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          body: _screens[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard), label: 'Inicio'),
              NavigationDestination(icon: Icon(Icons.people), label: 'Alumnos'),
              NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Ejercicios'),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AppProvider provider) {
    showConfirmDialog(
      context,
      title: 'Cerrar sesión',
      content: '¿Seguro que quieres cerrar sesión?',
      onConfirm: () => provider.logout(),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final totalStudents = provider.students.length;
        final totalExercises = provider.exercises.length;
        final assignedExercises = provider.studentExercises.length;
        final completedExercises = provider.studentExercises
            .where((se) => se.status == ExerciseStatus.completed)
            .length;

        return RefreshIndicator(
          onRefresh: () async {
            await provider.refreshStudents();
            await provider.refreshExercises();
            await provider._refreshStudentExercises();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Alumnos',
                        value: totalStudents.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Ejercicios',
                        value: totalExercises.toString(),
                        icon: Icons.fitness_center,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Asignados',
                        value: assignedExercises.toString(),
                        icon: Icons.assignment,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Completados',
                        value: completedExercises.toString(),
                        icon: Icons.check_circle,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Acciones rápidas
                Text('Acciones rápidas', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: 'Nuevo alumno',
                        subtitle: 'Registrar estudiante',
                        icon: Icons.person_add,
                        color: Colors.blue,
                        onTap: () => _showAddStudentDialog(context, provider),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        title: 'Nuevo ejercicio',
                        subtitle: 'Crear entrenamiento',
                        icon: Icons.add_circle,
                        color: Colors.green,
                        onTap: () => _showAddExerciseDialog(context, provider),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Ejercicios recientes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ejercicios recientes', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => _navigateToTab(context, 2),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (provider.exercises.isEmpty)
                  _EmptyState(
                    icon: Icons.fitness_center,
                    title: 'No hay ejercicios',
                    subtitle: 'Crea tu primer entrenamiento',
                    onAction: () => _showAddExerciseDialog(context, provider),
                    actionLabel: 'Crear ejercicio',
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.exercises.take(3).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final exercise = provider.exercises[index];
                      return _ExerciseListTile(
                        exercise: exercise,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeacherExerciseDetail(exercise: exercise),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Alumnos recientes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Alumnos recientes', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => _navigateToTab(context, 1),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (provider.students.isEmpty)
                  _EmptyState(
                    icon: Icons.people,
                    title: 'No hay alumnos',
                    subtitle: 'Registra tu primer estudiante',
                    onAction: () => _showAddStudentDialog(context, provider),
                    actionLabel: 'Añadir alumno',
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.students.take(3).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = provider.students[index];
                      return _StudentListTile(student: student);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToTab(BuildContext context, int index) {
    // Esto requeriría un callback al padre, simplificamos
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Usa la navegación inferior para ir a esa pestaña')),
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
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Usuario'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            )),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseListTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: difficultyColor(exercise.defaultDifficulty).withOpacity(0.2),
          child: Icon(difficultyIcon(exercise.defaultDifficulty), color: difficultyColor(exercise.defaultDifficulty)),
        ),
        title: Text(exercise.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(exercise.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: buildDifficultyChip(exercise.defaultDifficulty),
        onTap: onTap,
      ),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  final User student;

  const _StudentListTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: Text(student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('@${student.username}'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onAction;
  final String actionLabel;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onAction,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}