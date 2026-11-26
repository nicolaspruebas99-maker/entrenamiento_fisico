import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/student_exercise.dart';
import '../../utils/helpers.dart';
import 'student_exercise_detail.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final student = provider.currentUser!;
        return Scaffold(
          appBar: AppBar(
            title: Text(student.fullName),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, provider),
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.refreshMyExercises(),
            child: _buildBody(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppProvider provider) {
    final exercises = provider.myExercises;
    final pending = exercises.where((e) => e.status == ExerciseStatus.assigned).toList();
    final inProgress = exercises.where((e) => e.status == ExerciseStatus.inProgress).toList();
    final completed = exercises.where((e) => e.status == ExerciseStatus.completed).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Por hacer', value: pending.length.toString(), icon: Icons.assignment, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: 'En curso', value: inProgress.length.toString(), icon: Icons.directions_run, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Completados', value: completed.length.toString(), icon: Icons.check_circle, color: Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: 'Total', value: exercises.length.toString(), icon: Icons.list, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),

          // Ejercicios en progreso (prioridad)
          if (inProgress.isNotEmpty) ...[
            Text('En progreso', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...inProgress.map((e) => _ExerciseCard(se: e, onTap: () => _openExercise(e))),
            const SizedBox(height: 24),
          ],

          // Ejercicios pendientes
          Text('Pendientes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('¡No tienes ejercicios pendientes!', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Los nuevos ejercicios aparecerán aquí', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            )
          else
            ...pending.map((e) => _ExerciseCard(se: e, onTap: () => _openExercise(e))),

          const SizedBox(height: 24),

          // Completados recientes
          if (completed.isNotEmpty) ...[
            Text('Completados recientemente', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...completed.take(3).map((e) => _CompletedExerciseCard(se: e, onTap: () => _openExercise(e))),
            if (completed.length > 3)
              TextButton(
                onPressed: () {},
                child: Text('Ver ${completed.length - 3} más...'),
              ),
          ],
        ],
      ),
    );
  }

  void _openExercise(StudentExercise se) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudentExerciseDetail(studentExercise: se)),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final StudentExercise se;
  final VoidCallback onTap;

  const _ExerciseCard({required this.se, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: exerciseStatusColor(se.status).withOpacity(0.2),
          child: Icon(exerciseStatusIcon(se.status), color: exerciseStatusColor(se.status)),
        ),
        title: Text('Ejercicio #${se.exerciseId}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Asignado: ${formatDate(se.assignedAt)}'),
        trailing: buildStatusChip(se.status),
        onTap: onTap,
      ),
    );
  }
}

class _CompletedExerciseCard extends StatelessWidget {
  final StudentExercise se;
  final VoidCallback onTap;

  const _CompletedExerciseCard({required this.se, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.green.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.2),
          child: const Icon(Icons.check_circle, color: Colors.green),
        ),
        title: Text('Ejercicio #${se.exerciseId}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completado: ${formatDate(se.completedAt!)}'),
            if (se.rating != null || se.difficultyFelt != null)
              Row(
                children: [
                  if (se.rating != null) ...[
                    buildRatingStars(se.rating!, size: 14),
                    const SizedBox(width: 8),
                  ],
                  if (se.difficultyFelt != null)
                    buildDifficultyChip(se.difficultyFelt!, fontSize: 10),
                ],
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}