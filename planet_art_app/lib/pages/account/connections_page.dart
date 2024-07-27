import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionsPage extends StatefulWidget {
  final String uid;

  ConnectionsPage({required this.uid});

  @override
  _ConnectionsPageState createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> connections = [];
  List<Map<String, dynamic>> filteredConnections = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchConnections();
  }

  Future<void> _fetchConnections() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('connections')
          .get();

      final fetchedConnections = snapshot.docs.map((doc) {
        // Fetch user details from the 'users' collection
        final userId = doc.id;
        return _firestore.collection('users').doc(userId).get().then((userDoc) {
          return userDoc.data() as Map<String, dynamic>;
        });
      }).toList();

      final userDocs = await Future.wait(fetchedConnections);

      setState(() {
        connections = userDocs;
        filteredConnections = connections;
      });
    } catch (e) {
      print('Error fetching connections: $e');
      setState(() {
        connections = [];
        filteredConnections = [];
      });
    }
  }

  void _filterConnections(String query) {
    setState(() {
      searchQuery = query;
      filteredConnections = connections.where((connection) {
        final name = connection['name']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 53, 48, 115),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 53, 48, 115),
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.0), // Horizontal padding
          height: 36.0, // Set the height of the search bar
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5), // Translucent white background
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          child: TextField(
            onChanged: _filterConnections,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.white),
              hintText: 'Search connections...',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 0.0), // Minimal vertical padding
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white), // Set icon color to white
      ),
      body: ListView.builder(
        itemCount: filteredConnections.length,
        itemBuilder: (context, index) {
          final connection = filteredConnections[index];
          final profileImageUrl = connection['profileImageUrl'] ?? '';
          final name = connection['name'] ?? 'No Name';
          final occupation = connection['occupation'] ?? 'No Occupation';

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(profileImageUrl),
            ),
            title: Text(name, style: TextStyle(color: Colors.white)),
            subtitle: Text(occupation, style: TextStyle(color: Colors.white70)),
            tileColor: Color.fromARGB(255, 40, 35, 88), // Darker background for list items
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          );
        },
      ),
    );
  }
}
