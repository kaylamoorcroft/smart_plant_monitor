import 'dart:convert';
import 'dart:io';
import 'dart:async';

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
      home: DataScreen(),
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
      Data data = Data.fromJson(jsonDecode(response.body));
      return data;
    } on ClientException {
      throw HttpException('Failed to load data');
    }
  }
}

// class ReadingViewModel extends ChangeNotifier {
//   final ReadingModel model;
//   Data? data;
//   String? errorMessage;
//   bool loading = false;

//   ReadingViewModel(this.model) {
//     getData();
//   }

//   Future<void> getData() async {
//     loading = true;
//     notifyListeners();
//     try {
//       data = await model.getData();
//       print('Data loaded: ${data!.toString()}'); // Temporary
//       errorMessage = null; // Clear any previous errors.
//     } on HttpException catch (error) {
//       errorMessage = error.message;
//       data = null;
//     }
//     loading = false;
//     notifyListeners();
//   }

// }

// class ReadingView extends StatelessWidget {
//   ReadingView({super.key});

//   final ReadingViewModel viewModel = ReadingViewModel(ReadingModel());

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Plant Overview'),
//         actions: [],
//       ),
//       body: ListenableBuilder(
//         listenable: viewModel,
//         builder: (context, child) {
//           return switch ((
//             viewModel.loading,
//             viewModel.data,
//             viewModel.errorMessage,
//           )) {
//             (true, _, _) => Center(child: CircularProgressIndicator()),
//             (false, _, String message) => Center(child: Text(message)),
//             (false, null, null) => Center(
//               child: Text('An unknown error has occurred'),
//             ),
//             // The summary must be non-null in this switch case.
//             (false, Data data, null) => SensorPage(
//               dataInfo: DataInfo.fromData(data),
//               //reloadDataCallback: viewModel.getData,
//             ),
//           };
//         },
//       ),
//       bottomNavigationBar: BottomAppBar(
//         child: Container(
//           height: 50,
//           child: Center(
//             child: Text('Buttons for navigation'),
//           ),
//         ),
//       ) ,
//     );
//   }
// }

class SensorPage extends StatelessWidget {
  const SensorPage({
    super.key,
    required this.dataInfo,
  });

  final List<DataInfo> dataInfo;
  
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
          color: Colors.tealAccent, // TODO: Change color based on condition
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

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  List<DataInfo> _dataInfo = [DataInfo(name: 'Loading...', unit: '', value: 0, condition: Condition.unknown)];
  int prevId = -1;
  late Timer _timer;
  String lastUpdatedTime = "0000-00-00 00:00:00";
  ReadingModel model = ReadingModel();

  @override
  void initState() {
    super.initState();
    _fetchData(); // Initial call
    _timer = Timer.periodic(Duration(seconds: 15), (timer) => _fetchData());
  }

  Future<void> _fetchData() async {
    Data newData= await model.getData();
    List<DataInfo> newDataInfo = DataInfo.fromData(newData);
    if (newData.id != prevId) {
      print(newDataInfo); // Temporary
      lastUpdatedTime = newData.time;
      setState(() {
        _dataInfo = newDataInfo;
        prevId = newData.id;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Critical to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Overview'),
        actions: [],
      ),
      body: Column(
        children: [
          SensorPage(dataInfo: _dataInfo),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
                children: [
                Text("Last Updated:", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(lastUpdatedTime, style: Theme.of(context).textTheme.bodyMedium),
                ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50,
          child: Center(
            child: Text('Buttons for navigation'),
          ),
        ),
      ),
    );
  }
}