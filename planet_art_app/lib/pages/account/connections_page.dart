import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ConnectionsPage extends StatefulWidget {
  @override
  _ConnectionsPageState createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  // temp data for connections
  final List<Map<String, String>> connections = List.generate(
    20,
    (index) => {
      'profileImageUrl': 'https://your-image-url.com/user$index.jpg',
      'name': 'User $index',
      'occupation': 'Occupation $index',
    },
  );

  final Set<int> removedConnections = {}; // track removed connections, will be dynamic

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connections'),
      ),
      body: ListView.builder(
        itemCount: connections.length,
        itemBuilder: (context, index) {
          final connection = connections[index];
          final isRemoved = removedConnections.contains(index);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: CachedNetworkImageProvider(connection['profileImageUrl']!),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection['name']!,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        connection['occupation']!,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
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
              ],
            ),
          );
        },
      ),
    );
  }
}
