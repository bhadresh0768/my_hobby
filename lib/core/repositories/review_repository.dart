import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/models/review_model.dart';
import '../app_constants.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReview(Review review) async {
    final businessId = review.businessId.trim();
    final businessRef = _firestore.collection(AppConstants.businessesCollection).doc(businessId);
    final reviewRef = businessRef.collection('reviews').doc();

    await _firestore.runTransaction((transaction) async {
      final businessSnapshot = await transaction.get(businessRef);
      if (!businessSnapshot.exists) {
        throw Exception("Business does not exist!");
      }

      final data = businessSnapshot.data() as Map<String, dynamic>;
      final double currentAverageRating = (data['averageRating'] ?? 0.0).toDouble();
      final int currentTotalReviews = data['totalReviews'] ?? 0;

      final int newTotalReviews = currentTotalReviews + 1;
      final double newAverageRating =
          ((currentAverageRating * currentTotalReviews) + review.rating) / newTotalReviews;

      // Use the generated reviewRef.id for the Review object's internal ID
      final reviewData = review.copyWith(id: reviewRef.id, businessId: businessId).toFirestore();

      transaction.set(reviewRef, reviewData);
      transaction.update(businessRef, {
        'averageRating': newAverageRating,
        'totalReviews': newTotalReviews,
      });
    });
  }

  Future<void> updateReview(Review oldReview, Review newReview) async {
    final businessId = newReview.businessId.trim();
    final businessRef = _firestore.collection(AppConstants.businessesCollection).doc(businessId);
    final reviewRef = businessRef.collection('reviews').doc(newReview.id.trim());

    await _firestore.runTransaction((transaction) async {
      final businessSnapshot = await transaction.get(businessRef);
      if (!businessSnapshot.exists) {
        throw Exception("Business does not exist!");
      }

      final data = businessSnapshot.data() as Map<String, dynamic>;
      final double currentAverageRating = (data['averageRating'] ?? 0.0).toDouble();
      final int currentTotalReviews = data['totalReviews'] ?? 0;

      // New Average = (TotalSum - oldRating + newRating) / TotalReviews
      final double newAverageRating =
          ((currentAverageRating * currentTotalReviews) - oldReview.rating + newReview.rating) / currentTotalReviews;

      final reviewData = newReview.copyWith(businessId: businessId).toFirestore();

      transaction.update(reviewRef, reviewData);
      transaction.update(businessRef, {
        'averageRating': newAverageRating,
      });
    });
  }

  Future<void> deleteReview(Review review) async {
    final businessId = review.businessId.trim();
    final businessRef = _firestore.collection(AppConstants.businessesCollection).doc(businessId);
    final reviewRef = businessRef.collection('reviews').doc(review.id.trim());

    await _firestore.runTransaction((transaction) async {
      final businessSnapshot = await transaction.get(businessRef);
      if (!businessSnapshot.exists) {
        throw Exception("Business does not exist!");
      }

      final data = businessSnapshot.data() as Map<String, dynamic>;
      final double currentAverageRating = (data['averageRating'] ?? 0.0).toDouble();
      final int currentTotalReviews = data['totalReviews'] ?? 0;

      final int newTotalReviews = currentTotalReviews - 1;
      double newAverageRating = 0.0;
      
      if (newTotalReviews > 0) {
        newAverageRating = ((currentAverageRating * currentTotalReviews) - review.rating) / newTotalReviews;
      }

      transaction.delete(reviewRef);
      transaction.update(businessRef, {
        'averageRating': newAverageRating,
        'totalReviews': newTotalReviews,
      });
    });
  }

  Stream<List<Review>> getReviews(String businessId) {
    return _firestore
        .collection(AppConstants.businessesCollection)
        .doc(businessId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    });
  }

  Future<void> addReply(String businessId, String reviewId, String reply) async {
    await _firestore
        .collection(AppConstants.businessesCollection)
        .doc(businessId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'ownerReply': reply,
      'ownerReplyAt': FieldValue.serverTimestamp(),
    });
  }
}
