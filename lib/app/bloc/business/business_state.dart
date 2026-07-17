import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/models/business_model.dart';

enum BusinessBlocStatus { initial, loading, success, submissionSuccess, error }

class BusinessState extends Equatable {
  final BusinessBlocStatus status;
  final List<Business> businesses;
  final String? errorMessage;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final bool isFetchingMore;

  const BusinessState({
    this.status = BusinessBlocStatus.initial,
    this.businesses = const [],
    this.errorMessage,
    this.hasMore = true,
    this.lastDoc,
    this.isFetchingMore = false,
  });

  BusinessState copyWith({
    BusinessBlocStatus? status,
    List<Business>? businesses,
    String? errorMessage,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    bool? isFetchingMore,
  }) {
    return BusinessState(
      status: status ?? this.status,
      businesses: businesses ?? this.businesses,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }

  @override
  List<Object?> get props => [status, businesses, errorMessage, hasMore, lastDoc, isFetchingMore];
}
