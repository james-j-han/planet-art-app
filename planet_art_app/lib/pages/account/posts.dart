import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostsPage extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final int initialIndex;
  final String name;

  PostsPage({
    required this.posts,
    required this.initialIndex,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
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
                _buildPostHeader(post['profileImageUrl'] ?? ''),
                SizedBox(height: 4.0), 
                AspectRatio(
                  aspectRatio: 1.0,
                  child: CachedNetworkImage(
                    imageUrl: post['imageUrl'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), 
                  child: Text(
                    post['title'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), 
                  child: Text(post['description'] ?? ''),
                ),
                SizedBox(height: 8.0), 
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostHeader(String profileImageUrl) {
    return Container(
      color: Colors.grey[200], 
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: CachedNetworkImageProvider(profileImageUrl),
          ),
          SizedBox(width: 8),
          Text(
            name, 
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
