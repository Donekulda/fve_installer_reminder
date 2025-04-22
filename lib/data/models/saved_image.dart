/// Model class representing a saved image in the database.
/// Contains information about the image's location, type, and associated entities.
class SavedImage {
  /// Unique identifier for the saved image
  final int id;

  /// ID of the FVE installation this image belongs to
  final int fveInstallationId;

  /// ID of the required image type this image represents
  final int requiredImageId;

  /// File path or URL where the image is stored
  final String? location;

  /// Timestamp when the image was added
  final DateTime? timeAdded;

  /// Display name of the image
  final String? name;

  /// ID of the user who added this image
  final int userId;

  /// Creates a new SavedImage instance.
  ///
  /// [id] - Unique identifier for the saved image
  /// [fveInstallationId] - ID of the FVE installation this image belongs to
  /// [requiredImageId] - ID of the required image type this image represents
  /// [location] - File path or URL where the image is stored
  /// [timeAdded] - Timestamp when the image was added
  /// [name] - Display name of the image
  /// [userId] - ID of the user who added this image
  SavedImage({
    required this.id,
    required this.fveInstallationId,
    required this.requiredImageId,
    this.location,
    this.timeAdded,
    this.name,
    required this.userId,
  });

  /// Creates a SavedImage instance from a JSON map.
  ///
  /// [json] - Map containing the saved image data
  /// Returns a new SavedImage instance
  factory SavedImage.fromJson(Map<String, dynamic> json) {
    return SavedImage(
      id: json['id'] as int,
      fveInstallationId: json['fveInstalations_id'] as int,
      requiredImageId: json['requiredImages_id'] as int,
      location: json['location'] as String?,
      timeAdded:
          json['timeAdded'] != null
              ? DateTime.parse(json['timeAdded'] as String)
              : null,
      name: json['name'] as String?,
      userId: json['users_id'] as int,
    );
  }

  /// Converts the SavedImage instance to a JSON map.
  ///
  /// Returns a Map containing the saved image data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fveInstalations_id': fveInstallationId,
      'requiredImages_id': requiredImageId,
      'location': location,
      'timeAdded': timeAdded?.toIso8601String(),
      'name': name,
      'users_id': userId,
    };
  }
}
