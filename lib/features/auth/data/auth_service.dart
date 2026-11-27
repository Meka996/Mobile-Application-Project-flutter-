import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  UserCredential? _pendingRegistration;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  bool get hasPendingRegistration => _pendingRegistration != null;

  // Sign Up
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final credential =
        _pendingRegistration ??
        await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

    final user = credential.user;

    if (user == null || _auth.currentUser?.uid != user.uid) {
      throw Exception('User account was not created.');
    }

    // Firebase signs in as soon as it creates the account. Keep the credential
    // for a profile-write retry so we do not try to register the email twice.
    _pendingRegistration = credential;
    await completeProfile(uid: user.uid, name: name, phone: phone);
    _pendingRegistration = null;

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
    _pendingRegistration = null;
  }

  Future<void> completeProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user?.uid != uid || email == null) {
      throw StateError('Please sign in again to create your profile.');
    }

    final profile = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      // A retry can follow a successful write whose response was interrupted.
      if ((await transaction.get(profile)).exists) return;
      transaction.set(profile, {
        'name': name.trim(),
        'email': email,
        'phone': phone.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
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
}
