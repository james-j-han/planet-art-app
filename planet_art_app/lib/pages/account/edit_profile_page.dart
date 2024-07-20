import 'package:flutter/material.dart';
import 'user_service.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _pronounsController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _portfolioLinkController = TextEditingController();

  String profileImageUrl = 'https://your-image-url.com/profile.jpg'; // Default profile image URL

  @override
  void initState() {
    super.initState();
    _getUserProfile();
  }

  void _getUserProfile() async {
    UserService userService = UserService();
    Map<String, dynamic>? userData = await userService.getUserProfile();

    if (userData != null) {
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _occupationController.text = userData['occupation'] ?? '';
        _pronounsController.text = userData['pronouns'] ?? '';
        _bioController.text = userData['bio'] ?? '';
        _portfolioLinkController.text = userData['portfolioLink'] ?? '';

        profileImageUrl = userData['profileImageUrl'] ?? 'https://your-image-url.com/profile.jpg';
      });
    }
  }



  void _saveProfile() async {
    UserService userService = UserService();
    
    // Save the profile data
    await userService.saveUserProfile(
      name: _nameController.text,
      occupation: _occupationController.text,
      bio: _bioController.text,
      profileImageUrl: profileImageUrl,
      pronouns: _pronounsController.text,
      portfolioLink: _portfolioLinkController.text,
    );

    // Retrieve and display the updated profile data
    Map<String, dynamic>? updatedUserData = await userService.getUserProfile();
    
    if (updatedUserData != null) {
      Navigator.pop(context, updatedUserData); // Pass updated data back
    } else {
      Navigator.pop(context, null); // Pass null if data retrieval failed
    }
  }




  void _changeProfileImage() {
    setState(() {
      profileImageUrl = 'https://your-image-url.com/new-profile.jpg'; // Placeholder for new image URL
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _changeProfileImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profileImageUrl),
                child: Icon(
                  Icons.camera_alt,
                  size: 30,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildTextField(_nameController, 'Name'),
            _buildTextField(_occupationController, 'Occupation'),
            _buildTextField(_pronounsController, 'Pronouns'),
            _buildTextField(_bioController, 'Bio', maxLines: 5),
            _buildTextField(_portfolioLinkController, 'Portfolio Link'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText, // Generic hint text
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Add padding for better appearance
        ),
      ),
    );
  }
}