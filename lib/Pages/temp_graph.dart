import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'dart:io';
import '../data.dart';

class TemperatureGraph extends StatelessWidget {
  const TemperatureGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Temperature Graph'),
        backgroundColor: Colors.yellow[200],
      ),
      body: SensorView(),
    );
  }
}

class SensorModel {
  Future<List<DataSpot>> getData() async {
    final uri = Uri.https(
      'muc-server.onrender.com',
      '/data',
    );
    try {
      final response = await get(uri);
      if (response.statusCode != 200) {
        throw HttpException('Failed to update data');
      }
      List<DataSpot> dataToPlot = DataSpot.fromJsonList(jsonDecode(response.body));
      // for (DataSpot spot in dataToPlot) {
      //   print("${DataSpot.getFormattedTime(spot.timeInMillis)}: ${spot.temperature} °C");
      // }
      return dataToPlot;
    } on ClientException {
      throw HttpException('Failed to load data');
    }
  }
}

class SensorViewModel extends ChangeNotifier {
  final SensorModel model;
  List<DataSpot>? dataToPlot;
  String? errorMessage;
  bool loading = false;

  SensorViewModel(this.model) {
    print('Initializing SensorViewModel');
    getData();
  }

  Future<void> getData() async {
    notifyListeners();
    loading = true;
    try {
      dataToPlot = await model.getData();
      errorMessage = null; // Clear any previous errors.
    } on HttpException catch (error) {
      errorMessage = error.message;
      dataToPlot = null;
    }
    loading = false;
    notifyListeners();
  }

}

class SensorView extends StatelessWidget {
  SensorView({super.key});

  final SensorViewModel viewModel = SensorViewModel(SensorModel());

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return switch ((
          viewModel.loading,
          viewModel.dataToPlot,
          viewModel.errorMessage,
        )) {
          (true, _, _) => Center(child: CircularProgressIndicator()),
          (false, _, String message) => Center(child: Text(message)),
          (false, null, null) => Center(
            child: Text('An unknown error has occurred'),
          ),
          // The data must be non-null in this switch case.
          (false, List<DataSpot> dataToPlot, null) => SensorChart(
            data: dataToPlot.map((spot) => FlSpot(spot.timeInMillis, spot.temperature)).toList())
        };
      },
    );
  }
}

class SensorChart extends StatelessWidget {
  const SensorChart({super.key, required this.data});

  final List<FlSpot> data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0, right: 25.0, top: 10.0, bottom: 10.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double minX = data.map((spot) => spot.x).reduce((a, b) => a < b ? a : b);
          final double maxX = data.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);
          final double minY = data.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
          final double maxY = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
          // Calculate interval: e.g., show a label every 50 pixels
          double dynamicIntervalX = (maxX - minX) / (constraints.maxWidth / 50);
          double dynamicIntervalY = (maxY - minY) / (constraints.maxHeight / 50);

          return LineChart(
            LineChartData(
              minY: minY - (maxY-minY) * 0.1, // Add 10% padding below the minimum
              maxY: maxY + (maxY-minY) * 0.1, // Add 10% padding above the maximum
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: dynamicIntervalX, //3600000, // Optional: set interval in microseconds (e.g., 1 day) for titles
                    getTitlesWidget: (value, meta) {
                      if ((value > meta.max - (meta.appliedInterval * 0.5) && value != meta.max) 
                        || (value < meta.min + (meta.appliedInterval * 0.5) && value != meta.min)) {
                        return const SizedBox.shrink(); 
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 10.0,
                        angle: -0.5,
                        child: Text(DataSpot.getFormattedTime(value), style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                  axisNameWidget: const Text(
                    'Date and time',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  axisNameSize: 25,
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if ((value > meta.max - (meta.appliedInterval * 0.5) && value != meta.max) 
                        || (value < meta.min + (meta.appliedInterval * 0.5) && value != meta.min)) {
                        return const SizedBox.shrink(); 
                      }
                      // Return your custom widget for the labels
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          value.toStringAsFixed(1), // Convert the value to a fixed-point number with 1 decimal place
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                    reservedSize: 30,
                    interval: dynamicIntervalY,
                  ),
                  axisNameWidget: const Text(
                    'Temperature (˚C)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  axisNameSize: 25,
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: data,
                  isCurved: false,
                  barWidth: 4,
                  belowBarData: BarAreaData(show: true),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}