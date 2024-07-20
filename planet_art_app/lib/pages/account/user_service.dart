import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserProfile() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<void> saveUserProfile({
    required String name,
    required String occupation,
    required String bio,
    required String profileImageUrl,
    required String pronouns,
    required String portfolioLink,
  }) async {
    User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'occupation': occupation,
        'bio': bio,
        'profileImageUrl': profileImageUrl,
        'pronouns': pronouns,
        'portfolioLink': portfolioLink, // Ensure correct field name
      });
    }
  }
}