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

  Future<List<Map<String, dynamic>>> getUserPosts(String uid) async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').doc(uid).collection('posts').orderBy('timestamp', descending: true).get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching user posts: $e");
      return [];
    }
  }

  Future<void> addPost(String uid, String? imageUrl, String description, String title) async {
    try {
      await _firestore.collection('users').doc(uid).collection('posts').add({
        'imageUrl': imageUrl,
        'description': description,
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding post: $e");
    }
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
        'portfolioLink': portfolioLink, 
      });
    }
  }

  Future<void> updateUserProfileField(String fieldName, String value) async {
    User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        fieldName: value,
      });
    }
  }
}
