import 'package:intl/intl.dart';

enum Condition { good, warning, critical, unknown }

/// data from the `/data` route on server
class Data {
  /// Returns a new `Data` instance.
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

  /// Returns a new [Data] instance
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
          time: (time).replaceAll(
            'T',
            ' ',
          ), //.split('.').first, // Format to "YYYY-MM-DD HH:MM:SS"
        ),
      _ => throw FormatException('Could not deserialize Data, json=$json'),
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

/// Same format as `Data` but for containing average values (possibly empty),
/// along with the abbreviation for the weekday, eg. 'Mon'
class DayAverage {
  DayAverage({
    this.humidity,
    this.light,
    this.moisture,
    this.temperature,
    required this.weekday,
  });

  DataInfo? humidity;
  DataInfo? light;
  DataInfo? moisture;
  DataInfo? temperature;
  String weekday;

  static List<DayAverage> getDailyAverages(List<Data> data) {
    // group data by day
    Map<String, List<Data>> dayData = {};
    for (Data d in data) {
      DateTime time = DateTime.parse(d.time);
      String date = DateFormat('yyyy-MM-dd').format(time);
      dayData.putIfAbsent(date, () => []); // add date to list / ignore key
      dayData[date]!.add(d); // add current data point to array
    }
    // calculate averages
    return dayData.entries.map((entry) {
      int count = entry.value.length;
      double avgTemp =
          entry.value.map((v) => v.temperature).reduce((a, b) => a + b) / count;
      double avgHum =
          entry.value.map((v) => v.humidity).reduce((a, b) => a + b) / count;
      double avgMoisture =
          entry.value.map((v) => v.moisture).reduce((a, b) => a + b) / count;
      double avgLight =
          entry.value.map((v) => v.light).reduce((a, b) => a + b) / count;

      return DayAverage(
        humidity: DataInfo(
          name: "Humidity",
          unit: '%',
          value: avgHum.round(),
          condition: DataUtils.getCondition('humidity', avgHum.round()),
          time: entry.key,
        ),
        light: DataInfo(
          name: "Light",
          unit: 'lux',
          value: avgLight.round(),
          condition: DataUtils.getCondition('light', avgLight.round()),
          time: entry.key,
        ),
        temperature: DataInfo(
          name: "Temperature",
          unit: '°C',
          value: avgTemp.round(),
          condition: DataUtils.getCondition('temperature', avgTemp.round()),
          time: entry.key,
        ),
        moisture: DataInfo(
          name: "Moisture",
          unit: '%',
          value: avgMoisture.round(),
          condition: DataUtils.getCondition('moisture', avgMoisture.round()),
          time: entry.key,
        ),
        weekday: DateFormat('E').format(DateTime.parse(entry.key)),
      );
    }).toList();
  }

  /// if there non-consecutive days, fill the gaps in the middle or
  /// start with the corresponding weekdays but null values for data
  static void fillMissingDays(List<DayAverage> data) {
    if (data.isEmpty) return;

    final List<String> weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    // address gaps between dates
    for (int i = 0; i < data.length - 1; i++) {
      int currIdx = weekdays.indexOf(data[i].weekday);
      int nextIdx = weekdays.indexOf(data[i + 1].weekday);

      // Calculate forward distance between days (including wrap around)
      int diff = (nextIdx - currIdx + 7) % 7;

      if (diff > 1) {
        // Fill the gaps
        for (int j = 1; j < diff; j++) {
          int missingIdx = (currIdx + j) % 7;
          data.insert(i + 1, DayAverage(weekday: weekdays[missingIdx]));
        }
      }
    }
    // address missing data at start of list
    while (data.length < 7) {
      int currIdx = weekdays.indexOf(data[0].weekday);
      int missingIdx = (currIdx - 1) % 7;
      data.insert(0, DayAverage(weekday: weekdays[missingIdx]));
    }
  }

