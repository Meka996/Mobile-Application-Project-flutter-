import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('User account was not created.');

    await _firestore.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': user.email,
      'phone': phone.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // Login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get User Profile
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(
    String uid,
  ) async {
    return _firestore.collection('users').doc(uid).get();
  }

  // Update User Profile
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
    });
  }

  // Change password after confirming the user's current password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      throw Exception('Please sign in again.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
