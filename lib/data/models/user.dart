/// Model class representing a user in the database.
/// Contains information about the user's credentials, privileges, and status.
class User {
  /// Unique identifier for the user
  final int id;

  /// Username used for login
  final String username;

  /// Password for authentication
  final String password;

  /// Full name of the user
  final String? fullname;

  /// User's privilege level (0=Regular, 1=Installer, 2=Admin)
  final int privileges;

  /// Whether the user account is active
  final bool active;

  /// Creates a new User instance.
  ///
  /// [id] - Unique identifier for the user
  /// [username] - Username used for login
  /// [password] - Password for authentication
  /// [fullname] - Full name of the user
  /// [privileges] - User's privilege level
  /// [active] - Whether the user account is active
  User({
    required this.id,
    required this.username,
    required this.password,
    this.fullname,
    required this.privileges,
    required this.active,
  });

  /// Creates a User instance from a JSON map.
  ///
  /// [json] - Map containing the user data
  /// Returns a new User instance
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['nick'] as String,
      password: json['pass'] as String,
      fullname: json['fullname'] as String?,
      privileges: json['privileges'] as int,
      active: json['active'] == 1,
    );
  }

  /// Converts the User instance to a JSON map.
  ///
  /// Returns a Map containing the user data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nick': username,
      'pass': password,
      'fullname': fullname,
      'privileges': privileges,
      'active': active ? 1 : 0,
    };
  }

  /// Whether the user has any privileges (privileges > 0)
  bool get isPrivileged => privileges > 0;
}
