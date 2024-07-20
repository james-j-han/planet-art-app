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

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
