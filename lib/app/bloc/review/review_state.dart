import '../../../common/models/review_model.dart';

enum ReviewStatus { initial, loading, success, adding, addSuccess, updating, updateSuccess, deleting, deleteSuccess, failure }

class ReviewState {
  final ReviewStatus status;
  final List<Review> reviews;
  final String? error;

  const ReviewState({
    this.status = ReviewStatus.initial,
    this.reviews = const [],
    this.error,
  });

  ReviewState copyWith({
    ReviewStatus? status,
    List<Review>? reviews,
    String? error,
  }) {
    return ReviewState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
      error: error ?? this.error,
    );
  }
}
