import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:smart_plant_monitor/data.dart';

/// Main history page
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryState();
}

/// Controls loading / error / data display for history page
class _HistoryState extends State<HistoryScreen> {
  late final DayAverageViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = DayAverageViewModel(DayAverageModel());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return switch ((
          viewModel.loading,
          viewModel.data,
          viewModel.errorMessage,
        )) {
          (true, _, _) => Center(child: CircularProgressIndicator()),
          (false, _, String message) => Center(child: Text(message)),
          (false, null, null) => Center(
            child: Text('An unknown error has occurred'),
          ),
          // The data must be non-null in this switch case.
          (false, List<DayAverage> data, null) => HistoryInfo(data: data),
        };
      },
    );
  }
}

/// structure for history page bubbles
class HistoryInfo extends StatelessWidget {
  final List<DayAverage> data;

  const HistoryInfo({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "History",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: Icon(Icons.settings, size: 45.0),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(
                  70,
                  40,
                  0,
                  0,
                ), //margin offset for days of week
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: data.map((entry) {
                    return WeekDay(
                      day: entry.weekday, // The key from your map
                      hum: entry.humidity,
                      temp: entry.temperature,
                      light: entry.light,
                      moisture: entry.moisture,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          Positioned(
            //fix labels so not as to interfere with bubbles and days of week
            top: 98,
            left: 14,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                spacing: 24, // space between dividers and labels
                children: [
                  Label(icon: Icons.thermostat, label: "temp"),
                  Divider(height: 1, endIndent: 25),
                  Label(icon: Icons.wb_sunny, label: "light"),
                  Divider(height: 1, endIndent: 25),
                  Label(icon: Icons.dew_point, label: "hum"),
                  Divider(height: 1, endIndent: 25),
                  Label(icon: Icons.water_drop, label: "soil"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formatting for days of the week
class WeekDay extends StatelessWidget {
  final String day;
  final DataInfo? temp;
  final DataInfo? hum;
  final DataInfo? light;
  final DataInfo? moisture;
  const WeekDay({
    super.key,
    required this.day,
    this.temp,
    this.hum,
    this.light,
    this.moisture,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          child: Padding(
            padding: EdgeInsetsGeometry.only(bottom: 40),
            child: Text(
              day,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SensorValue(val: temp),
        SizedBox(height: 76),
        SensorValue(val: light),
        SizedBox(height: 72),
        SensorValue(val: hum),
        SizedBox(height: 74),
        SensorValue(val: moisture),
      ],
    );
  }
}

/// Formatting for sensor label letters
class Label extends StatelessWidget {
  final IconData icon;
  final String label;
  const Label({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
          width: 45,
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3), //label corners
            border: Border.all(color: Colors.grey),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 3,
            children: [
              Icon(icon, size: 28),
              Text(label, style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Smaller sensor reading bubbles for history page
class SensorValue extends StatelessWidget {
  const SensorValue({this.val, super.key});

  final DataInfo? val;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blueGrey),
          color: switch (val?.condition) {
            Condition.good => const Color.fromARGB(255, 0, 187, 119),
            Condition.warning => const Color.fromARGB(255, 247, 230, 100),
            Condition.critical => Colors.deepOrange[700],
            _ =>
              Colors.grey[300], //default if not matching a specific condition
          },
        ),
        child: Center(child: Text(val == null ? '---' : val!.value.toString())),
      ),
    );
  }
}

/// Data for day averages for last week
class DayAverageModel {
  //Future<List<DataDayAverage>> getData() async {
  Future<List<DayAverage>> getData() async {
    // Get date and time of today, subtract 7 day, and format to "YYYY-MM-DD"
    final String startDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(Duration(days: 7)));
    print('1 week ago: $startDate');

    final uri = Uri.https('muc-server.onrender.com', '/data', {
      'startDate': startDate, // TODO: add this param to server
    });

    try {
      final response = await get(uri);
      if (response.statusCode != 200) {
        throw HttpException('Failed to update data');
      }
      List<Map<String, Object?>> json = (jsonDecode(response.body) as List)
          .cast<Map<String, dynamic>>(); // cast to correct type to avoid error
      List<DayAverage> data = DayAverage.getDailyAverages(
        json.map((d) => Data.fromJson(d)).toList(),
      );
      if (data.length < 7) {
        DayAverage.fillMissingDays(data);
      }
      print(data);
      return data;
    } on ClientException {
      throw HttpException('Failed to load data');
    }
  }
}

/// Determine what will be displayed for data averages
class DayAverageViewModel extends ChangeNotifier {
  final DayAverageModel model;
  List<DayAverage>? data;
  String? errorMessage;
  bool loading = false;

  DayAverageViewModel(this.model) {
    getData();
  }

  Future<void> getData() async {
    notifyListeners();
    loading = true;
    try {
      data = await model.getData();
      errorMessage = null; // Clear any previous errors.
    } on HttpException catch (error) {
      errorMessage = error.message;
      data = null;
    }
    loading = false;
    notifyListeners();
  }
}
