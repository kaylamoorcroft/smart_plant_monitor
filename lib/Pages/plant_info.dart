import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'dart:async';
import 'dart:convert';

import 'plant_care.dart';

class PlantInfoScreen extends StatefulWidget {
  const PlantInfoScreen({super.key});

  @override
  State<PlantInfoScreen> createState() => _InfoState();
}

class _InfoState extends State<PlantInfoScreen> {
  final PlantInfoModel m = PlantInfoModel();
  PlantCare? plantCare;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    m.getPlantCareInfo(1);
    m.searchPlants('monstera');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 10.0,
          children: [
            SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                return SearchBar(
                  controller: controller,
                  padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  onTap: () {
                    controller.openView();
                  },
                  onChanged: (_) {
                    controller.openView();
                  },
                  leading: const Icon(Icons.search),
                );
              },
              suggestionsBuilder:
                  (BuildContext context, SearchController controller) async {
                    final completer =
                        Completer<Iterable<Widget>>(); // holds response
                    _debounce?.cancel(); // cancel lookup delay if user typing
                    List<PlantInfo> plants = List<PlantInfo>.empty();
                    _debounce = Timer(
                      const Duration(milliseconds: 500),
                      () async {
                        try {
                          if (controller.text.isEmpty) {
                            completer.complete([]);
                            return;
                          }
                          plants = await m.searchPlants(controller.text);

                          final results = plants.map((plant) {
                            return ListTile(
                              title: Text(plant.commonName),
                              subtitle: Text(plant.scientificName),
                              onTap: () async {
                                PlantCare? curPlantCare = await m
                                    .getPlantCareInfo(plant.id);
                                setState(() {
                                  controller.closeView(plant.scientificName);
                                  plantCare = curPlantCare;
                                  print('plantid: ${plant.id}');
                                  print(plantCare);
                                });
                              },
                            );
                          });
                          completer.complete(results);
                        } catch (e) {
                          // Return an empty list or error widget on failure
                          completer.complete([
                            const ListTile(title: Text('No results found')),
                          ]);
                        }
                      },
                    );
                    return completer.future;
                  },
            ),
            PlantCareBox(plantCare),
          ],
        ),
      ),
    );
  }
}

class PlantCareBox extends StatelessWidget {
  const PlantCareBox(this.plantCareInfo, {super.key});

  final PlantCare? plantCareInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: plantCareInfo != null
          ? [
              Text(
                plantCareInfo!.commonName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                plantCareInfo!.scientificName,
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
              Text(
                plantCareInfo!.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  spacing: 5,
                  children: [
                    PlantCareRow('Sun', plantCareInfo!.sun, Icons.wb_sunny),
                    PlantCareRow('Growth Rate', 'Fast', Icons.park),
                    PlantCareRow('Care Level', 'Medium', Icons.local_florist),
                    PlantCareRow(
                      'Watering',
                      plantCareInfo!.watering,
                      Icons.water_drop,
                    ),
                    //if (plantCareInfo!.maintenance != null)
                    PlantCareRow(
                      'Maintenance',
                      plantCareInfo!.maintenance,
                      Icons.build,
                    ),
                  ],
                ),
              ),
            ]
          : [Text("No plant selected")],
    );
  }
}

class PlantCareRow extends StatelessWidget {
  const PlantCareRow(this.label, this.info, this.icon, {super.key});

  final String? info;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(spacing: 10, children: [Icon(icon), Text('$label: $info')]);
  }
}

class PlantInfoModel {
  final String baseUrl = 'perenual.com';
  final String key = 'sk-cqrb69d184abc303a16136'; // need to move this to .env
  Future<PlantCare?> getPlantCareInfo(int id) async {
    print('calling getPlantCareInfo with id $id');
    if (id < 1) return null;
    //final uri = Uri.https(baseUrl, '/api/v2/species/details/$id', {'key': key});
    try {
      print('making get request for plant care info...');
      //final response = await get(uri);
      // if (response.statusCode != 200) {
      //   throw HttpException('Failed to fetch plant data');
      // }
      Map<String, dynamic> jsonData = {
        "id": 1,
        "common_name": "European Silver Fir",
        "scientific_name": ["Abies alba"],
        "watering": "Frequent",
        "watering_general_benchmark": {"value": "\"7-10\"", "unit": "days"},
        "plant_anatomy": [],
        "sunlight": ["full sun"],
        "maintenance": null,
        "care_guides":
            "http://perenual.com/api/species-care-guide-list?species_id=1&key=sk-cqrb69d184abc303a16136",
        "soil": [],
        "growth_rate": "High",
        "tropical": false,
        "indoor": false,
        "care_level": "Medium",
        "description":
            "European Silver Fir (Abies alba) is an amazing coniferous species native to mountainous regions of central Europe and the Balkans. It is an evergreen tree with a narrow, pyramidal shape and long, soft needles. Its bark is scaly grey-brown and its branches are highly ornamental due to its conical-shaped silver-tinged needles. It is pruned for use as an ornamental evergreen hedging and screening plant, and is also popular for use as a Christmas tree. Young trees grow quickly and have strong, flexible branches which makes them perfect for use as windbreaks. The European Silver Fir is an impressive species, making it ideal for gardens and public spaces.",
      };

      // Encode Map to JSON string
      String jsonString = jsonEncode(jsonData);
      //print(jsonString);
      //PlantCare data = PlantCare.fromJson(jsonDecode(response.body));
      PlantCare data = PlantCare.fromJson(jsonDecode(jsonString));

      print('plant care info for plant with id $id');
      print(data);
      return data;
    } on ClientException {
      throw HttpException('Failed to load data');
    }
  }

  Future<List<PlantInfo>> searchPlants(String query) async {
    if (query.isEmpty) return [];
    // final uri = Uri.https(baseUrl, '/api/v2/species-list', {
    //   'key': key,
    //   'q': query,
    // });
    try {
      print('making get request for plant names...');
      // final response = await get(uri);
      // print(response.statusCode);
      // if (response.statusCode != 200) {
      //   throw HttpException('Failed to fetch plant data');
      // }
      Map<String, dynamic> jsonData = {
        "data": [
          {
            "id": 5257,
            "common_name": "Swiss cheese plant",
            "scientific_name": ["Monstera deliciosa"],
          },
          {
            "id": 5258,
            "common_name": "variegated Swiss cheese plant",
            "scientific_name": ["Monstera deliciosa 'Variegata'"],
          },
          {
            "id": 1,
            "common_name": "European Silver Fir",
            "scientific_name": ["Abies alba"],
          },
        ],
      };
      String jsonString = jsonEncode(jsonData);
      //final data = PlantInfo.fromJsonList(jsonDecode(response.body)['data']);
      final data = PlantInfo.fromJsonList(jsonDecode(jsonString)['data']);
      print(data);
      return data; // Returns the list of plant matches
    } on ClientException {
      throw HttpException('Failed to load data');
    }
  }
}
