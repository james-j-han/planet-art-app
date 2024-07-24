import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'connections_page.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'add_post_page.dart';
import 'posts.dart';
import '../../auth.dart'; 
import 'user_service.dart'; 

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String uid = '';
  String pronouns = '';
  String name = '';
  String occupation = '';
  String bio = '';
  String profileImageUrl = '';
  String portfolioLink = ''; 
  int connections = 0;
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        uid = user.uid;
      });
      _getUserProfile();
      _getUserPosts(); 
    } else {
      print('No user is signed in.');
    }
  }

  void _getUserProfile() async {
    if (uid.isNotEmpty) {
      UserService userService = UserService();
      Map<String, dynamic>? userData = await userService.getUserProfile();

      if (userData != null) {
        setState(() {
          name = userData['name'] ?? 'No Name';
          occupation = userData['occupation'] ?? 'No Occupation';
          bio = userData['bio'] ?? 'No Bio';
          pronouns =userData['pronouns'] ?? '';
          profileImageUrl = userData['profileImageUrl'] ?? '';
          connections = userData['connections'] ?? 0;
          portfolioLink = userData['portfolioLink'] ?? ''; 
        });
      }
    }
  }

  void _getUserPosts() async {
    if (uid.isNotEmpty) {
      UserService userService = UserService();
      List<Map<String, dynamic>> userPosts = await userService.getUserPosts(uid);

      setState(() {
        posts = userPosts;
      });
    }
  }
  // url launch package
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    );

    // if there's a result, update the profile
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        name = result['name'] ?? name;
        occupation = result['occupation'] ?? occupation;
        bio = result['bio'] ?? bio;
        pronouns = result['pronouns'] ?? pronouns;
        profileImageUrl = result['profileImageUrl'] ?? profileImageUrl;
        portfolioLink = result['portfolioLink'] ?? portfolioLink;
      });
    }
  }

  void _viewPost(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostsPage(
          posts: [post],
          initialIndex: 0, //for post page scroll
          name: name, // pass the user's name
        ),
      ),
    );
  }
  void _onPostTap(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostsPage(
          posts: posts,
          initialIndex: index,
          name: name,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPostPage()),
          ).then((_) => _getUserPosts()); // refresh posts after adding a new one
        },
        child: Icon(Icons.add),
      ),
      endDrawer: _buildDrawer(context),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(width: 8),
                    Text(
                      pronouns,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  occupation,
                  style: TextStyle(fontSize: 16),
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
              Spacer(), // pushes the connections button to the right
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConnectionsPage()),
                  );
                },
                child: Text(
                  '$connections Connections',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
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
      return GestureDetector(
        onTap: () => _onPostTap(index), // go to PostsPage on tap
        child: CachedNetworkImage(
          imageUrl: posts[index]['imageUrl'],
          fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: <Widget>[
                ListTile(
                  title: Text('Edit Profile'),
                  leading: Icon(Icons.edit),
                  onTap: _editProfile,
                ),
                ListTile(
                  title: Text('Settings'),
                  leading: Icon(Icons.settings),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  },
                ),
                ListTile(
                  title: Text('Saved Events'),
                  leading: Icon(Icons.bookmark),
                  onTap: () {
                    // open saved events
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _signOutButton(),
          ),
        ],
      ),
    );
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Sign Out'),
    );
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }
}
