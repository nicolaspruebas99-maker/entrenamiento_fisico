import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _db = DatabaseService();
  static const _keyCurrentUser = 'current_user_id';
  static const _keyRememberMe = 'remember_me';

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    if (rememberMe) {
      final userIdStr = await _storage.read(key: _keyCurrentUser);
      if (userIdStr != null) {
        final userId = int.tryParse(userIdStr);
        if (userId != null) {
          _currentUser = await _db.getUserById(userId);
        }
      }
    }
  }

  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    final user = await _db.getUserByUsername(username);
    if (user == null) return false;
    
    // Verificar contraseña (en producción usar bcrypt/hash real)
    if (!_verifyPassword(password, user.passwordHash)) return false;

    _currentUser = user;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe);
    
    if (rememberMe) {
      await _storage.write(key: _keyCurrentUser, value: user.id.toString());
    }
    
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, false);
    await _storage.delete(key: _keyCurrentUser);
  }

  Future<User?> registerTeacher({
    required String username,
    required String password,
    required String fullName,
  }) async {
    // Verificar si existe
    final existing = await _db.getUserByUsername(username);
    if (existing != null) return null;

    final user = User(
      username: username,
      passwordHash: _hashPassword(password),
      fullName: fullName,
      role: UserRole.teacher,
    );
    
    final id = await _db.insertUser(user);
    return user.copyWith(id: id);
  }

  Future<User?> registerStudent({
    required String username,
    required String password,
    required String fullName,
    required int teacherId,
  }) async {
    final existing = await _db.getUserByUsername(username);
    if (existing != null) return null;

    final user = User(
      username: username,
      passwordHash: _hashPassword(password),
      fullName: fullName,
      role: UserRole.student,
      teacherId: teacherId,
    );
    
    final id = await _db.insertUser(user);
    return user.copyWith(id: id);
  }

  bool _verifyPassword(String password, String hash) {
    // En producción usar bcrypt: BCrypt.checkpw(password, hash)
    // Para simplicidad usamos hash simple (NO seguro para producción real)
    return _hashPassword(password) == hash;
  }

  String _hashPassword(String password) {
    // Hash simple para demo - EN PRODUCCIÓN USAR BCRYPT
    return 'hash_${password.hashCode}';
  }

  bool get isLoggedIn => _currentUser != null;
  bool get isTeacher => _currentUser?.role == UserRole.teacher;
  bool get isStudent => _currentUser?.role == UserRole.student;
}