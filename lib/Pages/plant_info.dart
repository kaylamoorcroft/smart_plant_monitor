import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'plant_care.dart';

class PlantInfoScreen extends StatefulWidget {
  const PlantInfoScreen({super.key});

  @override
  State<PlantInfoScreen> createState() => _InfoState();
}

class _InfoState extends State<PlantInfoScreen> {
  late final PlantInfoViewModel viewModel;
  int? plantId;
  Timer? _debounce;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    viewModel = PlantInfoViewModel(PlantInfoModel());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plant Info", style: Theme.of(context).textTheme.headlineMedium),
        actions: <Widget>[
          IconButton(
            onPressed: (){
              Navigator.pushNamed(context, '/settings');
            },
            icon: Icon(
              Icons.settings,
              size: 45.0,
            ),
          ),
        ],
      ),
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
                    // don't run api call if in process of closing suggestions
                    if (_isClosing) return [];
                    // If text is too short, return empty suggestions
                    if (controller.text.length < 2) {
                      return [
                        ListTile(
                          title: Center(
                            child: Text("Start typing to get suggestions..."),
                          ),
                        ),
                      ];
                    }
                    final completer =
                        Completer<Iterable<Widget>>(); // holds response
                    _debounce?.cancel(); // cancel lookup delay if user typing
                    _debounce = Timer(
                      const Duration(milliseconds: 700),
                      () async {
                        await viewModel.searchPlants(controller.text);
                        // there was an error
                        if (viewModel.plantInfoError != null) {
                          completer.complete([
                            ListTile(title: Text(viewModel.plantInfoError!)),
                          ]);
                        } else {
                          final results =
                              viewModel.plantInfo?.map(
                                (plant) => ListTile(
                                  title: Text(plant.commonName),
                                  subtitle: Text(plant.scientificName),
                                  onTap: () async {
                                    setState(() {
                                      _isClosing = true; // closing suggestions
                                      plantId = plant.id;
                                    });
                                    await viewModel.getPlantCareInfo(plant.id);
                                    controller.closeView(plant.scientificName);
                                    print('plantid: ${plant.id}');

                                    // Reset flag after tiny delay so next search works
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                      () {
                                        _isClosing = false;
                                      },
                                    );
                                  },
                                ),
                              ) ??
                              [ListTile(title: Text('No results found'))];
                          completer.complete(results);
                        }
                      },
                    );
                    return [
                      FutureBuilder<Iterable<Widget>>(
                        future: completer.future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            // finished loading, show list of tiles
                            return Column(
                              children:
                                  snapshot.data?.toList() ??
                                  [ListTile(title: Text('No results found'))],
                            );
                          }
                          // loading icon while timer runs
                          return const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ];
                  },
            ),
            //Text('plant id: $plantId'),
            ListenableBuilder(
              listenable: viewModel,
              builder: (context, child) {
                return switch ((
                  viewModel.careLoading,
                  viewModel.plantCare,
                  viewModel.plantCareError,
                )) {
                  (true, _, _) => Center(child: CircularProgressIndicator()),
                  (false, _, String message) => Center(child: Text(message)),
                  (false, null, null) => Center(
                    child: Text("No plant selected..."),
                  ),
                  // The data must be non-null in this switch case.
                  (false, PlantCare plantCare, null) => PlantCareBox(plantCare),
                };
              },
            ),
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
                    if (plantCareInfo!.growthRate != null)
                      PlantCareRow(
                        'Growth Rate',
                        plantCareInfo!.growthRate,
                        Icons.park,
                      ),
                    if (plantCareInfo!.careLevel != null)
                      PlantCareRow(
                        'Care Level',
                        plantCareInfo!.careLevel,
                        Icons.local_florist,
                      ),
                    if (plantCareInfo!.watering != null)
                      PlantCareRow(
                        'Watering',
                        plantCareInfo!.watering,
                        Icons.water_drop,
                      ),
                    if (plantCareInfo!.maintenance != null)
                      PlantCareRow(
                        'Maintenance',
                        plantCareInfo!.maintenance,
                        Icons.build,
                      ),
                  ],
                ),
              ),
            ]
          : [Text("No plant selected...")],
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
    final uri = Uri.https(baseUrl, '/api/v2/species/details/$id', {'key': key});
    try {
      print('making get request for plant care info...');
      final response = await get(uri);
      if (response.statusCode != 200) {
        throw HttpException('Failed to fetch plant data');
      }
      // Map<String, dynamic> jsonData = {
      //   "id": 1,
      //   "common_name": "European Silver Fir",
      //   "scientific_name": ["Abies alba"],
      //   "watering": "Frequent",
      //   "watering_general_benchmark": {"value": "\"7-10\"", "unit": "days"},
      //   "plant_anatomy": [],
      //   "sunlight": ["full sun"],
      //   "maintenance": null,
      //   "care_guides":
      //       "http://perenual.com/api/species-care-guide-list?species_id=1&key=sk-cqrb69d184abc303a16136",
      //   "soil": [],
      //   "growth_rate": "High",
      //   "tropical": false,
      //   "indoor": false,
      //   "care_level": "Medium",
      //   "description":
      //       "European Silver Fir (Abies alba) is an amazing coniferous species native to mountainous regions of central Europe and the Balkans. It is an evergreen tree with a narrow, pyramidal shape and long, soft needles. Its bark is scaly grey-brown and its branches are highly ornamental due to its conical-shaped silver-tinged needles. It is pruned for use as an ornamental evergreen hedging and screening plant, and is also popular for use as a Christmas tree. Young trees grow quickly and have strong, flexible branches which makes them perfect for use as windbreaks. The European Silver Fir is an impressive species, making it ideal for gardens and public spaces.",
      // };

      // Encode Map to JSON string
      //String jsonString = jsonEncode(jsonData);
      //print(jsonString);
      //PlantCare data = PlantCare.fromJson(jsonDecode(jsonString));

      PlantCare data = PlantCare.fromJson(jsonDecode(response.body));

      print('plant care info for plant with id $id');
      print(data);
      return data;
    } on ClientException {
      throw HttpException('Failed to load data');
    }
  }

  Future<List<PlantInfo>> searchPlants(String query) async {
    if (query.isEmpty) return [];
    final uri = Uri.https(baseUrl, '/api/v2/species-list', {
      'key': key,
      'q': query,
    });
    try {
      print('making get request for plant names...');
      final response = await get(uri);
      print(response.statusCode);
      if (response.statusCode != 200) {
        throw HttpException('Failed to fetch plant data');
      }

      // Map<String, dynamic> jsonData = {
      //   "data": [
      //     {
      //       "id": 5257,
      //       "common_name": "Swiss cheese plant",
      //       "scientific_name": ["Monstera deliciosa"],
      //     },
      //     {
      //       "id": 5258,
      //       "common_name": "variegated Swiss cheese plant",
      //       "scientific_name": ["Monstera deliciosa 'Variegata'"],
      //     },
      //     {
      //       "id": 1,
      //       "common_name": "European Silver Fir",
      //       "scientific_name": ["Abies alba"],
      //     },
      //   ],
      // };
      // String jsonString = jsonEncode(jsonData);
      // final data = PlantInfo.fromJsonList(jsonDecode(jsonString)['data']);

      final data = PlantInfo.fromJsonList(jsonDecode(response.body)['data']);
      print(data);
      return data; // Returns the list of plant matches
    } on ClientException {
      throw HttpException('Failed to load data');
    }
  }
}

class PlantInfoViewModel extends ChangeNotifier {
  final PlantInfoModel model;
  List<PlantInfo>? plantInfo;
  PlantCare? plantCare;
  String? plantInfoError;
  String? plantCareError;
  bool infoLoading = false;
  bool careLoading = false;

  PlantInfoViewModel(this.model);

  Future<void> searchPlants(String query) async {
    notifyListeners();
    infoLoading = true;
    try {
      plantInfo = await model.searchPlants(query);
      plantInfoError = null; // Clear any previous errors.
    } on HttpException catch (error) {
      plantInfoError = error.message;
      plantInfo = null;
    }
    infoLoading = false;
    notifyListeners();
  }

  Future<void> getPlantCareInfo(int plantId) async {
    notifyListeners();
    careLoading = true;
    try {
      plantCare = await model.getPlantCareInfo(plantId);
      plantCareError = null; // Clear any previous errors.
    } on HttpException catch (error) {
      plantCareError = error.message;
      plantCare = null;
    }
    careLoading = false;
    notifyListeners();
  }
}
