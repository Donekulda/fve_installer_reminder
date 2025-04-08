class User {
  final int id;
  final String username;
  final String password;
  final bool isPrivileged;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.isPrivileged,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      isPrivileged: map['is_privileged'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'is_privileged': isPrivileged ? 1 : 0,
    };
  }
} 