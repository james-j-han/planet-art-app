import 'package:flutter/material.dart';

class EventDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const EventDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.deepPurple,
      //   title: Text(
      //     item['name'] ?? 'Details',
      //     style: const TextStyle(color: Colors.white),
      //   ),
      // ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [Color(0xFF1F0E69), Color(0xFF341592)],
          begin: Alignment.bottomCenter,
          end: Alignment.center,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the details of the place here
            Stack(
              children: [
                Image.network(
                  item['url'] ?? 'https://via.placeholder.com/400x200',
                  fit: BoxFit.cover,
                  height: 500.0,
                  width: double.infinity,
                ),
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
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Column(
                    children: [
                      Text(
                        item['name'] ?? 'Art Exhibition',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // const Text('Location'),
            ListTile(
              leading: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
              ),
              title: Text(
                'Location',
                style: TextStyle(fontSize: 16, color: Colors.grey[300]),
              ),
              subtitle: Text(
                item['address'] ?? 'Exhibition A',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.access_time_filled_rounded,
                color: Colors.white,
              ),
              title: Text(
                'When',
                style: TextStyle(fontSize: 16, color: Colors.grey[300]),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exhibition A', // This could be replaced with the actual event name
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var hour in item['opening_hours'] ?? [])
                    Text(
                      hour,
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
