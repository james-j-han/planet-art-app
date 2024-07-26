import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'explore_detail_page.dart';

class ExplorePage extends StatefulWidget {
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getUserName(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['name'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130.0),
        child: AppBar(
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
                      child: CachedNetworkImage(
                        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/planet-art-app.appspot.com/o/app%2Ficons8-planet-48%20(1).png?alt=media&token=e4297794-f47d-4b68-ab82-9a39f3049ed5',
                        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
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
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.0),
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Explore Planet Art',
                  style: TextStyle(
                    fontSize: 29.0,
                    color: Color.fromARGB(255, 194, 189, 251),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('explore_posts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No posts found'));
          } else {
            // Convert snapshot data to a list of posts
            _posts = snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return {
                'title': data['title'] ?? '',
                'description': data['description'] ?? '',
                'imageUrl': data['imageUrl'] ?? '',
                'uid': data['uid'] ?? '',
              };
            }).toList();

            // Filter posts based on the search query
            var filteredPosts = _posts.where((post) {
              final title = post['title'].toLowerCase();
              final description = post['description'].toLowerCase();
              return title.contains(_searchQuery) || description.contains(_searchQuery);
            }).toList();

            return GridView.builder(
              padding: EdgeInsets.all(0.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1.0,
                mainAxisSpacing: 1.0,
              ),
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                var post = filteredPosts[index];
                return FutureBuilder<String>(
                  future: _getUserName(post['uid']),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (userSnapshot.hasError) {
                      return Center(child: Icon(Icons.error));
                    } else {
                      final name = userSnapshot.data ?? 'Unknown';
                      return GestureDetector(
                        onTap: () => _onPostTap(index),
                        child: CachedNetworkImage(
                          imageUrl: post['imageUrl'],
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  void _onPostTap(int index) async {
    var post = _posts[index]; // Use _posts instead of posts
    String name = await _getUserName(post['uid']);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreDetailPage(
          posts: [post],
          name: name, // pass the user's name
        ),
      ),
    );
  }
}
