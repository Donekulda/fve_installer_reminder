/// Model class representing a required image type in the database.
/// Defines the types of images that need to be taken for FVE installations.
class RequiredImage {
  /// Unique identifier for the required image type
  final int id;

  /// Name of the required image type
  final String? name;

  /// Minimum number of images required for this type
  final int minImages;

  /// Detailed description of what photos should be taken
  final String? description;

  /// Creates a new RequiredImage instance.
  ///
  /// [id] - Unique identifier for the required image type
  /// [name] - Name of the required image type
  /// [minImages] - Minimum number of images required for this type
  /// [description] - Detailed description of what photos should be taken
  RequiredImage({
    required this.id,
    this.name,
    this.minImages = 1,
    this.description,
  });

  /// Creates a RequiredImage instance from a JSON map.
  ///
  /// [json] - Map containing the required image type data
  /// Returns a new RequiredImage instance
  factory RequiredImage.fromJson(Map<String, dynamic> json) {
    return RequiredImage(
      id: json['id'] as int,
      name: json['name'] as String?,
      minImages: json['min_images'] as int? ?? 1,
      description: json['description'] as String?,
    );
  }

  /// Converts the RequiredImage instance to a JSON map.
  ///
  /// Returns a Map containing the required image type data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'min_images': minImages,
      'description': description,
    };
  }
}
