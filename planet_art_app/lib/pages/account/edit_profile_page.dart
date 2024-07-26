import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final TextEditingController _imageUrlController = TextEditingController();

  String profileImageUrl = '';
  File? _imageFile;
  bool _showUrlField = false;

  @override
  void initState() {
    super.initState();
    _getUserProfile();
  }

  void _getUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserService userService = UserService();
      Map<String, dynamic>? userData = await userService.getUserProfile(user.uid); // Pass uid to getUserProfile

      if (userData != null) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _occupationController.text = userData['occupation'] ?? '';
          _pronounsController.text = userData['pronouns'] ?? '';
          _bioController.text = userData['bio'] ?? '';
          _portfolioLinkController.text = userData['portfolioLink'] ?? '';
          
          profileImageUrl = userData['profileImageUrl'] ?? '';
        });
      }
    }
  }

  void _saveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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

      // Get and display the updated profile data
      Map<String, dynamic>? updatedUserData = await userService.getUserProfile(user.uid); // Pass uid to getUserProfile
      
      if (updatedUserData != null) {
        Navigator.pop(context, updatedUserData); // Pass updated data back
      } else {
        Navigator.pop(context, null); // Pass null if data retrieval failed
      }
    }
  }

  void _changeProfileImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image, color: Colors.white),
                title: Text('Upload Image', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await _uploadImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.link, color: Colors.white),
                title: Text('Enter Image URL', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _showUrlField = !_showUrlField;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      try {
        String downloadUrl = await _uploadImageToStorage(imageFile);
        setState(() {
          profileImageUrl = downloadUrl;
        });
        // Update Firestore with the new profile image URL
        UserService userService = UserService();
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await userService.updateUserProfileField('profileImageUrl', profileImageUrl);
        }
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  Future<String> _uploadImageToStorage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${FirebaseAuth.instance.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}');
      
      final uploadTask = storageRef.putFile(imageFile);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });
      
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw e; // Handle the error in _uploadImage
    }
  }

  void _enterImageUrl() async {
    String url = _imageUrlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        profileImageUrl = url;
      });
      // Update Firestore with the new profile image URL
      UserService userService = UserService();
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await userService.updateUserProfileField('profileImageUrl', profileImageUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 53, 48, 115), // Background color
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Color.fromARGB(255, 33, 30, 80), // Darker AppBar color
        titleTextStyle: TextStyle(
          color: Colors.white, // White text color
          fontSize: 20, // Adjust text size as needed
        ),
        iconTheme: IconThemeData(
          color: Colors.white, // White color for back button
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _changeProfileImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                backgroundColor: Colors.grey[200],
                child: profileImageUrl.isEmpty
                    ? Icon(
                        Icons.camera_alt,
                        size: 30,
                        color: Colors.white.withOpacity(0.8),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 16),
            if (_showUrlField)
              _buildTextField(_imageUrlController, 'Image URL', onSubmitted: _enterImageUrl),
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

  Widget _buildTextField(TextEditingController controller, String hintText, {int maxLines = 1, void Function()? onSubmitted}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white), // Text color
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.2), // Translucent white background
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white70), // Hint text color
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Add padding for better appearance
        ),
        onSubmitted: (_) => onSubmitted?.call(),
      ),
    );
  }
}
