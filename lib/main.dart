import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:smart_plant_monitor/all_libraries.dart';

import 'data.dart';
import 'theme.dart';
import 'util.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, "ABeeZee", "Poppins",);
    MaterialTheme theme = MaterialTheme(textTheme);
    return MaterialApp(
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      // initialRoute: '/',
      routes: {
        '/': (context) => DataScreen(), //replace home: DataScreen(),
        '/sensorGraph': (context) => SensorGraph(),
      }
    );
  }
}

// Model-View-ViewModel (MVVM) architecture
// ReadingModel gets data from API
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

// ReadingViewModel manages the state of the data and notifies listeners when it changes.
// It also handles the logic of fetching data and error handling.
class ReadingViewModel extends ChangeNotifier {
  final ReadingModel model;
  Data? data;
  String? errorMessage;
  bool loading = true;

  ReadingViewModel(this.model) {
    print('Initializing ReadingViewModel');
  }

  Future<void> getData() async {
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

// home page design
class SensorPage extends StatelessWidget {
  const SensorPage({
    super.key,
    required this.dataInfo,
    required this.lastUpdatedTime,
  });

  final List<DataInfo> dataInfo;
  final String lastUpdatedTime;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 60.0),
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
        ),
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
    );
  }
}

// Widget to display individual sensor readings ("tile")
class SensorReading extends StatelessWidget {
  const SensorReading(this.dataInfo, {super.key});

  final DataInfo dataInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: () {
            Navigator.pushNamed(context, '/sensorGraph', 
              arguments: GraphArguments(
                title: '${dataInfo.name} Graph',
                field: dataInfo.sensorLabel,
                yLabel: '${dataInfo.name} (${dataInfo.unit})',
                latestTime: dataInfo.time,
              ),
            );
          },
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
            color: switch(dataInfo.condition){
              Condition.good => const Color.fromARGB(255, 0, 187, 119),
              Condition.warning => const Color.fromARGB (255, 247, 230, 100),
              Condition.critical => Colors.deepOrange[700],
              _ => Colors.grey[200], //default if not matching a specific condition
            },
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: Text(
                dataInfo.displayValue,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
          Text(dataInfo.displayName, style: Theme.of(context).textTheme.bodyMedium), 
        ],
    );
  }
}

// DataScreen is the main screen that displays the sensor data. It uses a timer to periodically fetch new data and updates the UI accordingly.
class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  _DataScreenState createState() => _DataScreenState();
}


class _DataScreenState extends State<DataScreen> {
  List<DataInfo> _dataInfo = [DataInfo(name: 'Loading...', unit: '', value: 0, condition: Condition.unknown, time: "0000-00-00 00:00:00")];
  int prevId = -1;
  late Timer _timer;
  String lastUpdatedTime = "0000-00-00 00:00:00";
  final ReadingViewModel viewModel = ReadingViewModel(ReadingModel());

  @override
  void initState() {
    super.initState();
    _fetchData(); // Initial call
    _timer = Timer.periodic(Duration(seconds: 15), (timer) => _fetchData());
  }

  Future<void> _fetchData() async {
    await viewModel.getData();
    if (viewModel.data != null) {
      List<DataInfo> newDataInfo = DataInfo.fromData(viewModel.data!);
      if (viewModel.data!.id != prevId) {
        print(newDataInfo); // Temporary
        lastUpdatedTime = viewModel.data!.time;
        setState(() {
          _dataInfo = newDataInfo;
          prevId = viewModel.data!.id;
        });
      }
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
      // backgroundColor: const Color.fromARGB(255, 238, 243, 246),
      appBar: AppBar(
        // backgroundColor: const Color.fromARGB(255, 131, 150, 169),
        // foregroundColor: Colors.white,
        title: Text('Plant Overview', style: Theme.of(context).textTheme.headlineMedium),
        actions: <Widget>[
          IconButton(
            onPressed: (){},
            icon: Icon(
              Icons.settings,
              size: 45.0,
              // color: Colors.lightBlue[800],
            ),
          ),
        ],
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
            // The data must be non-null in this switch case.
            (false, Data _, null) => SensorPage(
              dataInfo: _dataInfo, 
              lastUpdatedTime: lastUpdatedTime
            ),
          };
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        // backgroundColor: const Color.fromARGB(255, 131, 150, 169),
        // fixedColor: Colors.white,
        // unselectedItemColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Plant Info'),
        ],
      ) ,
    );
  }
}