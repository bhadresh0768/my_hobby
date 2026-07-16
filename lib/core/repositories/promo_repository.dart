import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../common/models/promo_model.dart';
import '../../common/models/offer_model.dart';
import '../app_constants.dart';

class PromoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Promo Codes ---

  Future<void> createPromoCode(PromoCode promo) async {
    await _firestore
        .collection(AppConstants.promoCodesCollection)
        .doc(promo.id)
        .set(promo.toFirestore());
  }

  Future<void> updatePromoCode(PromoCode promo) async {
    await _firestore
        .collection(AppConstants.promoCodesCollection)
        .doc(promo.id)
        .update(promo.toFirestore());
  }

  Future<void> deletePromoCode(String id) async {
    await _firestore.collection(AppConstants.promoCodesCollection).doc(id).delete();
  }

  Stream<List<PromoCode>> getPromosForBusiness(String businessId) {
    return _firestore
        .collection(AppConstants.promoCodesCollection)
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PromoCode.fromFirestore(doc)).toList());
  }

  Future<void> claimPromoCode(String userId, String promoId, {String? userName, String? userPhone}) async {
    final promoRef = _firestore.collection(AppConstants.promoCodesCollection).doc(promoId);
    final claimRef = _firestore.collection(AppConstants.claimsCollection).doc('${promoId}_$userId');

    // Generate a unique 10-digit verification code safely
    final String verificationCode = List.generate(10, (_) => Random().nextInt(10)).join();

    return _firestore.runTransaction((transaction) async {
      final promoDoc = await transaction.get(promoRef);
      if (!promoDoc.exists) throw Exception('Promo code not found');

      final promo = PromoCode.fromFirestore(promoDoc);
      if (!promo.isAvailable) throw Exception('Promo code is not available');

      final claimDoc = await transaction.get(claimRef);
      if (claimDoc.exists) throw Exception('You have already claimed this promo code');

      transaction.update(promoRef, {'currentUsage': promo.currentUsage + 1});
      transaction.set(claimRef, {
        'userId': userId,
        'promoId': promoId,
        'businessId': promo.businessId,
        'userName': userName ?? 'N/A',
        'userPhone': userPhone ?? 'N/A',
        'verificationCode': verificationCode,
        'claimedAt': FieldValue.serverTimestamp(),
        'status': 'applied', // 'applied', 'redeemed'
      });
    });
  }

  Future<void> cancelPromoCode(String userId, String promoId) async {
    final promoRef = _firestore.collection(AppConstants.promoCodesCollection).doc(promoId);
    final claimRef = _firestore.collection(AppConstants.claimsCollection).doc('${promoId}_$userId');

    return _firestore.runTransaction((transaction) async {
      final promoDoc = await transaction.get(promoRef);
      if (!promoDoc.exists) throw Exception('Promo code not found');

      final promo = PromoCode.fromFirestore(promoDoc);
      final claimDoc = await transaction.get(claimRef);
      if (!claimDoc.exists) throw Exception('No claim found to cancel');

      transaction.update(promoRef, {'currentUsage': promo.currentUsage - 1});
      transaction.delete(claimRef);
    });
  }

  Future<void> redeemPromoCode(String userId, String promoId, String inputCode) async {
    final claimDoc = await _firestore.collection(AppConstants.claimsCollection).doc('${promoId}_$userId').get();
    
    if (!claimDoc.exists) throw Exception('No claim record found');
    
    final storedCode = claimDoc.data()?['verificationCode'];
    if (storedCode != inputCode) {
      throw Exception('Invalid Verification Code. Please check the code on the customer\'s screen.');
    }

    await _firestore
        .collection(AppConstants.claimsCollection)
        .doc('${promoId}_$userId')
        .update({'status': 'redeemed', 'redeemedAt': FieldValue.serverTimestamp()});
  }

  Stream<List<Map<String, dynamic>>> getClaimsForPromo(String promoId) {
    return _firestore
        .collection(AppConstants.claimsCollection)
        .where('promoId', isEqualTo: promoId)
        .snapshots()
        .map((snapshot) {
      final claims = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      // Sort manually in memory to avoid needing a Firestore composite index
      claims.sort((a, b) {
        final aTime = a['claimedAt'] as Timestamp?;
        final bTime = b['claimedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // Descending
      });
      return claims;
    });
  }

  Stream<List<Map<String, dynamic>>> getUserClaims(String userId, {String? status}) {
    Query query = _firestore
        .collection(AppConstants.claimsCollection)
        .where('userId', isEqualTo: userId);

    if (status != null && status != 'All') {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }

    return query.snapshots().asyncMap((snapshot) async {
      final List<Map<String, dynamic>> results = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final promoId = data['promoId'];
        if (promoId == null) continue;

        final promoDoc = await _firestore
            .collection(AppConstants.promoCodesCollection)
            .doc(promoId)
            .get();

        if (promoDoc.exists) {
          results.add({
            ...data,
            'promo': PromoCode.fromFirestore(promoDoc),
          });
        }
      }

      // Sort DESC by claimedAt
      results.sort((a, b) {
        final aTime = a['claimedAt'] as Timestamp?;
        final bTime = b['claimedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return results;
    });
  }

  // --- Offers ---

  Future<void> createOffer(Offer offer) async {
    await _firestore
        .collection(AppConstants.offersCollection)
        .doc(offer.id)
        .set(offer.toFirestore());
  }

  Future<void> updateOffer(Offer offer) async {
    await _firestore
        .collection(AppConstants.offersCollection)
        .doc(offer.id)
        .update(offer.toFirestore());
  }

  Future<void> deleteOffer(String id) async {
    await _firestore.collection(AppConstants.offersCollection).doc(id).delete();
  }

  Stream<List<Offer>> getOffersForBusiness(String businessId) {
    return _firestore
        .collection(AppConstants.offersCollection)
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Offer.fromFirestore(doc)).toList());
  }

  // --- Image Upload ---

  Future<List<String>> uploadImages(String businessId, String type, List<File> images) async {
    List<String> urls = [];
    for (var image in images) {
      final ref = _storage
          .ref()
          .child('business_content')
          .child(businessId)
          .child(type) // 'promos' or 'offers'
          .child('${DateTime.now().millisecondsSinceEpoch}_${urls.length}.jpg');
      
      final uploadTask = await ref.putFile(image);
      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }
}
