class Data {
  /// Returns a new [Data] instance.
  Data({
    required this.humidity,
    required this.light,
    required this.moisture,
    required this.temperature,
    required this.time,
  });

  int humidity;
  int light;
  int moisture;
  double temperature;
  String time;

  /// Returns a new [Summary] instance
  static Data fromJson(Map<String, Object?> json) {
    return switch (json) {
      { 
        'humidity': final int humidity,
        'light': final int light,
        'moisture': final int moisture,
        'temperature': final double temperature,
        'time': final String time,
      } => 
        Data(
          humidity: humidity,
          light: light,
          moisture: moisture,
          temperature: temperature,
          time: DateTime.parse(time).toLocal().toString().replaceAll('T', ' ').split('.').first, // Format to "YYYY-MM-DD HH:MM:SS"
        ),
      _ => throw FormatException('Could not deserialize Summary, json=$json'),
    };
  }

  @override
  String toString() =>
      'Data['
      'humidity=$humidity, '
      'light=$light, '
      'moisture=$moisture, '
      'temperature=$temperature, '
      'time=$time'
      ']';
}

class DataInfo {
  final String name;
  final String unit;
  final int value;

  DataInfo({
    required this.name,
    required this.unit,
    required this.value,
  });

  static List<DataInfo> fromData(Data data) {
    return switch (data) {
      Data(:final humidity, :final light, :final moisture, :final temperature) =>
        [
          DataInfo(name: "Temperature", unit: '°C', value: temperature.round()),
          DataInfo(name: "Humidity", unit: '%', value: humidity),
          DataInfo(name: "Light", unit: 'lux', value: light),
          DataInfo(name: "Soil Moisture", unit: '%', value: moisture),
        ],
    };  
  }
  @override
  String toString() => '$name: $value $unit';

  String get displayValue => '$value $unit';
  String get displayName => name[0].toUpperCase() + name.substring(1);
}

void main() {
  Map<String, Object?> json = {
    'id': 1,
    'humidity': 50,
    'light': 100,
    'moisture': 30,
    'temperature': 25.5,
    'time': DateTime.now().toUtc().toString(),
  };

  final data = Data.fromJson(json);
  print(data);
}