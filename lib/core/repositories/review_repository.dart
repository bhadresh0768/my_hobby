import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/models/review_model.dart';
import '../app_constants.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReview(Review review) async {
    final businessRef = _firestore.collection(AppConstants.businessesCollection).doc(review.businessId);
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

      transaction.set(reviewRef, review.toFirestore());
      transaction.update(businessRef, {
        'averageRating': newAverageRating,
        'totalReviews': newTotalReviews,
      });
    });
  }

  Future<void> updateReview(Review oldReview, Review newReview) async {
    final businessRef = _firestore.collection(AppConstants.businessesCollection).doc(newReview.businessId);
    final reviewRef = businessRef.collection('reviews').doc(newReview.id);

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

      transaction.update(reviewRef, newReview.toFirestore());
      transaction.update(businessRef, {
        'averageRating': newAverageRating,
      });
    });
  }

  Future<void> deleteReview(Review review) async {
    final businessRef = _firestore.collection(AppConstants.businessesCollection).doc(review.businessId);
    final reviewRef = businessRef.collection('reviews').doc(review.id);

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
