import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String businessId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? ownerReply;
  final DateTime? ownerReplyAt;

  Review({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.ownerReply,
    this.ownerReplyAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    try {
      Map data = doc.data() as Map<String, dynamic>;
      return Review(
        id: doc.id,
        businessId: data['businessId'] ?? '',
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? 'Anonymous',
        userPhotoUrl: data['userPhotoUrl'],
        rating: (data['rating'] ?? 0.0).toDouble(),
        comment: data['comment'] ?? '',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        ownerReply: data['ownerReply'],
        ownerReplyAt: data['ownerReplyAt'] != null ? (data['ownerReplyAt'] as Timestamp).toDate() : null,
      );
    } catch (e) {
      // Create a dummy review to avoid crashing the list, but log the error
      return Review(
        id: doc.id,
        businessId: '',
        userId: '',
        userName: 'Error Loading Review',
        rating: 0,
        comment: 'This review could not be loaded: $e',
        createdAt: DateTime.now(),
      );
    }
  }

  Review copyWith({
    String? id,
    String? businessId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    double? rating,
    String? comment,
    DateTime? createdAt,
    String? ownerReply,
    DateTime? ownerReplyAt,
  }) {
    return Review(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      ownerReply: ownerReply ?? this.ownerReply,
      ownerReplyAt: ownerReplyAt ?? this.ownerReplyAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerReply': ownerReply,
      'ownerReplyAt': ownerReplyAt != null ? Timestamp.fromDate(ownerReplyAt!) : null,
    };
  }
}
