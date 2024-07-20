import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

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
            _buildOtherSettingsSection(),
          ],
        ),
      ),
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
            // implement privacy settings
          },
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText, // Changed from labelText to hintText
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
