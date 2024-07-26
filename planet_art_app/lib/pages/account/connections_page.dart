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
        return doc.data() as Map<String, dynamic>;
      }).toList();

      setState(() {
        connections = fetchedConnections;
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
      appBar: AppBar(
        title: Text('Connections'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search connections',
                border: OutlineInputBorder(),
                filled: true,
              ),
              onChanged: _filterConnections,
            ),
          ),
        ),
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
            title: Text(name),
            subtitle: Text(occupation),
          );
        },
      ),
    );
  }
}
