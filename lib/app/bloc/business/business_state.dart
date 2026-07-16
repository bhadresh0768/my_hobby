import 'package:equatable/equatable.dart';
import '../../../common/models/business_model.dart';

enum BusinessBlocStatus { initial, loading, success, submissionSuccess, error }

class BusinessState extends Equatable {
  final BusinessBlocStatus status;
  final List<Business> businesses;
  final String? errorMessage;

  const BusinessState({
    this.status = BusinessBlocStatus.initial,
    this.businesses = const [],
    this.errorMessage,
  });

  BusinessState copyWith({
    BusinessBlocStatus? status,
    List<Business>? businesses,
    String? errorMessage,
  }) {
    return BusinessState(
      status: status ?? this.status,
      businesses: businesses ?? this.businesses,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, businesses, errorMessage];
}
