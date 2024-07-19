import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ConnectionsPage extends StatefulWidget {
  @override
  _ConnectionsPageState createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  // Dummy data for connections
  final List<Map<String, String>> connections = List.generate(
    20,
    (index) => {
      'profileImageUrl': 'https://your-image-url.com/user$index.jpg',
      'name': 'User $index',
      'occupation': 'Occupation $index',
    },
  );

  final Set<int> removedConnections = {}; // Track removed connections
  late List<Map<String, String>> filteredConnections; // Use late to initialize in initState
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    filteredConnections = connections; // Initialize filteredConnections with all connections
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredConnections = connections
          .where((connection) => connection['name']?.toLowerCase().contains(query.toLowerCase()) ?? false)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: updateSearchQuery,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search connections...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredConnections.length,
        itemBuilder: (context, index) {
          final connection = filteredConnections[index];
          final isRemoved = removedConnections.contains(index);
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(connection['profileImageUrl'] ?? ''),
            ),
            title: Text(connection['name'] ?? ''),
            subtitle: Text(connection['occupation'] ?? ''),
            trailing: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isRemoved) {
                    removedConnections.remove(index);
                  } else {
                    removedConnections.add(index);
                  }
                });
              },
              child: Text(isRemoved ? 'Add' : 'Remove'),
            ),
          );
        },
      ),
    );
  }
}
