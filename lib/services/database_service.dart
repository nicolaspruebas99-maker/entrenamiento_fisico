import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/exercise.dart';
import '../models/student_exercise.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'entrenamiento_fisico.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role INTEGER NOT NULL,
        teacher_id INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (teacher_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        instructions TEXT NOT NULL,
        default_difficulty INTEGER NOT NULL,
        estimated_duration_minutes INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (teacher_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE student_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        teacher_id INTEGER NOT NULL,
        assigned_at INTEGER NOT NULL,
        started_at INTEGER,
        completed_at INTEGER,
        difficulty_felt INTEGER,
        rating INTEGER,
        student_notes TEXT,
        teacher_private_notes TEXT,
        status INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (student_id) REFERENCES users (id),
        FOREIGN KEY (exercise_id) REFERENCES exercises (id),
        FOREIGN KEY (teacher_id) REFERENCES users (id)
      )
    ''');

    // Índices para consultas frecuentes
    await db.execute('CREATE INDEX idx_users_teacher ON users(teacher_id)');
    await db.execute('CREATE INDEX idx_exercises_teacher ON exercises(teacher_id)');
    await db.execute('CREATE INDEX idx_student_exercises_student ON student_exercises(student_id)');
    await db.execute('CREATE INDEX idx_student_exercises_teacher ON student_exercises(teacher_id)');
    await db.execute('CREATE INDEX idx_student_exercises_exercise ON student_exercises(exercise_id)');
  }

  // ============ USUARIOS ============

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<List<User>> getStudentsByTeacher(int teacherId) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'teacher_id = ? AND role = ?',
      whereArgs: [teacherId, UserRole.student.index],
      orderBy: 'full_name ASC',
    );
    return maps.map((m) => User.fromMap(m)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ============ EJERCICIOS ============

  Future<int> insertExercise(Exercise exercise) async {
    final db = await database;
    return await db.insert('exercises', exercise.toMap());
  }

  Future<List<Exercise>> getExercisesByTeacher(int teacherId, {bool onlyActive = true}) async {
    final db = await database;
    final where = onlyActive 
        ? 'teacher_id = ? AND is_active = 1' 
        : 'teacher_id = ?';
    final maps = await db.query(
      'exercises',
      where: where,
      whereArgs: [teacherId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<Exercise?> getExerciseById(int id) async {
    final db = await database;
    final maps = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await database;
    return await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> deleteExercise(int id) async {
    final db = await database;
    return await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ============ EJERCICIOS DE ESTUDIANTES ============

  Future<int> insertStudentExercise(StudentExercise se) async {
    final db = await database;
    return await db.insert('student_exercises', se.toMap());
  }

  Future<List<StudentExercise>> getStudentExercisesByStudent(int studentId) async {
    final db = await database;
    final maps = await db.query(
      'student_exercises',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'assigned_at DESC',
    );
    return maps.map((m) => StudentExercise.fromMap(m)).toList();
  }

  Future<List<StudentExercise>> getStudentExercisesByTeacher(int teacherId) async {
    final db = await database;
    final maps = await db.query(
      'student_exercises',
      where: 'teacher_id = ?',
      whereArgs: [teacherId],
      orderBy: 'assigned_at DESC',
    );
    return maps.map((m) => StudentExercise.fromMap(m)).toList();
  }

  Future<List<StudentExercise>> getStudentExercisesByExercise(int exerciseId) async {
    final db = await database;
    final maps = await db.query(
      'student_exercises',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'assigned_at DESC',
    );
    return maps.map((m) => StudentExercise.fromMap(m)).toList();
  }

  Future<StudentExercise?> getStudentExercise(int studentId, int exerciseId) async {
    final db = await database;
    final maps = await db.query(
      'student_exercises',
      where: 'student_id = ? AND exercise_id = ?',
      whereArgs: [studentId, exerciseId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return StudentExercise.fromMap(maps.first);
  }

  Future<int> updateStudentExercise(StudentExercise se) async {
    final db = await database;
    return await db.update(
      'student_exercises',
      se.toMap(),
      where: 'id = ?',
      whereArgs: [se.id],
    );
  }

  // Asignar ejercicio a múltiples estudiantes
  Future<void> assignExerciseToStudents(int exerciseId, int teacherId, List<int> studentIds) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (final studentId in studentIds) {
      // Verificar si ya existe
      final existing = await getStudentExercise(studentId, exerciseId);
      if (existing == null) {
        batch.insert('student_exercises', {
          'student_id': studentId,
          'exercise_id': exerciseId,
          'teacher_id': teacherId,
          'assigned_at': now,
          'status': ExerciseStatus.assigned.index,
        });
      }
    }
    await batch.commit(noResult: true);
  }
}