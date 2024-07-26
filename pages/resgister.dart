import 'package:flutter/material.dart';
import '../auth.dart';

class RegistrationPage extends StatefulWidget {
  final String email;
  final String password;

  RegistrationPage({required this.email, required this.password});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final Auth _auth = Auth();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Registration'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _occupationController,
              decoration: InputDecoration(labelText: 'Occupation'),
            ),
            
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _auth.createUserWithEmailAndPassword(
                    email: widget.email,
                    password: widget.password,
                    name: _nameController.text,
                    occupation: _occupationController.text,
                  );
                  Navigator.pop(context); // Navigate back to the previous screen
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Registration failed: ${e.toString()}')),
                  );
                }
              },
              child: Text('Complete Registration'),
            ),
          ],
        ),
      ),
    );
  }
}
