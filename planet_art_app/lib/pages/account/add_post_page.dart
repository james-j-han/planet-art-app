import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth.dart'; 
import 'user_service.dart'; 

class AddPostPage extends StatefulWidget {
  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  File? _imageFile;
  String? _imageUrl;
  bool _showUrlField = false;

  // Image picker allows file upload from device. Not supported on web. 
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null;
        _showUrlField = false;
      });
    }
  }

  // Post submission
  Future<void> _submitPost() async {
    // Post fields
    final String description = _descriptionController.text;
    final String title = _titleController.text;
    final String? imageUrl = _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null;
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      String? postImageUrl;

      // Upload image to storage if selected
      if (_imageFile != null) {
        postImageUrl = await _uploadImageToStorage(_imageFile!, user.uid);
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        postImageUrl = _ensureValidUrl(imageUrl);
      } else {
        throw Exception('No image selected or URL provided');
      }

      if (postImageUrl == null || postImageUrl.isEmpty) {
        throw Exception('Failed to get a valid image URL');
      }

      // Generate a new post ID
      String postId = FirebaseFirestore.instance.collection('explore_posts').doc().id;
      print('Generated postId: $postId'); // Debug statement

      // Prepare post data
      final postData = {
        'description': description,
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': user.uid,
        'imageUrl': postImageUrl,
        'postId': postId, // Ensure postId matches document ID
      };

      // Add post to the explore_posts collection
      await FirebaseFirestore.instance.collection('explore_posts').doc(postId).set(postData);

      // Add post to the user's posts collection with postId as field value
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('posts').doc(postId).set(postData);

      // Clear the fields after submission
      setState(() {
        _imageFile = null;
        _imageUrl = null;
        _imageUrlController.clear();
        _descriptionController.clear();
        _titleController.clear();
        _showUrlField = false;
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting post: ${e.toString()}')),
      );
    }
  }


  // Adding to Firebase Storage. Image upload -> URL -> stored in Firestore DB under users/uid/posts
  Future<String?> _uploadImageToStorage(File imageFile, String userId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('posts/$userId/${DateTime.now().millisecondsSinceEpoch}');
      
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
      throw e; // Error handled in submit post function
    }
  }

  // Handling null input
  String? _ensureValidUrl(String url) {
    if (url.isEmpty) {
      return null;
    }
    // Trying to fix URI error via parsing and adding http
    try {
      Uri parsedUri = Uri.parse(url);

      // Check if the URI scheme is missing and add 'http://' if needed
      if (!parsedUri.hasScheme) {
        parsedUri = Uri.parse('http://$url');
      }
      
      return parsedUri.toString();
    } catch (e) {
      print('Error parsing URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New post'),
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: Text(
              'Post',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              if (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
                Text('No image selected.')
              else
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: _imageFile != null
                        ? Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          )
                        : (_imageUrl != null && _imageUrl!.isNotEmpty)
                            ? Image.network(
                                _ensureValidUrl(_imageUrl!) ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading image: $error');
                                  return Center(child: Text('Error loading image'));
                                },
                              )
                            : Center(child: Text('Invalid image URL')),
                  ),
                ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Choose from gallery'),
                  ),
                  Text('OR'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showUrlField = !_showUrlField;
                      });
                    },
                    child: Text('Add photo URL'),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (_showUrlField)
                _buildTextField(_imageUrlController, 'Image URL'),
              SizedBox(height: 16),
              const Text(
                'Add a Title',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildTextField(_titleController, 'Title', maxLines: 1),
              SizedBox(height: 8),
              const Text(
                'Add a Caption',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildTextField(_descriptionController, 'Description', maxLines: 2),
            ],
          ),
        ),
      ),
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
        onChanged: (value) {
          if (labelText == 'Image URL') {
            setState(() {
              _imageUrl = value.isNotEmpty ? value : null;
              if (_imageUrl != null) _imageFile = null;
            });
          }
        },
      ),
    );
  }
}
