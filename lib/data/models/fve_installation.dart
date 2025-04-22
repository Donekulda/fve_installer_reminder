/// Model class representing a FVE installation in the database.
/// Contains information about the installation's location and responsible user.
class FVEInstallation {
  /// Unique identifier for the FVE installation
  final int id;

  /// Name of the FVE installation
  final String? name;

  /// Region where the FVE installation is located
  final String? region;

  /// Address of the FVE installation
  final String? address;

  /// ID of the user responsible for this installation
  final int userId;

  /// Creates a new FVEInstallation instance.
  ///
  /// [id] - Unique identifier for the FVE installation
  /// [name] - Name of the FVE installation
  /// [region] - Region where the FVE installation is located
  /// [address] - Address of the FVE installation
  /// [userId] - ID of the user responsible for this installation
  FVEInstallation({
    required this.id,
    this.name,
    this.region,
    this.address,
    required this.userId,
  });

  /// Creates a FVEInstallation instance from a JSON map.
  ///
  /// [json] - Map containing the FVE installation data
  /// Returns a new FVEInstallation instance
  factory FVEInstallation.fromJson(Map<String, dynamic> json) {
    return FVEInstallation(
      id: json['id'] as int,
      name: json['name'] as String?,
      region: json['region'] as String?,
      address: json['address'] as String?,
      userId: json['users_id'] as int,
    );
  }

  /// Converts the FVEInstallation instance to a JSON map.
  ///
  /// Returns a Map containing the FVE installation data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'address': address,
      'users_id': userId,
    };
  }
}
