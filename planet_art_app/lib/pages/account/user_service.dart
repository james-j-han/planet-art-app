import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user profile data
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Fetch user posts
  Future<List<Map<String, dynamic>>> getUserPosts(String uid) async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').doc(uid).collection('posts').orderBy('timestamp', descending: true).get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching user posts: $e");
      return [];
    }
  }

  // Add a new post
  Future<void> addPost(String uid, String? imageUrl, String description, String title, String postId) async {
    try {
      await _firestore.collection('users').doc(uid).collection('posts').add({
        'imageUrl': imageUrl,
        'description': description,
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
        'postId': postId,
      });
    } catch (e) {
      print("Error adding post: $e");
    }
  }

  // Save or update user profile
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

  // Update a specific user profile field
  Future<void> updateUserProfileField(String fieldName, String value) async {
    User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        fieldName: value,
      });
    }
  }

  // Delete a post from both users and explore_posts collections
  Future<void> deletePost(String uid, String postId) async {
    try {
      print('Attempting to delete post with ID: $postId');
      print('User ID: $uid');

      // Delete from 'users' collection
      await _firestore.collection('users').doc(uid).collection('posts').doc(postId).delete();
      print('Deleted from users collection');

      // Delete from 'explore_posts' collection
      await _firestore.collection('explore_posts').doc(postId).delete();
      print('Deleted from explore_posts collection');
    } catch (e) {
      print('Error during deletion: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  // Get the number of connections for a user
  Future<int> getConnectionCount(String uid) async {
    try {
      DocumentSnapshot connectionsDoc = await _firestore.collection('users').doc(uid).collection('connections').doc('accepted').get();
      Map<String, dynamic>? data = connectionsDoc.data() as Map<String, dynamic>?;
      List<dynamic> connections = data?['accepted'] ?? [];
      return connections.length;
    } catch (e) {
      print('Error fetching connection count: $e');
      return 0; // Return 0 if there is an error
    }
  }

  // Check if a user is connected
  Future<bool> isConnected(String currentUid, String targetUid) async {
    try {
      DocumentSnapshot connectionsDoc = await _firestore.collection('users').doc(currentUid).collection('connections').doc('accepted').get();
      Map<String, dynamic>? data = connectionsDoc.data() as Map<String, dynamic>?;
      List<dynamic> connections = data?['accepted'] ?? [];
      return connections.contains(targetUid);
    } catch (e) {
      print('Error checking connection status: $e');
      return false;
    }
  }

  // Add a connection
  Future<void> addConnection(String currentUid, String targetUid) async {
    try {
      DocumentReference userConnectionsRef = _firestore.collection('users').doc(currentUid).collection('connections').doc('accepted');
      DocumentSnapshot userConnectionsDoc = await userConnectionsRef.get();
      List<dynamic> connections = (userConnectionsDoc.data() as Map<String, dynamic>?)?['accepted'] ?? [];
      if (!connections.contains(targetUid)) {
        connections.add(targetUid);
        await userConnectionsRef.update({'accepted': connections});
      }
    } catch (e) {
      print('Error adding connection: $e');
    }
  }

  // Remove a connection
  Future<void> removeConnection(String currentUid, String targetUid) async {
    try {
      DocumentReference userConnectionsRef = _firestore.collection('users').doc(currentUid).collection('connections').doc('accepted');
      DocumentSnapshot userConnectionsDoc = await userConnectionsRef.get();
      List<dynamic> connections = (userConnectionsDoc.data() as Map<String, dynamic>?)?['accepted'] ?? [];
      connections.remove(targetUid);
      await userConnectionsRef.update({'accepted': connections});
    } catch (e) {
      print('Error removing connection: $e');
    }
  }
}
