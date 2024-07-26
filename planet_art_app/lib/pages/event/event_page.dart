import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:planet_art_app/pages/event/event_detail_page.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final _textController = TextEditingController();

  bool _showUpcoming = true;

  // Control sessions
  var uuid = const Uuid();

  String _sessionToken = '1234567890';

  // Load API KEY from .env
  String PLACES_API_KEY = dotenv.env['API_KEY'] ?? 'No API key found';

  List<dynamic> _places = [];

  // List<Map<String, String>> _photoUrlsWithNames = [];
  List<Map<String, dynamic>> _photoUrlsWithNames = [];

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

  // void getSuggestion() async {
  //   try {
  //     String baseURL =
  //         'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  //     String request =
  //         '$baseURL?input=Art%20Exhibition&key=$PLACES_API_KEY&sessiontoken=$_sessionToken';
  //     var response = await http.get(Uri.parse(request));
  //     var data = json.decode(response.body);

  //     if (kDebugMode) {
  //       print('mydata');
  //       print(data);
  //     }

  //     if (response.statusCode == 200) {
  //       setState(() {
  //         _places = data['predictions'];
  //       });

  //       if (_places.isNotEmpty) {
  //         var firstPlace = _places.first;
  //         await getPlaceDetails(
  //             firstPlace['place_id'], firstPlace['description']);
  //       }
  //     } else {
  //       throw Exception('Failed to load predictions');
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) {
        // Handle the case where the user denies permission
        print('Location permission denied');
        return;
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  void getSuggestion() async {
    try {
      // Request location permission
      await _requestLocationPermission();

      // Get current location
      Position? position = await _getCurrentLocation();

      if (position == null) {
        print('Could not get current location');
        return;
      }

      // Extract latitude and longitude
      String location = '${position.latitude},${position.longitude}';
      String radius = '5000'; // 20 km radius
      String type = 'art_gallery'; // Search for art galleries
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
      String request =
          '$baseURL?location=$location&radius=$radius&type=$type&key=$PLACES_API_KEY';

      List<dynamic> allPlaces = [];
      String? nextPageToken;

      while (true) {
        // Make the API request
        var response = await http.get(Uri.parse(nextPageToken ?? request));
        var data = json.decode(response.body);

        if (kDebugMode) {
          print('mydata');
          print(data);
        }

        if (response.statusCode == 200) {
          // Add results to the list
          allPlaces.addAll(data['results'] ?? []);

          // Check for next page token
          nextPageToken = data['next_page_token'];

          // If there is no next page token, break the loop
          if (nextPageToken == null) {
            break;
          }

          // Wait for a short period before making the next request
          await Future.delayed(const Duration(seconds: 2));
        } else {
          throw Exception('Failed to load predictions');
        }
      }

      setState(() {
        _places = allPlaces;
      });

      if (_places.isNotEmpty) {
        var firstPlace = _places.first;
        await getPlaceDetails(firstPlace['place_id'], firstPlace['name']);
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
        var formattedAddress = placeDetails['formatted_address'];
        var openingHours = placeDetails['opening_hours']?['weekday_text'] ?? [];

        _photoUrlsWithNames.clear();
        for (var photo in photos) {
          var photoReference = photo['photo_reference'];
          if (photoReference != null) {
            var photoUrl = await getPlacePhoto(photoReference);
            if (photoUrl != null) {
              _photoUrlsWithNames.add({
                'url': photoUrl,
                'name': placeName,
                'address': formattedAddress,
                'opening_hours': openingHours, // Ensure this is a List<String>
              });
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
                  onPressed: () {
                    setState(() {
                      _showUpcoming = true;
                    });
                  },
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
                  onPressed: () {
                    setState(() {
                      _showUpcoming = false;
                    });
                  },
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
            child: _showUpcoming ? _buildUpcomingView() : _buildCalendarView(),
          ),
        ],
      ),
    );
  }

  ListView _buildUpcomingView() {
    return ListView.builder(
      itemCount: _photoUrlsWithNames.length,
      itemBuilder: (context, index) {
        var item = _photoUrlsWithNames[index];
        var imageUrl = item['url'];
        var name = item['name'];
        var address = item['address'];
        var openingHours = item['opening_hours'] ?? [];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EventDetailPage(
                        item: item,
                      )),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0), // Rounded corners
            ),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(20.0), // Match the card corners
              child: Stack(
                children: [
                  Image.network(
                    imageUrl ?? 'https://via.placeholder.com/400x200',
                    fit: BoxFit.cover,
                    height: 250.0,
                    width: double.infinity,
                  ),
                  // Gradient overlay for text contrast
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                  ),
                  // Title at the top
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Column(
                      children: [
                        Text(
                          name ?? 'Art Exhibition',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          address ?? 'No address available',
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var hours in openingHours)
                          Text(
                            hours,
                            style: const TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarView() {
    // Get today's date
    DateTime now = DateTime.now();
    String formattedDate = DateFormat.yMMMMd().format(now); // Format the date

    return Column(
      children: [
        // Display today's date
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            formattedDate,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        // Display the list of items
        Expanded(
          child: ListView.builder(
            itemCount: _photoUrlsWithNames.length,
            itemBuilder: (context, index) {
              var item = _photoUrlsWithNames[index];
              var name = item['name'];
              return const ListTile(
                title: Text('test'),
              );
            },
          ),
        ),
      ],
    );
  }
}
