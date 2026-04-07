import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../data.dart';

class GraphArguments {
  final String field;
  final String yLabel;
  final String title;
  final String latestTime;

  GraphArguments({
    required this.field,
    required this.yLabel,
    required this.title,
    required this.latestTime,
  });
}

class SensorGraph extends StatelessWidget {
  const SensorGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as GraphArguments;
    return Scaffold(
      appBar: AppBar(
        title: Text(args.title),
        // backgroundColor: Colors.yellow[200],
      ),
      body: SensorView(args),
    );
  }
}

class SensorModel {
  Future<List<DataSpot>> getData(String field, String latestTime) async {
    // Get date and time of last reading, subtract 1 day, and format to "YYYY-MM-DD HH:MM:SS"
    final String startDate = DateTime.parse(latestTime)
        .subtract(Duration(days: 1))
        .toString()
        .split('.')
        .first
        .replaceAll(' ', 'T');
    final uri = Uri.https('muc-server.onrender.com', '/data/$field', {
      'startDate': startDate,
    });
    try {
      final response = await get(uri);
      if (response.statusCode != 200) {
        throw HttpException('Failed to update data');
      }
      List<DataSpot> dataToPlot = DataSpot.fromJsonList(
        jsonDecode(response.body),
        field,
      );
      return dataToPlot;
    } on ClientException {
      throw HttpException('Failed to load data');
    }
  }
}

class SensorViewModel extends ChangeNotifier {
  final SensorModel model;
  final String field;
  final String latestTime;
  List<DataSpot>? dataToPlot;
  String? errorMessage;
  bool loading = false;

  SensorViewModel(this.model, this.field, this.latestTime) {
    getData();
  }

  Future<void> getData() async {
    notifyListeners();
    loading = true;
    try {
      dataToPlot = await model.getData(field, latestTime);
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
  final GraphArguments args;
  late final SensorViewModel viewModel;

  SensorView(this.args, {super.key}) {
    viewModel = SensorViewModel(SensorModel(), args.field, args.latestTime);
  }

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
            yLabel: args.yLabel,
            data: dataToPlot
                .map((spot) => FlSpot(spot.timeInMillis, spot.value))
                .toList(),
          ),
        };
      },
    );
  }
}

class SensorChart extends StatelessWidget {
  const SensorChart({super.key, required this.data, required this.yLabel});

  final List<FlSpot> data;
  final String yLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 5.0,
        right: 25.0,
        top: 10.0,
        bottom: 10.0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double minX = data
              .map((spot) => spot.x)
              .reduce((a, b) => a < b ? a : b);
          double maxX = data
              .map((spot) => spot.x)
              .reduce((a, b) => a > b ? a : b);
          double minY = data
              .map((spot) => spot.y)
              .reduce((a, b) => a < b ? a : b);
          double maxY = data
              .map((spot) => spot.y)
              .reduce((a, b) => a > b ? a : b);
          maxY = (minY == maxY) ? maxY + 1 : maxY;
          maxX = (minX == maxX) ? maxX + 1 : maxX;
          // Calculate interval: e.g., show a label every 50 pixels
          double dynamicIntervalX = (maxX - minX) / (constraints.maxWidth / 50);
          double dynamicIntervalY =
              (maxY - minY) / (constraints.maxHeight / 50);
          // Prevent intervals smaller than 1 to avoid rounding duplicates
          dynamicIntervalY = dynamicIntervalY < 1
              ? yLabel[0] == 'T'
                    ? // finer grain for temperature
                      dynamicIntervalY < 0.1
                          ? 0.1
                          : dynamicIntervalY
                    : dynamicIntervalY < 0.5
                    ? 0.5
                    : 1
              : dynamicIntervalY;

          return LineChart(
            LineChartData(
              minY:
                  minY -
                  (maxY - minY) * 0.1, // Add 10% padding below the minimum
              maxY:
                  maxY +
                  (maxY - minY) * 0.1, // Add 10% padding above the maximum
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: dynamicIntervalX,
                    getTitlesWidget: (value, meta) {
                      if ((value > meta.max - (meta.appliedInterval * 0.5) &&
                              value != meta.max) ||
                          (value < meta.min + (meta.appliedInterval * 0.5) &&
                              value != meta.min)) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 10.0,
                        angle: -0.5,
                        child: Text(
                          DataSpot.getFormattedTime(value),
                          style: const TextStyle(fontSize: 10),
                        ),
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
                      if ((value > meta.max - (meta.appliedInterval * 0.5) &&
                              value != meta.max) ||
                          (value < meta.min + (meta.appliedInterval * 0.5) &&
                              value != meta.min)) {
                        return const SizedBox.shrink();
                      }
                      // Return custom widget for the labels
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          (yLabel[0] == 'T' || dynamicIntervalY < 1)
                              ? value.toStringAsFixed(1)
                              : value.toStringAsFixed(
                                  0,
                                ), // Show 1 decimal for temperature, 0 for others
                          style: const TextStyle(
                            // color: Colors.black,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                    reservedSize: yLabel[0] == 'L'
                        ? 45
                        : 30, // more space for light sensor values
                    interval: dynamicIntervalY,
                  ),
                  axisNameWidget: Text(
                    yLabel,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  axisNameSize: 25,
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              // custom tooltip to have time & val
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  maxContentWidth: 146,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((LineBarSpot barSpot) {
                      String datetime = DataSpot.getFormattedTime(barSpot.x);
                      String time = datetime.split(' ')[1];
                      String dataType = yLabel.split('(')[0].trimRight();
                      String unit = yLabel
                          .substring(0, yLabel.length - 1)
                          .split('(')[1];
                      String val = (yLabel[0] == 'T' || dynamicIntervalY < 1)
                          ? barSpot.y.toStringAsFixed(1)
                          : barSpot.y.toStringAsFixed(0);
                      // Show 1 decimal for temperature, 0 for others
                      return LineTooltipItem(
                        'Time: $time \n$dataType: $val $unit',
                        TextStyle(
                          // Use the line's color to match style
                          color: barSpot.bar.color ?? Colors.white,
                          fontWeight: FontWeight.bold, // Standard bold style
                          fontSize: 14, // Standard size
                        ),
                      );
                    }).toList();
                  },
                ),
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
        },
      ),
    );
  }
}
