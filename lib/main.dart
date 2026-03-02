import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'data.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Align(
            alignment: Alignment.center,
            child: Text('Plant Overview'),
          ),
        ),
        body: Center(
          child: SensorReadings(),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Container(
            height: 50,
            child: Center(
              child: Text('Buttons for navigation'),
            ),
          ),
        ) ,
      ),
    );
  }
}

class ReadingsModel {
  Future<Data> getData() async {
    final uri = Uri.https(
      'muc-server.onrender.com',
      '/data',
    );
    final response = await get(uri);

    if (response.statusCode != 200) {
      throw HttpException('Failed to update resource');
    }
    print(response.body);
    Data data = Data.fromJson(jsonDecode(response.body)["history"][0]);
    print(data);
    return data;
  }
}

class SensorReading extends StatelessWidget {
  const SensorReading(this.value, this.unit, this.label, {super.key});

  final double value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
          color: Colors.tealAccent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              "${value.toStringAsFixed(0)} $unit",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodyMedium), 
      ],   
    );
  }
}

class SensorReadings extends StatelessWidget {
  const SensorReadings({super.key});
  
  // TODO: Replace with actual sensor readings
  final List<SensorReading> _readings = const [
    SensorReading(23.5, '°C', "Temperature"),
    SensorReading(45.0, '%', "Humidity"),
    SensorReading(25.0, '%', "Soil Moisture"),
    SensorReading(10000.0, 'lux', "Light"),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Column(
        spacing: 30,
        children: [
          for (int i = 0; i < _readings.length; i += 2)
            Row(
              spacing: 50,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _readings[i],
                if (i + 1 < _readings.length) _readings[i + 1],
              ],
            ),
        ],
      ),
    );
  }
}