  @override
  String toString() {
    return '\n-- $weekday --'
        '\n$light'
        '\n$moisture'
        '\n$temperature'
        '\n$humidity';
  }
}

/// Detailed info for a single `Data` field - adds condition, name and unit
class DataInfo {
  final String name;
  final String unit;
  final int value;
  final Condition condition;
  final String time;

  DataInfo({
    required this.name,
    required this.unit,
    required this.value,
    required this.condition,
    required this.time,
  });

  static List<DataInfo> fromData(Data data) {
    return switch (data) {
      Data(
        :final humidity,
        :final light,
        :final moisture,
        :final temperature,
        :final time,
      ) =>
        [
          DataInfo(
            name: "Temperature",
            unit: '°C',
            value: temperature.round(),
            condition: DataUtils.getCondition(
              'temperature',
              temperature.round(),
            ),
            time: time,
          ),
          DataInfo(
            name: "Humidity",
            unit: '%',
            value: humidity,
            condition: DataUtils.getCondition('humidity', humidity),
            time: time,
          ),
          DataInfo(
            name: "Light",
            unit: 'lux',
            value: light,
            condition: DataUtils.getCondition('light', light),
            time: time,
          ),
          DataInfo(
            name: "Soil Moisture",
            unit: '%',
            value: moisture,
            condition: DataUtils.getCondition('moisture', moisture),
            time: time,
          ),
        ],
    };
  }

  @override
  String toString() =>
      '$name: $value $unit (${condition.toString().split(".").last})';

  String get displayValue => '$value $unit';
  String get sensorLabel => name.substring(name.indexOf(' ') + 1).toLowerCase();
  String get displayName => name[0].toUpperCase() + name.substring(1);
}

/// Formatted data to be displayed on graphs plus other functionality for formatting
class DataSpot {
  DataSpot({required this.value, required this.timeInMillis});

  final double value;
  final double timeInMillis;

  static String getFormattedTime(double millis) {
    DateTime datetime = DateTime.fromMillisecondsSinceEpoch(millis.toInt());
    return DateFormat.Md().add_Hm().format(datetime); // e.g., "1/1 13:00"
  }

  static DataSpot _fromJson(Map<String, Object?> json, String field) {
    final value = (json[field] as num).toDouble();
    final time = json['time'] as String;

    return DataSpot(
      value: value,
      timeInMillis: DateTime.parse(time).millisecondsSinceEpoch.toDouble(),
    );
  }

  static List<DataSpot> fromJsonList(List<dynamic> jsonList, String field) {
    return jsonList
        .map((item) => DataSpot._fromJson(item as Map<String, Object?>, field))
        .toList();
  }

  @override
  String toString() =>
      'DataSpot[time=${getFormattedTime(timeInMillis)}, value=$value]';
}

/// Static class for any additional `Data` manipulation needed
class DataUtils {
  /// get the condition based on standard thresholds for plant sensor values
  static Condition getCondition(String sensorType, int value) {
    switch (sensorType) {
      case 'temperature':
        if (value < 13) return Condition.critical;
        if (value < 18) return Condition.warning;
        if (value <= 24) return Condition.good;
        if (value > 28) return Condition.critical;
        return Condition.warning;
      case 'humidity':
        if (value < 30) return Condition.critical;
        if (value < 40) return Condition.warning;
        if (value <= 60) return Condition.good;
        if (value > 70) return Condition.critical;
        return Condition.warning;
      case 'light':
        if (value < 230) return Condition.critical;
        if (value < 460) return Condition.warning;
        if (value <= 1000) return Condition.good;
        return Condition.warning;
      case 'moisture':
        if (value <= 10) return Condition.critical;
        if (value < 21) return Condition.warning;
        if (value <= 40) return Condition.good;
        if (value >= 80) return Condition.critical;
        return Condition.warning;
      default:
        return Condition.unknown;
    }
  }
}
