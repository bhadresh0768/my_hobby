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
  final String sortBy;
  final String? selectedCity;
  final double? latitude;
  final double? longitude;

  const BusinessState({
    this.status = BusinessBlocStatus.initial,
    this.businesses = const [],
    this.errorMessage,
    this.hasMore = true,
    this.lastDoc,
    this.isFetchingMore = false,
    this.sortBy = 'newest',
    this.selectedCity,
    this.latitude,
    this.longitude,
  });

  BusinessState copyWith({
    BusinessBlocStatus? status,
    List<Business>? businesses,
    String? errorMessage,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    bool? isFetchingMore,
    String? sortBy,
    String? selectedCity,
    double? latitude,
    double? longitude,
  }) {
    return BusinessState(
      status: status ?? this.status,
      businesses: businesses ?? this.businesses,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      sortBy: sortBy ?? this.sortBy,
      selectedCity: selectedCity ?? this.selectedCity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [
        status,
        businesses,
        errorMessage,
        hasMore,
        lastDoc,
        isFetchingMore,
        sortBy,
        selectedCity,
        latitude,
        longitude
      ];
}
