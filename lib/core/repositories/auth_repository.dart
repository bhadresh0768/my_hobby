import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../common/models/user_model.dart';
import '../app_constants.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10)); // Add timeout to prevent infinite loading
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
    return null;
  }

  Future<bool> checkIfUserExists(String phoneNumber) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String smsCode,
    required String name,
    required UserRole role,
  }) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    
    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user != null) {
      // Check if user already exists in Firestore
      final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!doc.exists) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          phoneNumber: userCredential.user!.phoneNumber,
          displayName: name,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toFirestore());
      }
    }
    return userCredential;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
    
    // Also update FirebaseAuth profile if needed (displayName and photoURL)
    if (data.containsKey('displayName')) {
      await _auth.currentUser?.updateDisplayName(data['displayName']);
    }
    if (data.containsKey('photoUrl')) {
      await _auth.currentUser?.updatePhotoURL(data['photoUrl']);
    }
  }

  Future<void> toggleFavorite(String uid, String businessId, bool isFavorite) async {
    final userRef = _firestore.collection(AppConstants.usersCollection).doc(uid);
    final businessRef = _firestore.collection(AppConstants.businessesCollection).doc(businessId);

    try {
      await _firestore.runTransaction((transaction) async {
        // Perform reads first (required for transactions)
        await transaction.get(userRef);
        await transaction.get(businessRef);

        // 1. Update User Favorites
        transaction.update(userRef, {
          'favorites': isFavorite
              ? FieldValue.arrayUnion([businessId])
              : FieldValue.arrayRemove([businessId]),
        });

        // 2. Update Business Favorite Count
        transaction.set(businessRef, {
          'favoriteCount': isFavorite
              ? FieldValue.increment(1)
              : FieldValue.increment(-1),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      throw Exception('Failed to update favorite: $e');
    }
  }

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final ref = _storage.ref().child('profile_images').child('$uid.jpg');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
