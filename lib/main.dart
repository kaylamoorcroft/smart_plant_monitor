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
      home: ReadingView(),
    );
  }
}

class ReadingModel {
  Future<Data> getData() async {
    final uri = Uri.https(
      'muc-server.onrender.com',
      '/data/latest',
    );
    try {
      final response = await get(uri);
      if (response.statusCode != 200) {
        throw HttpException('Failed to update data');
      }
      print("json response: ${response.body}");
      Data data = Data.fromJson(jsonDecode(response.body));
      return data;
    } on ClientException {
      throw HttpException('Failed to load data');
    }
  }
}

class ReadingViewModel extends ChangeNotifier {
  final ReadingModel model;
  Data? data;
  String? errorMessage;
  bool loading = false;

  ReadingViewModel(this.model) {
    getData();
  }

  Future<void> getData() async {
    loading = true;
    notifyListeners();
    try {
      data = await model.getData();
      print('Data loaded: ${data!.toString()}'); // Temporary
      errorMessage = null; // Clear any previous errors.
    } on HttpException catch (error) {
      errorMessage = error.message;
      data = null;
    }
    loading = false;
    notifyListeners();
  }

}

class ReadingView extends StatelessWidget {
  ReadingView({super.key});

  final ReadingViewModel viewModel = ReadingViewModel(ReadingModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Overview'),
        actions: [],
      ),
      body: ListenableBuilder(
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
            // The summary must be non-null in this switch case.
            (false, Data data, null) => SensorPage(
              dataInfo: DataInfo.fromData(data),
              reloadDataCallback: viewModel.getData,
            ),
          };
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50,
          child: Center(
            child: Text('Buttons for navigation'),
          ),
        ),
      ) ,
    );
  }
}

class SensorPage extends StatelessWidget {
  const SensorPage({
    super.key,
    required this.dataInfo,
    required this.reloadDataCallback,
  });

  final List<DataInfo> dataInfo;
  final VoidCallback reloadDataCallback;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Column(
        spacing: 30,
        children: [
          for (int i = 0; i < dataInfo.length; i += 2)
            Row(
              spacing: 50,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SensorReading(dataInfo[i]),
                if (i + 1 < dataInfo.length) SensorReading(dataInfo[i + 1]),
              ],
            ),
          ElevatedButton(
            onPressed: reloadDataCallback,
            child: Text('Reload Data'),
          ),
        ],
      ),
    );
  }
}

class SensorReading extends StatelessWidget {
  const SensorReading(this.dataInfo, {super.key});

  final DataInfo dataInfo;

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
              dataInfo.displayValue,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        Text(dataInfo.displayName, style: Theme.of(context).textTheme.bodyMedium), 
      ],   
    );
  }
}