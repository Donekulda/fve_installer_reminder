class FVEInstallation {
  final int id;
  final String name;
  final String address;
  final DateTime installationDate;
  final List<String> requiredPhotos;

  FVEInstallation({
    required this.id,
    required this.name,
    required this.address,
    required this.installationDate,
    required this.requiredPhotos,
  });

  factory FVEInstallation.fromMap(Map<String, dynamic> map) {
    return FVEInstallation(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      installationDate: DateTime.parse(map['installation_date']),
      requiredPhotos: List<String>.from(map['required_photos'].split(',')),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'installation_date': installationDate.toIso8601String(),
      'required_photos': requiredPhotos.join(','),
    };
  }
} 