import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_page.dart'; // Import UserProfilePage
import 'package:firebase_auth/firebase_auth.dart';
import '../account/account_page.dart';

class ExploreDetailPage extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final String name;

  ExploreDetailPage({
    required this.posts,
    required this.name,
  });

  Future<Map<String, dynamic>> _fetchUserData(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts'),
      ),
      body: posts.isEmpty
        ? Center(child: Text('No posts available.'))
        : ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchUserData(post['uid']),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (userSnapshot.hasError) {
                    return Center(child: Text('Error: ${userSnapshot.error}'));
                  } else if (!userSnapshot.hasData || !userSnapshot.data!.isNotEmpty) {
                    return Center(child: Text('User data not found.'));
                  } else {
                    final userData = userSnapshot.data!;
                    return PostItem(
                      profileImageUrl: userData['profileImageUrl'] ?? '',
                      name: userData['name'] ?? 'No Name',
                      imageUrl: post['imageUrl'] ?? '',
                      title: post['title'] ?? '',
                      description: post['description'] ?? '',
                      uid: post['uid'] ?? '',
                      posts: posts, // Pass posts to UserProfilePage
                    );
                  }
                },
              );
            },
          ),
    );
  }
}

class PostItem extends StatelessWidget {
  final String profileImageUrl;
  final String imageUrl;
  final String title;
  final String description;
  final String name;
  final String uid; // Use uid for navigation
  final List<Map<String, dynamic>> posts; // Added posts parameter

  PostItem({
    required this.profileImageUrl,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.name,
    required this.uid,
    required this.posts, // Initialize posts
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(context),
          SizedBox(height: 4.0),
          AspectRatio(
            aspectRatio: 1.0,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          SizedBox(height: 4.0),
          Text(description),
        ],
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToProfile(context, uid),
      child: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(profileImageUrl)
                  : AssetImage('assets/default_profile_image.png') as ImageProvider, // Placeholder image
            ),
            SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, String uid) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final currentUserUid = currentUser.uid;

      if (uid == currentUserUid) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountPage() // Redirect to AccountPage with uid
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(uid: uid, posts: []), // Redirect to UserProfilePage with uid and posts
          ),
        );
      }
    }
  }
}

