import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _pronounsController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String profileImageUrl = 'https://your-image-url.com/profile.jpg';

  void _saveProfile() {
    // update dynamically
    print('Profile saved');
    print('Username: ${_usernameController.text}');
    print('Name: ${_nameController.text}');
    print('Link: ${_linkController.text}');
    print('Occupation: ${_occupationController.text}');
    print('Pronouns: ${_pronounsController.text}');
    print('Bio: ${_bioController.text}');
  }

  void _changeProfileImage() {
    // dynamic again
    setState(() {
      profileImageUrl = 'https://your-image-url.com/new-profile.jpg';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileSection(),
            Divider(),
            _buildOtherSettingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: _changeProfileImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: CachedNetworkImageProvider(profileImageUrl),
            child: Icon(
              Icons.camera_alt,
              size: 30,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildTextField(_usernameController, 'Username'),
        _buildTextField(_nameController, 'Name'),
        _buildTextField(_linkController, 'Link'),
        _buildTextField(_occupationController, 'Occupation'),
        _buildTextField(_pronounsController, 'Pronouns'),
        _buildTextField(_bioController, 'Bio', maxLines: 5),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saveProfile,
          child: Text('Save Profile'),
        ),
      ],
    );
  }

  Widget _buildOtherSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ListTile(
          leading: Icon(Icons.security),
          title: Text('Privacy'),
          onTap: () {
            // implement blocked users
          },
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
