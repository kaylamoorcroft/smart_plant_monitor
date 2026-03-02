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
          time: DateTime.parse(time).toLocal().toString(),
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
