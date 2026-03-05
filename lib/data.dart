enum Condition { good, warning, critical, unknown }

class Data {
  /// Returns a new [Data] instance.
  Data({
    required this.id,
    required this.humidity,
    required this.light,
    required this.moisture,
    required this.temperature,
    required this.time,
  });

  int id;
  int humidity;
  int light;
  int moisture;
  double temperature;
  String time;

  /// Returns a new [Summary] instance
  static Data fromJson(Map<String, Object?> json) {
    return switch (json) {
      { 
        'id': final int id,
        'humidity': final int humidity,
        'light': final int light,
        'moisture': final int moisture,
        'temperature': final double temperature,
        'time': final String time,
      } => 
        Data(
          id: id,
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
  final Condition condition;

  DataInfo({
    required this.name,
    required this.unit,
    required this.value,
    required this.condition,
  });

  static List<DataInfo> fromData(Data data) {
    return switch (data) {
      Data(:final humidity, :final light, :final moisture, :final temperature) =>
        [
          DataInfo(name: "Temperature", unit: '°C', value: temperature.round(), condition: DataUtils.getCondition('temperature', temperature.round())),
          DataInfo(name: "Humidity", unit: '%', value: humidity, condition: DataUtils.getCondition('humidity', humidity)),
          DataInfo(name: "Light", unit: 'lux', value: light, condition: DataUtils.getCondition('light', light)),
          DataInfo(name: "Soil Moisture", unit: '%', value: moisture, condition: DataUtils.getCondition('moisture', moisture)),
        ],
    };  
  }
  @override
  String toString() => '$name: $value $unit (${condition.toString().split(".").last})';

  String get displayValue => '$value $unit';
  String get displayName => name[0].toUpperCase() + name.substring(1);
}

class DataUtils {
  static Condition getCondition(String sensorType, int value) {
    switch (sensorType) {
      case 'temperature':
        if (value < 15) return Condition.critical;
        if (value < 20) return Condition.warning;
        if (value <= 30) return Condition.good;
        if (value > 45) return Condition.critical;
        return Condition.warning;
      case 'humidity':
        if (value < 30) return Condition.critical;
        if (value < 50) return Condition.warning;
        if (value <= 70) return Condition.good;
        return Condition.warning;
      case 'light':
        if (value < 200) return Condition.critical;
        if (value < 500) return Condition.warning;
        if (value <= 1000) return Condition.good;
        return Condition.warning;
      case 'moisture':
        if (value < 20) return Condition.critical;
        if (value < 40) return Condition.warning;
        if (value <= 60) return Condition.good;
        return Condition.warning;
      default:
        return Condition.unknown;
    }
  }
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