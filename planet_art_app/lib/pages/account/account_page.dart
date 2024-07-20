import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'connections_page.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'add_post_page.dart';
import 'user_service.dart';
import '../../auth.dart'; // Ensure you import Auth for sign out functionality

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String uid = '';
  String name = '';
  String occupation = '';
  String bio = '';
  String profileImageUrl = 'https://your-image-url.com/profile.jpg';
  String portfolioLink = ''; // Add a field for the portfolio link
  int connections = 0;

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
          profileImageUrl = userData['profileImageUrl'] ?? 'https://your-image-url.com/profile.jpg';
          connections = userData['connections'] ?? 0;
          portfolioLink = userData['portfolioLink'] ?? ''; // Fetch the portfolio link
        });
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

  void _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    );

    // If there's a result, update the profile
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        name = result['name'] ?? name;
        occupation = result['occupation'] ?? occupation;
        bio = result['bio'] ?? bio;
        profileImageUrl = result['profileImageUrl'] ?? profileImageUrl;
        portfolioLink = result['portfolioLink'] ?? portfolioLink;
      });
    }
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
          );
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
                      'pronouns', // Replace with actual pronouns if available
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
              if (portfolioLink.isNotEmpty) // Show portfolio link if available
                GestureDetector(
                  onTap: () {
                    _launchURL(portfolioLink); // Use the correct URL
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
    // temp data for posts
    final List<String> posts = List.generate(
        30, (index) => 'https://i.natgeofe.com/n/548467d8-c5f1-4551-9f58-6817a8d2c45e/NationalGeographic_2572187_square.jpg');

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
        return CachedNetworkImage(
          imageUrl: posts[index],
          fit: BoxFit.cover,
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