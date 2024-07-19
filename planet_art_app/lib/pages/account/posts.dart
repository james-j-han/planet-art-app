import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostsPage extends StatelessWidget {
  final List<Map<String, String>> posts;
  final int initialIndex;

  PostsPage({required this.posts, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('your_username'),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPostHeader(post['imageUrl']!),
                SizedBox(height: 8.0), // Space between header and image
                AspectRatio(
                  aspectRatio: 1.0, // Maintain square aspect ratio
                  child: CachedNetworkImage(
                    imageUrl: post['imageUrl']!,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    post['title']!,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(post['description']!),
                ),
                SizedBox(height: 16.0), // Space at the end of each post
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostHeader(String profileImageUrl) {
    return Container(
      color: Colors.grey[200], // Light gray background color
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: CachedNetworkImageProvider(profileImageUrl),
          ),
          SizedBox(width: 8),
          Text(
            'Your Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

