import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import '../../common/models/business_model.dart';
import '../../core/app_constants.dart';

class BusinessRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> registerBusiness(Business business) async {
    await _firestore
        .collection(AppConstants.businessesCollection)
        .doc(business.id)
        .set(business.toFirestore());
    
    // Also update user document to link business if needed
    // (Optional: depending on if one user can have multiple businesses)
  }

  Future<Business?> getBusiness(String id) async {
    final doc = await _firestore.collection(AppConstants.businessesCollection).doc(id).get();
    if (doc.exists) {
      return Business.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<Business>> getBusinesses({String? category}) {
    Query query = _firestore.collection(AppConstants.businessesCollection);
    
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Business.fromFirestore(doc))
          .where((business) => business.isPubliclyVisible)
          .toList();
    });
  }

  Stream<List<Business>> getMyBusinesses(String ownerId) {
    return _firestore
        .collection(AppConstants.businessesCollection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Business.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateBusiness(Business business) async {
    await _firestore
        .collection(AppConstants.businessesCollection)
        .doc(business.id)
        .update(business.toFirestore());
  }

  Future<void> deleteBusiness(String id) async {
    try {
      // 1. Delete all images from Storage for this business
      // Images are stored under: business_images / businessId / ...
      final storageFolder = _storage.ref().child('business_images').child(id.trim());
      
      try {
        final listResult = await storageFolder.listAll();
        // Delete all files in the folder
        await Future.wait(listResult.items.map((item) => item.delete()));
      } catch (e) {
        // Log or handle storage deletion failure (e.g. folder already empty or doesn't exist)
        // We don't want to block Firestore deletion if Storage cleanup fails
        debugPrint('Storage cleanup warning for business $id: $e');
      }

      // 2. Delete from Firestore
      await _firestore.collection(AppConstants.businessesCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete business: $e');
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final tempDir = await path_provider.getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg");

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85, // Slightly lower quality for better reliability
        format: CompressFormat.jpeg,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (e) {
      // In production, consider using a logging service
      return null;
    }
  }

  Future<String> uploadBusinessImage(String businessId, File imageFile) async {
    try {
      // Ensure the file exists before attempting upload
      if (!await imageFile.exists()) {
        throw Exception('Source image file not found at ${imageFile.path}');
      }

      final File? compressedFile = await _compressImage(imageFile);
      final File fileToUpload = compressedFile ?? imageFile;

      final storageRef = _storage
          .ref()
          .child('business_images')
          .child(businessId.trim())
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Wait for the upload to complete
      final uploadTask = await storageRef.putFile(fileToUpload);
      
      // Retry getting the download URL (handles eventual consistency issues)
      int retryCount = 0;
      while (retryCount < 5) {
        try {
          return await uploadTask.ref.getDownloadURL();
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('object-not-found') && retryCount < 4) {
            retryCount++;
            // Wait increasingly longer between retries
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
            continue;
          }
          rethrow;
        }
      }
      throw Exception('Failed to retrieve download URL after multiple attempts');
    } catch (e) {
      throw Exception('Firebase Storage Upload Error: $e');
    }
  }
}
