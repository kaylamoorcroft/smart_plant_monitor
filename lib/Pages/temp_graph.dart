import 'package:flutter/material.dart';

class TemperatureGraph extends StatelessWidget {
  const TemperatureGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Temperature Graph'),
        backgroundColor: Colors.yellow[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text('Temperature Graph here.'),
      ),
    );
  }
}