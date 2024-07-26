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
    print('Signing in with email: $email');
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      print('Sign-in successful');
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String occupation,
  }) async {
    print('Creating user with email: $email');
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      User? user = userCredential.user;

      if (user != null) {
        print('User created with UID: ${user.uid}');
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'name': name,
          'occupation': occupation,
          'bio': '',
          'profileImageUrl': '',
          'connections': 0,
        });
        print('User data added to Firestore');

        // Initialize accepted connections subcollection
        await _firestore.collection('users').doc(user.uid).collection('connections').doc('accepted').set({
          'accepted': [],
        });
        print('Connections subcollection initialized');
      }
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> addPost(String uid, String title, String description, String postId) async {
    print('Adding post for UID: $uid');
    try {
      await _firestore.collection('users').doc(uid).collection('posts').add({
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
        'description': description,
        'postId': postId,
      });
      print('Post added successfully');
    } catch (e) {
      print('Error adding post: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserPosts(String uid) async {
    print('Fetching posts for UID: $uid');
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').doc(uid).collection('posts').orderBy('timestamp', descending: true).get();
      List<Map<String, dynamic>> posts = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure post ID is included
        return data;
      }).toList();
      print('Posts fetched: $posts');
      return posts;
    } catch (e) {
      print('Error fetching user posts: $e');
      return [];
    }
  }

  Future<void> updatePost(String uid, String title, String description, String postId) async {
    print('Updating post with ID: $postId for UID: $uid');
    try {
      await _firestore.collection('users').doc(uid).collection('posts').doc(postId).update({
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
        'description': description,
        'postId': postId,
      });
      print('Post updated successfully');
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    print('Signing out');
    try {
      await _firebaseAuth.signOut();
      print('Sign-out successful');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Methods for managing connections

  Future<void> addConnection(String uid, String connectionUid) async {
    print('Adding connection from UID: $uid to UID: $connectionUid');
    try {
      // Add to accepted connections for both users
      await _firestore.collection('users').doc(uid).collection('connections').doc('accepted').update({
        'accepted': FieldValue.arrayUnion([connectionUid])
      });

      await _firestore.collection('users').doc(connectionUid).collection('connections').doc('accepted').update({
        'accepted': FieldValue.arrayUnion([uid])
      });

      print('Connection added successfully');
    } catch (e) {
      print('Error adding connection: $e');
      rethrow;
    }
  }

  Future<void> removeConnection(String uid, String connectionUid) async {
    print('Removing connection from UID: $uid to UID: $connectionUid');
    try {
      // Remove from accepted connections for both users
      await _firestore.collection('users').doc(uid).collection('connections').doc('accepted').update({
        'accepted': FieldValue.arrayRemove([connectionUid])
      });

      await _firestore.collection('users').doc(connectionUid).collection('connections').doc('accepted').update({
        'accepted': FieldValue.arrayRemove([uid])
      });

      print('Connection removed successfully');
    } catch (e) {
      print('Error removing connection: $e');
      rethrow;
    }
  }
}
