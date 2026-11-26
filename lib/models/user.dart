enum UserRole { teacher, student }

class User {
  final int? id;
  final String username;
  final String passwordHash;
  final String fullName;
  final UserRole role;
  final int? teacherId; // Para estudiantes: ID de su profesor
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    required this.role,
    this.teacherId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'full_name': fullName,
      'role': role.index,
      'teacher_id': teacherId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password_hash'],
      fullName: map['full_name'],
      role: UserRole.values[map['role']],
      teacherId: map['teacher_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? fullName,
    UserRole? role,
    int? teacherId,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}