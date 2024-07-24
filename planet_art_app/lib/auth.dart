import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String occupation,
  }) async {
    UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    
    User? user = userCredential.user;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'name': name,
        'occupation': occupation,
        'bio': '',
        'profileImageUrl': '',
        'connections': 0,
      });
    }
  }
Future<void> addPost(String uid, String title, String content) async {
    try {
      await _firestore.collection('users').doc(uid).collection('posts').add({
        'title': title,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Post added successfully");
    } catch (e) {
      print("Error adding post: $e");
    }
  }

  // Function to retrieve user posts
  Future<List<Map<String, dynamic>>> getUserPosts(String uid) async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').doc(uid).collection('posts').orderBy('timestamp', descending: true).get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching user posts: $e");
      return [];
    }
  }

  // Function to update a post
  Future<void> updatePost(String uid, String postId, String title, String content) async {
    try {
      await _firestore.collection('users').doc(uid).collection('posts').doc(postId).update({
        'title': title,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Post updated successfully");
    } catch (e) {
      print("Error updating post: $e");
    }
  }

  // Function to delete a post
  Future<void> deletePost(String uid, String postId) async {
    try {
      await _firestore.collection('users').doc(uid).collection('posts').doc(postId).delete();
      print("Post deleted successfully");
    } catch (e) {
      print("Error deleting post: $e");
    }
  }
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
