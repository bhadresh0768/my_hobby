import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/review_repository.dart';
import 'review_event.dart';
import 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository _reviewRepository;
  StreamSubscription? _reviewsSubscription;

  ReviewBloc({required ReviewRepository reviewRepository})
      : _reviewRepository = reviewRepository,
        super(const ReviewState()) {
    on<ReviewFetchRequested>(_onFetchRequested);
    on<ReviewAddRequested>(_onAddRequested);
    on<ReviewUpdateRequested>(_onUpdateRequested);
    on<ReviewDeleteRequested>(_onDeleteRequested);
    on<ReviewReplyAdded>(_onReplyAdded);
    on<ReviewsUpdated>(_onReviewsUpdated);
  }

  Future<void> _onFetchRequested(ReviewFetchRequested event, Emitter<ReviewState> emit) async {
    emit(state.copyWith(status: ReviewStatus.loading));
    await _reviewsSubscription?.cancel();
    _reviewsSubscription = _reviewRepository.getReviews(event.businessId).listen(
      (reviews) => add(ReviewsUpdated(reviews)),
    );
  }

  Future<void> _onAddRequested(ReviewAddRequested event, Emitter<ReviewState> emit) async {
    emit(state.copyWith(status: ReviewStatus.adding));
    try {
      await _reviewRepository.addReview(event.review);
      emit(state.copyWith(status: ReviewStatus.addSuccess));
    } catch (e) {
      emit(state.copyWith(status: ReviewStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(ReviewUpdateRequested event, Emitter<ReviewState> emit) async {
    emit(state.copyWith(status: ReviewStatus.updating));
    try {
      await _reviewRepository.updateReview(event.oldReview, event.newReview);
      emit(state.copyWith(status: ReviewStatus.updateSuccess));
    } catch (e) {
      emit(state.copyWith(status: ReviewStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(ReviewDeleteRequested event, Emitter<ReviewState> emit) async {
    emit(state.copyWith(status: ReviewStatus.deleting));
    try {
      await _reviewRepository.deleteReview(event.review);
      emit(state.copyWith(status: ReviewStatus.deleteSuccess));
    } catch (e) {
      emit(state.copyWith(status: ReviewStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onReplyAdded(ReviewReplyAdded event, Emitter<ReviewState> emit) async {
    try {
      await _reviewRepository.addReply(event.businessId, event.reviewId, event.reply);
    } catch (e) {
      emit(state.copyWith(status: ReviewStatus.failure, error: e.toString()));
    }
  }

  void _onReviewsUpdated(ReviewsUpdated event, Emitter<ReviewState> emit) {
    emit(state.copyWith(status: ReviewStatus.success, reviews: event.reviews));
  }

  @override
  Future<void> close() {
    _reviewsSubscription?.cancel();
    return super.close();
  }
}
