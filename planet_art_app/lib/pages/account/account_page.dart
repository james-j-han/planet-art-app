import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:planet_art_app/auth.dart';
import 'package:url_launcher/url_launcher.dart';


class AccountPage extends StatelessWidget {
  // these will be updated dynamically
  final String profileImageUrl = 'https://your-image-url.com/profile.jpg';
  final String username = 'your_username';
  final String name = 'Your Name';
  final String linkUrl = 'myportfolio.com';
  final String occupation = 'Your occupation';
  final String pronouns = 'Your pronouns';
  final String bio = 'Your bio goes here.';
  final int connections = 120;

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        actions: [
          Builder(
            builder: (BuildContext context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer(); 
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildBioSection(),
            _buildPostsGrid(),
          ],
        ),
      ),
      endDrawer: _buildDrawer(), 
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: CachedNetworkImageProvider(profileImageUrl), //dynamic profile photo
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

  Widget _buildBioSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  _launchURL(linkUrl);
                },
                child: Text(
                  'myportfolio.com',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // open connections page
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
    // Dummy data for posts
    final List<String> posts = List.generate(
        30, (index) => 'https://your-image-url.com/post$index.jpg');

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

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: <Widget>[
                ListTile(
                  title: Text('Settings'),
                  leading: Icon(Icons.settings),
                  onTap: () {
                    // open settings
                  },
                ),
                ListTile(
                  title: Text('Saved Events'),
                  leading: Icon(Icons.bookmark),
                  onTap: () {
                    // Handle saved events tap
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
