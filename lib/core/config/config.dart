class Config {
  static const bool loggerOn = true; // Set to false in production
  static const bool debugLog = true; // Set to false in production
  static const bool errorLog = true; // Set to false in production
  static const bool infoLog = true; // Set to false in production
  static const bool warningLog = true; // Set to false in production

  static const bool saveLogToFile = false; // Set to false in production
  static const int logBatchSize =
      10; // Number of logs to batch together before writing to file
  static const Duration logFlushInterval = Duration(
    seconds: 5,
  ); // How often to flush logs to file

  // Database configuration
  static const bool useDirectDatabaseConnection =
      true; // Set to false to use service factory database - in production set to false
  static const bool enableDatabaseService =
      true; // Set to false to disable database service completely

  /// Map of privilege levels to their corresponding names
  static const Map<int, String> privilegeNames = {
    0: 'visitor',
    1: 'builder',
    2: 'installer',
    3: 'admin',
    4: 'superAdmin',
  };

  /// Map of privilege names to their corresponding levels
  static const Map<String, int> privilegeLevels = {
    'visitor': 0,
    'builder': 1,
    'installer': 2,
    'admin': 3,
    'superAdmin': 4,
  };

  /// Checks if a user has sufficient privileges for a required privilege level
  ///
  /// [userPrivilege] The user's current privilege level (0-4)
  /// [requiredPrivilege] The name of the required privilege level ('visitor', 'builder', 'installer', 'admin', 'superAdmin')
  /// Returns true if the user has sufficient privileges, false otherwise
  static bool hasRequiredPrivilege(
    int userPrivilege,
    String requiredPrivilege,
  ) {
    // Get the required privilege level
    final requiredLevel = privilegeLevels[requiredPrivilege.toLowerCase()];

    // If the required privilege is not found in the map, return false
    if (requiredLevel == null) {
      return false;
    }

    // User has sufficient privileges if their level is greater than or equal to the required level
    return userPrivilege >= requiredLevel;
  }

  /// Gets the name of a privilege level
  ///
  /// [privilegeLevel] The privilege level (0-4)
  /// Returns the name of the privilege level, or highest/lowest known privilege if out of range
  static String getPrivilegeName(int privilegeLevel) {
    if (privilegeLevel < 0) {
      return privilegeNames[0]!; // Return 'visitor' for negative levels
    }

    final maxLevel = privilegeNames.keys.reduce((a, b) => a > b ? a : b);
    if (privilegeLevel > maxLevel) {
      return privilegeNames[maxLevel]!; // Return highest privilege for levels above max
    }

    return privilegeNames[privilegeLevel] ?? 'unknown';
  }

  /// Gets the level of a privilege name
  ///
  /// [privilegeName] The name of the privilege ('visitor', 'builder', 'installer', 'admin', 'superAdmin')
  /// Returns the privilege level, or -1 if not found
  static int getPrivilegeLevel(String privilegeName) {
    return privilegeLevels[privilegeName.toLowerCase()] ?? -1;
  }

  /// Checks if a user has superAdmin privileges
  ///
  /// [userPrivilege] The user's current privilege level
  /// Returns true if the user has superAdmin privileges
  static bool isSuperAdmin(int userPrivilege) {
    return userPrivilege >= privilegeLevels['superAdmin']!;
  }

  /// Checks if a user has admin privileges
  ///
  /// [userPrivilege] The user's current privilege level
  /// Returns true if the user has admin privileges
  static bool isAdmin(int userPrivilege) {
    return userPrivilege >= privilegeLevels['admin']!;
  }

  /// Checks if a user has installer privileges
  ///
  /// [userPrivilege] The user's current privilege level
  /// Returns true if the user has installer privileges
  static bool isInstaller(int userPrivilege) {
    return userPrivilege >= privilegeLevels['installer']!;
  }

  /// Checks if a user has builder privileges
  ///
  /// [userPrivilege] The user's current privilege level
  /// Returns true if the user has builder privileges
  static bool isBuilder(int userPrivilege) {
    return userPrivilege >= privilegeLevels['builder']!;
  }

  /// Gets all available privilege levels
  ///
  /// Returns a list of all privilege levels (0-4)
  static List<int> getAvailablePrivilegeLevels() {
    return privilegeNames.keys.toList();
  }

  /// Gets all available privilege names
  ///
  /// Returns a list of all privilege names
  static List<String> getAvailablePrivilegeNames() {
    return privilegeNames.values.toList();
  }
}
