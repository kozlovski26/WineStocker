// lib/features/auth/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/app_user.dart';

class AuthRepository {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Stream<AppUser?> get authStateChanges {
  return _auth.authStateChanges().map((firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) return null;
    
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      // You might want to fetch additional user details from Firestore
    );
  });
}

  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('Attempting sign in with email: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        print('No user returned from Firebase Auth');
        return null;
      }

      // Verify or create user document
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        final userData = {
          'id': firebaseUser.uid,
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userData);
      }

      return AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  Future<AppUser?> createUserWithEmailAndPassword(
  String email, 
  String password, 
  String firstName, 
  String lastName
) async {
  try {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) throw Exception('Failed to create user');

    // Combine first and last name for display name
    final displayName = '$firstName $lastName';

    final appUser = AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
    );

    await _firestore.collection('users').doc(appUser.id).set({
      'id': appUser.id,
      'email': appUser.email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return appUser;
  } catch (e) {
    print('Create user error: $e');
    rethrow;
  }
}

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');
      
      // Delete user data from Firestore
      final batch = _firestore.batch();
      
      // Delete user document
      batch.delete(_firestore.collection('users').doc(user.uid));
      
      // Delete user's wines collection
      final wines = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wines')
          .get();
      for (var doc in wines.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's settings
      final settings = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .get();
      for (var doc in settings.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's drunk wines
      final drunkWines = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('drunk_wines')
          .get();
      for (var doc in drunkWines.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit Firestore deletions
      await batch.commit();
      
      // Delete Firebase Auth account
      await user.delete();
      
    } catch (e) {
      print('Delete account error: $e');
      rethrow;
    }
  }
}