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
  bool _isLoading = true;

  // Control sessions
  var uuid = const Uuid();

  String _sessionToken = '1234567890';

  // Load API KEY from .env
  String PLACES_API_KEY = dotenv.env['API_KEY'] ?? 'No API key found';

  List<dynamic> _places = [];

  // List<Map<String, String>> _photoUrlsWithNames = [];
  List<Map<String, dynamic>> _photoUrlsWithNames = [];

  DateTime _selectedDate = DateTime.now();

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

  // void getSuggestion() async {
  //   try {
  //     // Request location permission
  //     await _requestLocationPermission();

  //     // Get current location
  //     Position? position = await _getCurrentLocation();

  //     if (position == null) {
  //       print('Could not get current location');
  //       return;
  //     } else {
  //       print('${position.latitude},${position.longitude}');
  //     }

  //     // Extract latitude and longitude
  //     String location = '${position.latitude},${position.longitude}';
  //     String radius = '5000'; // 5 km radius
  //     String type = 'art_gallery'; // Search for art galleries
  //     String baseURL =
  //         'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  //     String request =
  //         '$baseURL?location=$location&radius=$radius&type=$type&key=$PLACES_API_KEY';

  //     List<dynamic> allPlaces = [];
  //     String? nextPageToken;

  //     while (true) {
  //       // Make the API request
  //       var response = await http.get(Uri.parse(nextPageToken ?? request));
  //       var data = json.decode(response.body);

  //       if (kDebugMode) {
  //         print('mydata');
  //         print(data);
  //       }

  //       if (response.statusCode == 200) {
  //         // Add results to the list
  //         allPlaces.addAll(data['results'] ?? []);

  //         // Check for next page token
  //         nextPageToken = data['next_page_token'];

  //         // If there is no next page token, break the loop
  //         if (nextPageToken == null) {
  //           break;
  //         }

  //         // Wait for a short period before making the next request
  //         await Future.delayed(const Duration(seconds: 2));
  //       } else {
  //         throw Exception('Failed to load predictions');
  //       }
  //     }

  //     setState(() {
  //       _places = allPlaces;
  //     });

  //     if (_places.isNotEmpty) {
  //       // var firstPlace = _places.first;
  //       // await getPlaceDetails(firstPlace['place_id'], firstPlace['name']);

  //       for (var place in _places) {
  //         await getPlaceDetails(place['place_id'], place['name']);
  //       }
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  void getSuggestion() async {
    try {
      await _requestLocationPermission();
      Position? position = await _getCurrentLocation();

      if (position == null) {
        print('Could not get current location');
        return;
      }

      String location = '${position.latitude},${position.longitude}';
      String radius = '5000';
      String type = 'art_gallery';
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
      String request =
          '$baseURL?location=$location&radius=$radius&type=$type&key=$PLACES_API_KEY';

      List<dynamic> allPlaces = [];
      String? nextPageToken;

      do {
        var response = await http.get(Uri.parse(nextPageToken == null
            ? request
            : '$baseURL?pagetoken=$nextPageToken&key=$PLACES_API_KEY'));
        var data = json.decode(response.body);

        if (response.statusCode == 200) {
          allPlaces.addAll(data['results'] ?? []);
          nextPageToken = data['next_page_token'];

          if (nextPageToken != null) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } else {
          throw Exception('Failed to load predictions');
        }
      } while (nextPageToken != null);

      setState(() {
        _places = allPlaces;
        _isLoading = false;
      });

      if (_places.isNotEmpty) {
        List<Map<String, dynamic>> tempPhotoUrlsWithNames = [];

        for (var place in _places) {
          var placeDetails =
              await getPlaceDetails(place['place_id'], place['name']);
          tempPhotoUrlsWithNames.addAll(placeDetails);
        }

        setState(() {
          _photoUrlsWithNames = tempPhotoUrlsWithNames;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // Future<void> getPlaceDetails(String placeID, String placeName) async {
  //   try {
  //     String baseURL =
  //         'https://maps.googleapis.com/maps/api/place/details/json';
  //     String request = '$baseURL?place_id=$placeID&key=$PLACES_API_KEY';
  //     var response = await http.get(Uri.parse(request));
  //     var data = json.decode(response.body);

  //     if (response.statusCode == 200) {
  //       var placeDetails = data['result'];
  //       var photos = placeDetails['photos'] ?? [];
  //       var formattedAddress = placeDetails['formatted_address'];
  //       // var openingHours = placeDetails['opening_hours']?['weekday_text'] ?? [];
  //       var openingHours =
  //           (placeDetails['opening_hours']?['weekday_text'] as List<dynamic>?)
  //                   ?.map((e) => e.toString())
  //                   .toList() ??
  //               [];

  //       _photoUrlsWithNames.clear();
  //       for (var photo in photos) {
  //         var photoReference = photo['photo_reference'];
  //         if (photoReference != null) {
  //           var photoUrl = await getPlacePhoto(photoReference);
  //           if (photoUrl != null) {
  //             _photoUrlsWithNames.add({
  //               'url': photoUrl,
  //               'name': placeName,
  //               'address': formattedAddress,
  //               'opening_hours': openingHours, // Ensure this is a List<String>
  //             });
  //           }
  //         }
  //       }

  //       setState(() {});
  //     } else {
  //       throw Exception('Failed to load place details');
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  Future<List<Map<String, dynamic>>> getPlaceDetails(
      String placeID, String placeName) async {
    List<Map<String, dynamic>> placeData = [];

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
        var openingHours =
            (placeDetails['opening_hours']?['weekday_text'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];

        for (var photo in photos) {
          var photoReference = photo['photo_reference'];
          if (photoReference != null) {
            var photoUrl = await getPlacePhoto(photoReference);
            if (photoUrl != null) {
              placeData.add({
                'url': photoUrl,
                'name': placeName,
                'address': formattedAddress,
                'opening_hours': openingHours,
              });
            }
          }
        }
      } else {
        throw Exception('Failed to load place details');
      }
    } catch (e) {
      print(e);
    }

    return placeData;
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
      backgroundColor: Color.fromARGB(255, 53, 48, 115),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color.fromARGB(255, 53, 48, 115),
        flexibleSpace: Column(
          children: [
            SizedBox(height: 40.0),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    margin: EdgeInsets.only(right: 16.0),
                    child: Image.network(
                      'https://firebasestorage.googleapis.com/v0/b/planet-art-app.appspot.com/o/app%2Ficons8-planet-48%20(1).png?alt=media&token=e4297794-f47d-4b68-ab82-9a39f3049ed5',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.black),
                          hintText: 'Search anything',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                        child: Text(
                          'Upcoming',
                          style: TextStyle(
                            color: _showUpcoming
                                ? Colors.white
                                : Color.fromARGB(255, 194, 189, 251),
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
                        child: Text(
                          'Calendar',
                          style: TextStyle(
                            color: !_showUpcoming
                                ? Colors.white
                                : Color.fromARGB(255, 194, 189, 251),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _showUpcoming
                      ? _buildUpcomingView()
                      : _buildCalendarView(),
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

  // void _filterPlacesByDate() {
  //   print('Before filtering: $_photoUrlsWithNames'); // Debug print
  //   setState(() {
  //     _photoUrlsWithNames = _photoUrlsWithNames.where((place) {
  //       var openingHours = place['opening_hours'] as List<String>? ?? [];
  //       return _isOpenOnSelectedDate(openingHours);
  //     }).toList();
  //   });
  //   print('After filtering: $_photoUrlsWithNames'); // Debug print
  // }

  void _filterPlacesByDate() {
    print('Before filtering: $_photoUrlsWithNames'); // Debug print

    setState(() {
      // Use a Set to ensure uniqueness
      final seenPlaceIds = <String>{};
      _photoUrlsWithNames = _photoUrlsWithNames.where((place) {
        var placeId = place['place_id'];
        var openingHours = place['opening_hours'] as List<String>? ?? [];
        bool isOpen = _isOpenOnSelectedDate(openingHours);

        // Add the place to the list if it's open on the selected date and hasn't been added yet
        if (isOpen && !seenPlaceIds.contains(placeId)) {
          seenPlaceIds.add(placeId);
          return true;
        }
        return false;
      }).toList();
    });

    print('After filtering: $_photoUrlsWithNames'); // Debug print
  }

  bool _isOpenOnSelectedDate(List<String> openingHours) {
    String dayOfWeek =
        DateFormat('EEEE').format(_selectedDate); // e.g., 'Monday'
    return openingHours.any((hours) => hours.contains(dayOfWeek));
  }

  // bool _isOpenOnSelectedDate(List<String> openingHours) {
  //   String dayOfWeek =
  //       DateFormat('EEEE').format(_selectedDate); // e.g., 'Monday'
  //   return openingHours.any((hours) => hours.contains(dayOfWeek));
  // }

  Widget _buildCalendarView() {
    String formattedDate =
        DateFormat.yMMMMd().format(_selectedDate); // Format the date

    return Column(
      children: [
        // Display today's date
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListTile(
            leading: const Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
            ),
            title: Text(
              formattedDate,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        // Button to change the date
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            onPressed: () async {
              // Show date picker
              DateTime? newDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (newDate != null && newDate != _selectedDate) {
                setState(() {
                  _selectedDate = newDate;
                  // Filter places based on the selected date
                  _filterPlacesByDate();
                });
              }
            },
            child: const Text('Change Date'),
          ),
        ),
        // Display the list of items
        Expanded(
          child: ListView.builder(
            itemCount: _photoUrlsWithNames.length,
            itemBuilder: (context, index) {
              var item = _photoUrlsWithNames[index];
              var name = item['name'];

              // Debug print to check the data for each ListTile
              print('ListTile $index: $item');

              return ListTile(
                leading: const Icon(Icons.location_on, color: Colors.white),
                title: Text(
                  name ?? 'no name',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Open today',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EventDetailPage(item: item)));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget _buildCalendarView() {
  //   String formattedDate =
  //       DateFormat.yMMMMd().format(_selectedDate); // Format the date

  //   return Column(
  //     children: [
  //       // Display today's date
  //       Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: ListTile(
  //           leading: const Icon(
  //             Icons.calendar_today_rounded,
  //             color: Colors.white,
  //           ),
  //           title: Text(
  //             formattedDate,
  //             style: const TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.white),
  //           ),
  //         ),
  //       ),
  //       // Button to change the date
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //         child: ElevatedButton(
  //           onPressed: () async {
  //             // Show date picker
  //             DateTime? newDate = await showDatePicker(
  //               context: context,
  //               initialDate: _selectedDate,
  //               firstDate: DateTime(2000),
  //               lastDate: DateTime(2100),
  //             );

  //             if (newDate != null && newDate != _selectedDate) {
  //               setState(() {
  //                 _selectedDate = newDate;
  //                 // Filter places based on the selected date
  //                 _filterPlacesByDate();
  //               });
  //             }
  //           },
  //           child: const Text('Change Date'),
  //         ),
  //       ),
  //       // Display the list of items
  //       Expanded(
  //         child: ListView.builder(
  //           itemCount: _photoUrlsWithNames.length,
  //           itemBuilder: (context, index) {
  //             var item = _photoUrlsWithNames[index];
  //             var name = item['name'];
  //             // var openingHours = item['opening_hours'] as List<String>? ?? [];

  //             // Debug print to check the data for each ListTile
  //             print('ListTile $index: $item');

  //             // Filter out places that are not open on the selected date
  //             if (_isOpenOnSelectedDate(openingHours)) {
  //               return ListTile(
  //                 leading: const Icon(Icons.location_on, color: Colors.white),
  //                 title: Text(
  //                   name ?? 'no name',
  //                   style: const TextStyle(color: Colors.white),
  //                 ),
  //                 subtitle: const Text(
  //                   'Open today',
  //                   style: TextStyle(color: Colors.white),
  //                 ),
  //                 onTap: () {
  //                   Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                           builder: (context) => EventDetailPage(item: item)));
  //                 },
  //               );
  //             } else {
  //               return Container(); // Empty container if not open
  //             }
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
