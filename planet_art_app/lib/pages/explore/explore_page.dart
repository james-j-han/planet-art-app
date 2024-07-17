import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _textController = TextEditingController();
  // Control sessions
  var uuid = const Uuid();
  String _sessionToken = '1234567890';

  List<dynamic> _places = [];

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      _onChanged();
    });
  }

  void _onChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }

    getSuggestion(_textController.text);
  }

  void getSuggestion(String input) async {
    const String PLACES_API_KEY = 'AIzaSyALDRnIRGMgqKMfVK5vXOjSgQ3jpxBUa98';

    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=$input&key=$PLACES_API_KEY&sessiontoken=$_sessionToken';
      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);

      if (kDebugMode) {
        print('mydata');
        print(data);
      }

      if (response.statusCode == 200) {
        setState(() {
          _places = json.decode(response.body)['predictions'];
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Explore Page'),
        ),
        body: TextField(
          controller: _textController,
          decoration: InputDecoration(
              hintText: 'Search here',
              suffixIcon: IconButton(
                icon: const Icon(Icons.cancel_rounded),
                onPressed: () {
                  _textController.clear();
                },
              )),
        ));
  }
}
