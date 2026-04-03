import 'package:flutter/material.dart';

class PlantInfoScreen extends StatefulWidget {
  const PlantInfoScreen({super.key});

  @override
  State<PlantInfoScreen> createState() => _InfoState();
}

class _InfoState extends State<PlantInfoScreen> {
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Text('Official Plant Info page'),
    );
  }
}