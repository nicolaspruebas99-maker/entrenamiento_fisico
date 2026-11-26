import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/exercise.dart';
import '../models/student_exercise.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.isLoggedIn;
  bool get isTeacher => _auth.isTeacher;
  bool get isStudent => _auth.isStudent;

  // Estado del profesor
  List<User> _students = [];
  List<Exercise> _exercises = [];
  List<StudentExercise> _studentExercises = [];

  List<User> get students => _students;
  List<Exercise> get exercises => _exercises;
  List<StudentExercise> get studentExercises => _studentExercises;

  // Estado del alumno
  List<StudentExercise> _myExercises = [];
  List<StudentExercise> get myExercises => _myExercises;

  Future<void> initialize() async {
    await _auth.init();
    if (_auth.isLoggedIn) {
      await _loadDataForCurrentUser();
    }
    notifyListeners();
  }

  Future<void> _loadDataForCurrentUser() async {
    if (_auth.isTeacher) {
      await _loadTeacherData();
    } else if (_auth.isStudent) {
      await _loadStudentData();
    }
  }

  Future<void> _loadTeacherData() async {
    final teacherId = _auth.currentUser!.id!;
    _students = await _db.getStudentsByTeacher(teacherId);
    _exercises = await _db.getExercisesByTeacher(teacherId);
    _studentExercises = await _db.getStudentExercisesByTeacher(teacherId);
  }

  Future<void> _loadStudentData() async {
    final studentId = _auth.currentUser!.id!;
    _myExercises = await _db.getStudentExercisesByStudent(studentId);
  }

  // ============ AUTH ============

  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    final success = await _auth.login(username, password, rememberMe: rememberMe);
    if (success) {
      await _loadDataForCurrentUser();
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    await _auth.logout();
    _students.clear();
    _exercises.clear();
    _studentExercises.clear();
    _myExercises.clear();
    notifyListeners();
  }

  Future<User?> registerTeacher({
    required String username,
    required String password,
    required String fullName,
  }) async {
    final user = await _auth.registerTeacher(
      username: username,
      password: password,
      fullName: fullName,
    );
    if (user != null) {
      await login(username, password);
    }
    return user;
  }

  Future<User?> registerStudent({
    required String username,
    required String password,
    required String fullName,
  }) async {
    final teacherId = _auth.currentUser!.id!;
    final user = await _auth.registerStudent(
      username: username,
      password: password,
      fullName: fullName,
      teacherId: teacherId,
    );
    if (user != null) {
      _students.add(user);
      notifyListeners();
    }
    return user;
  }

  // ============ PROFESOR: ESTUDIANTES ============

  Future<void> refreshStudents() async {
    if (!_auth.isTeacher) return;
    _students = await _db.getStudentsByTeacher(_auth.currentUser!.id!);
    notifyListeners();
  }

  Future<bool> deleteStudent(int studentId) async {
    final result = await _db.deleteUser(studentId);
    if (result > 0) {
      _students.removeWhere((s) => s.id == studentId);
      notifyListeners();
      return true;
    }
    return false;
  }

  // ============ PROFESOR: EJERCICIOS ============

  Future<void> refreshExercises() async {
    if (!_auth.isTeacher) return;
    _exercises = await _db.getExercisesByTeacher(_auth.currentUser!.id!);
    notifyListeners();
  }

  Future<Exercise?> createExercise({
    required String title,
    required String description,
    required String instructions,
    DifficultyLevel defaultDifficulty = DifficultyLevel.medium,
    int estimatedDurationMinutes = 30,
  }) async {
    if (!_auth.isTeacher) return null;
    
    final exercise = Exercise(
      teacherId: _auth.currentUser!.id!,
      title: title,
      description: description,
      instructions: instructions,
      defaultDifficulty: defaultDifficulty,
      estimatedDurationMinutes: estimatedDurationMinutes,
    );
    
    final id = await _db.insertExercise(exercise);
    final newExercise = exercise.copyWith(id: id);
    _exercises.insert(0, newExercise);
    notifyListeners();
    return newExercise;
  }

  Future<bool> updateExercise(Exercise exercise) async {
    final result = await _db.updateExercise(exercise);
    if (result > 0) {
      final index = _exercises.indexWhere((e) => e.id == exercise.id);
      if (index != -1) {
        _exercises[index] = exercise;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteExercise(int exerciseId) async {
    final result = await _db.deleteExercise(exerciseId);
    if (result > 0) {
      _exercises.removeWhere((e) => e.id == exerciseId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<Exercise?> getExerciseById(int id) async {
    return await _db.getExerciseById(id);
  }

  // Asignar ejercicio a estudiantes
  Future<void> assignExerciseToStudents(int exerciseId, List<int> studentIds) async {
    if (!_auth.isTeacher) return;
    await _db.assignExerciseToStudents(
      exerciseId,
      _auth.currentUser!.id!,
      studentIds,
    );
    await _refreshStudentExercises();
  }

  Future<void> _refreshStudentExercises() async {
    if (!_auth.isTeacher) return;
    _studentExercises = await _db.getStudentExercisesByTeacher(_auth.currentUser!.id!);
    notifyListeners();
  }

  // ============ PROFESOR: ANOTACIONES PRIVADAS ============

  Future<bool> updateTeacherPrivateNotes(int studentExerciseId, String notes) async {
    final se = _studentExercises.firstWhere(
      (s) => s.id == studentExerciseId,
      orElse: () => throw Exception('No encontrado'),
    );
    final updated = se.copyWith(teacherPrivateNotes: notes);
    final result = await _db.updateStudentExercise(updated);
    if (result > 0) {
      final index = _studentExercises.indexWhere((s) => s.id == studentExerciseId);
      if (index != -1) {
        _studentExercises[index] = updated;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  // ============ ALUMNO: MIS EJERCICIOS ============

  Future<void> refreshMyExercises() async {
    if (!_auth.isStudent) return;
    _myExercises = await _db.getStudentExercisesByStudent(_auth.currentUser!.id!);
    notifyListeners();
  }

  Future<bool> startExercise(int studentExerciseId) async {
    final se = _myExercises.firstWhere(
      (s) => s.id == studentExerciseId,
      orElse: () => throw Exception('No encontrado'),
    );
    final updated = se.copyWith(
      status: ExerciseStatus.inProgress,
      startedAt: DateTime.now(),
    );
    final result = await _db.updateStudentExercise(updated);
    if (result > 0) {
      final index = _myExercises.indexWhere((s) => s.id == studentExerciseId);
      if (index != -1) {
        _myExercises[index] = updated;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> completeExercise({
    required int studentExerciseId,
    required DifficultyLevel difficultyFelt,
    required int rating,
    String? studentNotes,
  }) async {
    final se = _myExercises.firstWhere(
      (s) => s.id == studentExerciseId,
      orElse: () => throw Exception('No encontrado'),
    );
    final updated = se.copyWith(
      status: ExerciseStatus.completed,
      completedAt: DateTime.now(),
      difficultyFelt: difficultyFelt,
      rating: rating.clamp(1, 10),
      studentNotes: studentNotes,
    );
    final result = await _db.updateStudentExercise(updated);
    if (result > 0) {
      final index = _myExercises.indexWhere((s) => s.id == studentExerciseId);
      if (index != -1) {
        _myExercises[index] = updated;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> skipExercise(int studentExerciseId) async {
    final se = _myExercises.firstWhere(
      (s) => s.id == studentExerciseId,
      orElse: () => throw Exception('No encontrado'),
    );
    final updated = se.copyWith(status: ExerciseStatus.skipped);
    final result = await _db.updateStudentExercise(updated);
    if (result > 0) {
      final index = _myExercises.indexWhere((s) => s.id == studentExerciseId);
      if (index != -1) {
        _myExercises[index] = updated;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  // Helper para copyWith en Exercise
  Exercise copyWithExercise(Exercise e, {int? id}) {
    return Exercise(
      id: id ?? e.id,
      teacherId: e.teacherId,
      title: e.title,
      description: e.description,
      instructions: e.instructions,
      defaultDifficulty: e.defaultDifficulty,
      estimatedDurationMinutes: e.estimatedDurationMinutes,
      createdAt: e.createdAt,
      isActive: e.isActive,
    );
  }

  // ============ MÉTODOS ADICIONALES ============

  Future<bool> updateUser(User user) async {
    final result = await _db.updateUser(user);
    if (result > 0) {
      final index = _students.indexWhere((s) => s.id == user.id);
      if (index != -1) {
        _students[index] = user;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> updateStudentExercise(StudentExercise se) async {
    final result = await _db.updateStudentExercise(se);
    if (result > 0) {
      // Actualizar en lista del profesor
      final teacherIndex = _studentExercises.indexWhere((s) => s.id == se.id);
      if (teacherIndex != -1) {
        _studentExercises[teacherIndex] = se;
      }
      // Actualizar en lista del alumno
      final studentIndex = _myExercises.indexWhere((s) => s.id == se.id);
      if (studentIndex != -1) {
        _myExercises[studentIndex] = se;
      }
      notifyListeners();
      return true;
    }
    return false;
  }
}