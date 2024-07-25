import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:planet_art_app/pages/explore/explore_detail_page.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _textController = TextEditingController();
  Timer? _debounce;
  // Control sessions
  var uuid = const Uuid();
  String _sessionToken = '1234567890';

  // Load API KEY from .env
  String PLACES_API_KEY = dotenv.env['API_KEY'] ?? 'No API key found';

  List<dynamic> _places = [];
  List<Map<String, String>> _photoUrlsWithNames = [];

  @override
  void initState() {
    super.initState();
    // _textController.addListener(_onChanged);
    getSuggestion();
  }

  @override
  void dispose() {
    _textController.dispose();
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 2000), () {
      if (_sessionToken == null) {
        setState(() {
          _sessionToken = uuid.v4();
        });
      }
      // getSuggestion(_textController.text);
    });
  }

  void getSuggestion() async {
    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=Museum%20Art&key=$PLACES_API_KEY&sessiontoken=$_sessionToken';
      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);

      if (kDebugMode) {
        print('mydata');
        print(data);
      }

      if (response.statusCode == 200) {
        setState(() {
          _places = data['predictions'];
        });

        if (_places.isNotEmpty) {
          var firstPlace = _places.first;
          await getPlaceDetails(
              firstPlace['place_id'], firstPlace['description']);
        }
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> getPlaceDetails(String placeID, String placeName) async {
    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/details/json';
      String request = '$baseURL?place_id=$placeID&key=$PLACES_API_KEY';
      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        var placeDetails = data['result'];
        var photos = placeDetails['photos'] ?? [];

        _photoUrlsWithNames.clear();
        for (var photo in photos) {
          var photoReference = photo['photo_reference'];
          if (photoReference != null) {
            var photoUrl = await getPlacePhoto(photoReference);
            if (photoUrl != null) {
              _photoUrlsWithNames.add({'url': photoUrl, 'name': placeName});
            }
          }
        }

        setState(() {});
      } else {
        throw Exception('Failed to load place details');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<String?> getPlacePhoto(String photoReference) async {
    try {
      String baseURL = 'https://maps.googleapis.com/maps/api/place/photo';
      String request =
          '$baseURL?maxwidth=400&photoreference=$photoReference&key=$PLACES_API_KEY';
      var response = await http.get(Uri.parse(request));

      if (response.statusCode == 200) {
        return response.request?.url.toString();
      } else {
        throw Exception('Failed to load photo');
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Explore Page'),
      ),
      body: Column(
        children: [
          // TextField(
          //   controller: _textController,
          //   decoration: InputDecoration(
          //     hintText: 'Search here',
          //     suffixIcon: IconButton(
          //       icon: const Icon(Icons.cancel_rounded),
          //       onPressed: () {
          //         _textController.clear();
          //       },
          //     ),
          //   ),
          // ),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  itemCount: _places.length,
                  itemBuilder: (context, index) {
                    var place = _places[index];
                    return ListTile(
                      title: Text(place['description']),
                      // onTap: () async {
                      //   await getPlaceDetails(
                      //       place['place_id'], place['description']);
                      // },
                    );
                  },
                ),
                if (_photoUrlsWithNames.isNotEmpty)
                  GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: _photoUrlsWithNames.length,
                    itemBuilder: (context, index) {
                      var item = _photoUrlsWithNames[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ExploreDetailPage(
                                        name: item['name']!,
                                        imageUrl: item['url']!,
                                      )));
                        },
                        child: Stack(
                          children: [
                            Image.network(
                              item['url']!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                            // Positioned(
                            //   bottom: 0,
                            //   left: 0,
                            //   right: 0,
                            //   child: Container(
                            //     color: Colors.black54,
                            //     padding: const EdgeInsets.all(8.0),
                            //     child: Text(
                            //       item['name']!,
                            //       style: const TextStyle(
                            //         color: Colors.white,
                            //         fontSize: 16,
                            //         fontWeight: FontWeight.bold,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
