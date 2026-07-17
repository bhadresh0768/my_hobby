import '../../../common/models/review_model.dart';

abstract class ReviewEvent {}

class ReviewFetchRequested extends ReviewEvent {
  final String businessId;
  ReviewFetchRequested(this.businessId);
}

class ReviewAddRequested extends ReviewEvent {
  final Review review;
  ReviewAddRequested(this.review);
}

class ReviewReplyAdded extends ReviewEvent {
  final String businessId;
  final String reviewId;
  final String reply;
  ReviewReplyAdded({
    required this.businessId,
    required this.reviewId,
    required this.reply,
  });
}

class ReviewsUpdated extends ReviewEvent {
  final List<Review> reviews;
  ReviewsUpdated(this.reviews);
}
