import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPostPage extends StatefulWidget {
  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  File? _imageFile;
  String? _imageUrl;
  bool _showUrlField = false;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null;
        _showUrlField = false; // Hide URL field when picking an image
      });
    }
  }

  void _submitPost() {
    final String description = _descriptionController.text;
    final String? imageUrl = _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null;

    if ((_imageFile != null || imageUrl != null)) {
      // Here you would typically save the post to a backend or local storage

      if (_imageFile != null) {
        print('Image Path: ${_imageFile!.path}');
      }
      if (imageUrl != null) {
        print('Image URL: $imageUrl');
      }
      print('Description: $description');

      // Clear the fields after submission
      setState(() {
        _imageFile = null;
        _imageUrl = null;
        _imageUrlController.clear();
        _descriptionController.clear();
        _showUrlField = false; // Hide URL field after submission
      });

      // Optionally, you can navigate back or show a success message
      Navigator.pop(context);
    } else {
      // Show a message if no image or URL is provided
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image or enter a URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create new post'),
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: Text(
              'Post',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a Photo',
              style: TextStyle(fontSize:18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (_imageFile == null && _imageUrl == null)
              Text('No image selected.')
            else
              Center(
                child: Container(
                  width: 100, // Set fixed width
                  height: 100, // Set fixed height
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: _imageFile != null
                      ? Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                        ),
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
            Text(
              'Add a Caption',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildTextField(_descriptionController, 'Description', maxLines: 5),
          ],
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
