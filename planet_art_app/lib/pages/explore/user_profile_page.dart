import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../account/connections_page.dart';
import '../account/posts.dart'; // Ensure PostsPage is imported
import 'package:planet_art_app/auth.dart'; // Import your Auth file here
import '../account/user_service.dart'; // Ensure UserService is imported

class UserProfilePage extends StatefulWidget {
  final String uid;
  final List<Map<String, dynamic>> posts;

  const UserProfilePage({Key? key, required this.uid, required this.posts}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  
  String name = '';
  String pronouns = '';
  String occupation = '';
  String bio = '';
  String profileImageUrl = '';
  String portfolioLink = ''; 
  int connections = 0;
  bool isConnected = false; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getUserProfile();
    _getConnectionCount(); // Fetch the number of connections
    _checkConnectionStatus(); // Check the connection status
  }

  Future<void> _getUserProfile() async {
    UserService userService = UserService();
    Map<String, dynamic>? userData = await userService.getUserProfile(widget.uid);

    if (userData != null) {
      setState(() {
        name = userData['name'] ?? 'No Name';
        occupation = userData['occupation'] ?? 'No Occupation';
        bio = userData['bio'] ?? 'No Bio';
        pronouns = userData['pronouns'] ?? '';
        profileImageUrl = userData['profileImageUrl'] ?? '';
        portfolioLink = userData['portfolioLink'] ?? ''; 
      });
    }
  }

  Future<void> _getConnectionCount() async {
    try {
      QuerySnapshot connectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('connections')
          .get();
      setState(() {
        connections = connectionsSnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching connections count: $e');
    }
  }

  Future<void> _checkConnectionStatus() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot connectionDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('connections')
          .doc(widget.uid)
          .get();

      setState(() {
        isConnected = connectionDoc.exists;
      });
    }
  }

  void _toggleConnectionStatus() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentReference connectionDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('connections')
          .doc(widget.uid);

      if (isConnected) {
        await connectionDocRef.delete();
      } else {
        await connectionDocRef.set({'connectedAt': FieldValue.serverTimestamp()});
      }

      setState(() {
        isConnected = !isConnected;
      });
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _viewPost(Map<String, dynamic> post) {
    // Ensure post data is correctly passed
    final postId = post['postId'];
    if (postId != null && postId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostsPage(
            posts: widget.posts, // Pass all posts
            initialIndex: widget.posts.indexWhere((p) => p['postId'] == postId),
            name: name,
            uid: widget.uid,
            onPostsUpdated: (updatedPosts) {}, // Handle post updates if needed
          ),
        ),
      );
    } else {
      print('Error: Post ID is null or empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 53, 48, 115), // Background color
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 40, 35, 88), // AppBar background color
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Back icon color
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          name,
          style: TextStyle(color: Colors.white), // Text color
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat, color: Colors.white), // Chat icon color
            onPressed: () {
              // Handle chat button press
              // Navigate to chat screen or perform chat action
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.5), // 50% opacity
            ),
            onPressed: _toggleConnectionStatus,
            child: Text(
              isConnected ? 'Remove Connection' : 'Add Connection',
              style: TextStyle(color: Colors.white), // Text color
            ),
          ),
          SizedBox(width: 8), // Add some spacing between buttons
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildBioSection(context),
            _buildPostsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: CachedNetworkImageProvider(profileImageUrl),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white, // Text color
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      pronouns,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white, // Text color
                      ),
                    ),
                  ],
                ),
                Text(
                  occupation,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white, // Text color
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bio,
            textAlign: TextAlign.start,
            style: TextStyle(color: Colors.white), // Text color
          ),
          SizedBox(height: 16),
          Row(
            children: [
              if (portfolioLink.isNotEmpty) 
                GestureDetector(
                  onTap: () {
                    _launchURL(portfolioLink); 
                  },
                  child: Text(
                    portfolioLink,
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              Spacer(), // Pushes the connections button to the right
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.5), // 50% opacity
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConnectionsPage(uid: widget.uid), // Pass uid here
                    ),
                  );
                },
                child: Text(
                  '$connections Connections',
                  style: TextStyle(color: Colors.white), // Text color
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

   Widget _buildPostsGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('posts')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white))); // Text color
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No posts found', style: TextStyle(color: Colors.white))); // Text color
        } else {
          final posts = snapshot.data!.docs.map((doc) {
            var data = doc.data();
            return {
              'postId': doc.id,
              'title': data['title'] ?? '',
              'description': data['description'] ?? '',
              'imageUrl': data['imageUrl'] ?? '',
            };
          }).toList();
           return GridView.builder(
            padding: EdgeInsets.all(16.0),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(), // Disable scrolling for nested scroll view
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return GestureDetector(
                onTap: () => _viewPost(post),
                child: CachedNetworkImage(
                  imageUrl: post['imageUrl'],
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.white),
                  fit: BoxFit.cover,
                ),
              );
            },
          );
        }
      },
    );
  }
}
