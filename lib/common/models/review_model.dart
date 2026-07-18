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
    Map data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userPhotoUrl: data['userPhotoUrl'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      ownerReply: data['ownerReply'],
      ownerReplyAt: data['ownerReplyAt'] != null ? (data['ownerReplyAt'] as Timestamp).toDate() : null,
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
