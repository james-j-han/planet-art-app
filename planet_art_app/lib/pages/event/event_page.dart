import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final _textController = TextEditingController();

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
    _textController.addListener(_onTextChanged);
    getSuggestion();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {}

  void getSuggestion() async {
    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=Museum%20Art&key=$PLACES_API_KEY&sessiontoken=$_sessionToken';
      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);

      // if (kDebugMode) {
      //   print('mydata');
      //   print(data);
      // }

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
        backgroundColor: Colors.deepPurple,
        leading: const Icon(
          Icons.android_rounded,
          color: Colors.white,
        ),
        title: TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'Search anything',
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            filled: true,
            fillColor: Colors.white24,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.clear_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _textController.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs or categories
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Upcoming',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Calendar',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _photoUrlsWithNames.length, // Use actual data length
              itemBuilder: (context, index) {
                var item = _photoUrlsWithNames[index];
                var imageUrl = item['url'];
                var name = item['name'];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Container(
                    height: 400.0, // Set the desired fixed height here
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          imageUrl ?? 'https://via.placeholder.com/400x200',
                          fit: BoxFit.cover,
                          height:
                              250.0, // Adjust this height according to your layout
                          width: double.infinity,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name ?? 'Art Exhibition',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                const Expanded(
                                  child: Text(
                                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
                                    style: TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2, // Limit number of lines
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            'https://via.placeholder.com/50',
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Name Here',
                                                style: TextStyle(fontSize: 14)),
                                            Text('Occupation Here',
                                                style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('Exhibition Center A',
                                            style: TextStyle(fontSize: 12)),
                                        Text('June 8, 6 PM',
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
