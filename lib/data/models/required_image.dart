/// Model class representing a required image type in the database.
/// Defines the types of images that need to be taken for FVE installations.
class RequiredImage {
  /// Unique identifier for the required image type
  final int id;

  /// Name of the required image type
  final String? name;

  /// Creates a new RequiredImage instance.
  ///
  /// [id] - Unique identifier for the required image type
  /// [name] - Name of the required image type
  RequiredImage({required this.id, this.name});

  /// Creates a RequiredImage instance from a JSON map.
  ///
  /// [json] - Map containing the required image type data
  /// Returns a new RequiredImage instance
  factory RequiredImage.fromJson(Map<String, dynamic> json) {
    return RequiredImage(id: json['id'] as int, name: json['name'] as String?);
  }

  /// Converts the RequiredImage instance to a JSON map.
  ///
  /// Returns a Map containing the required image type data
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
