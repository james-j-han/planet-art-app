import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'connections_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_page.dart';
import 'add_post_page.dart';
import 'posts.dart';
import 'package:planet_art_app/auth.dart'; // Import your Auth file here

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String name = '';
  String pronouns = '';
  String occupation = '';
  String bio = '';
  String profileImageUrl = '';
  String portfolioLink = ''; 
  int connections = 0;

  final Auth _auth = Auth(); // Create an instance of Auth

  @override
  void initState() {
    super.initState();
    _getUserProfile();
    _getConnectionCount();
  }

  Future<void> _getUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        name = userDoc['name'] ?? 'No Name';
        occupation = userDoc['occupation'] ?? 'No Occupation';
        bio = userDoc['bio'] ?? 'No Bio';
        pronouns = userDoc['pronouns'] ?? '';
        profileImageUrl = userDoc['profileImageUrl'] ?? '';
        portfolioLink = userDoc['portfolioLink'] ?? ''; 
      });
    }
  }

  Future<void> _getConnectionCount() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        QuerySnapshot connectionsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('connections')
            .get();

        setState(() {
          connections = connectionsSnapshot.docs.length;
        });
      } catch (e) {
        print('Error fetching connections count: $e');
      }
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    );
  }

  void _signOut() async {
    await _auth.signOut(); // Call the instance method
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to login screen after sign out
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 40, 35, 88),
        title: Text(name, style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white), // Set icon color to white
        automaticallyImplyLeading: false, // Remove leading icon
      ),
      body: Container(
        color: Color.fromARGB(255, 53, 48, 115),
        child: Column(
          mainAxisSize: MainAxisSize.max, // Ensure the column takes up the full height
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
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
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      pronouns,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  occupation,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bio,
                            textAlign: TextAlign.start,
                            style: TextStyle(color: Colors.white),
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
                              Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ConnectionsPage(uid: FirebaseAuth.instance.currentUser!.uid),
                                    ),
                                  );
                                },
                                child: Text(
                                  '$connections Connections',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('posts')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('No posts found', style: TextStyle(color: Colors.white)));
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
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 4.0,
                              mainAxisSpacing: 4.0,
                            ),
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostsPage(
                                      posts: posts,
                                      initialIndex: index,
                                      name: name,
                                      uid: FirebaseAuth.instance.currentUser!.uid,
                                      onPostsUpdated: (updatedPosts) {},
                                    ),
                                  ),
                                ),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        backgroundColor: Color.fromARGB(255, 80, 75, 150), // Lighter shade of the background color
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: <Widget>[
                  ListTile(
                    title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
                    leading: Icon(Icons.edit, color: Colors.white),
                    onTap: _editProfile,
                  ),
                  
                  ListTile(
                    title: Text('Saved Events', style: TextStyle(color: Colors.white)),
                    leading: Icon(Icons.bookmark, color: Colors.white),
                    onTap: () {
                      // open saved events page
                    },
                  ),
                  ListTile(
                    title: Text('Sign Out', style: TextStyle(color: Colors.white)),
                    leading: Icon(Icons.exit_to_app, color: Colors.white),
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
