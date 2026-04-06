class PlantCare {
  /// Returns a new [PlantCare] instance.
  PlantCare({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.description,
    required this.sun,
    required this.growthRate,
    required this.careLevel,
    required this.watering,
    required this.maintenance,
  });

  int id;
  String commonName;
  String scientificName;
  String description;
  String sun;
  String? growthRate;
  String? careLevel;
  String? watering;
  String? maintenance;

  /// Returns a new [Data] instance
  static PlantCare fromJson(Map<String, Object?> json) {
    return switch (json) {
      {
        'id': final int id,
        'common_name': final String commonName,
        'scientific_name': final List<dynamic> scientificName,
        'description': final String description,
        'sunlight': final List<dynamic> sun,
        'growth_rate': final String? growthRate,
        'care_level': final String? careLevel,
        'watering': final String? watering,
        'maintenance': final String? maintenance,
      } =>
        PlantCare(
          id: id,
          commonName: commonName,
          scientificName: scientificName.firstOrNull?.toString() ?? 'Unknown',
          description: description,
          sun: sun.join(', '),
          growthRate: growthRate,
          careLevel: careLevel,
          watering: watering,
          maintenance: maintenance,
        ),
      _ => throw FormatException('Could not deserialize Data, json=$json'),
    };
  }

  @override
  String toString() =>
      'Data['
      '\n\tcommonName: $commonName, '
      '\n\tscientificName: $scientificName, '
      '\n\tsun: $sun, '
      '\n\tgrowthRate: $growthRate, '
      '\n\tcareLevel: $careLevel, '
      '\n\twatering: $watering, '
      '\n\tmaintenance: $maintenance'
      '\n]';
}

class PlantInfo {
  /// Returns a new [PlantInfo] instance.
  PlantInfo({
    required this.id,
    required this.commonName,
    required this.scientificName,
  });

  int id;
  String commonName;
  String scientificName;

  /// Returns a new [Data] instance
  static PlantInfo fromJson(Map<String, Object?> json) {
    return switch (json) {
      {
        'id': final int id,
        'common_name': final String commonName,
        'scientific_name': final List<dynamic> scientificName,
      } =>
        PlantInfo(
          id: id,
          commonName: commonName,
          scientificName: scientificName.firstOrNull?.toString() ?? 'Unknown',
        ),
      _ => throw FormatException('Could not deserialize Data, json=$json'),
    };
  }

  static List<PlantInfo> fromJsonList(List<dynamic> jsonList) {
    try {
      return jsonList
          .map((item) => PlantInfo.fromJson(item as Map<String, Object?>))
          .toList();
    } catch (e) {
      print('caught error: $e');
      return List<PlantInfo>.empty();
    }
  }

  @override
  String toString() =>
      'Data['
      '\n\tcommonName: $commonName, '
      '\n\tscientificName: $scientificName, '
      '\n]\n';
}
