import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context){
    return Stack(
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(90, 40, 0, 0), //margin offset for days of week
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  WeekDay(day: "S"),
                  WeekDay(day: "M"),
                  WeekDay(day: "T"),
                  WeekDay(day: "W"),
                  WeekDay(day: "T"),
                  WeekDay(day: "F"),
                  WeekDay(day: "S"),
                ],
              )
            ),
          ],
        ),
        
        Positioned( //fix labels so not as to interfere with bubbles and days of week
          top: 110,
          left: 22,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              spacing: 24, // space between dividers and labels
              children: [
                Label(sensorType: "T"),
                Divider(height: 1, endIndent: 40,),
                Label(sensorType: "L"),
                Divider(height: 1, endIndent: 40,),
                Label(sensorType: "H"),
                Divider(height: 1, endIndent: 40,),
                Label(sensorType: "S"),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//Formatting for days of the week
class WeekDay extends StatelessWidget {
  final String day;
  const WeekDay({required this.day});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          child:
            Padding(
              padding: EdgeInsetsGeometry.only(bottom: 40),
              child:
                Text(day, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
        ),
        SensorValue(),
        SizedBox(height: 66),
        SensorValue(),
        SizedBox(height: 65),
        SensorValue(),
        SizedBox(height: 66),
        SensorValue(),
      ],
    );
  }
}

//Formatting for sensor label letters
class Label extends StatelessWidget {
  final String sensorType;
  const Label({required this.sensorType});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 86,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3), //label corners
            border: Border.all(color: Colors.grey),
          ),
          child: Center(child: Text(sensorType, style: TextStyle(fontSize: 28,))),
        ),
      ],
    );
  }
}

//Formatting for sensor reading bubbles
class SensorValue extends StatelessWidget {
  const SensorValue({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Padding(
      padding: const EdgeInsets.all(2),
      child:
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueGrey),
              color: const Color.fromARGB(255, 196, 233, 221),
            ),
            child: Center(child: Text("X")),
          ),
    );
  }
}