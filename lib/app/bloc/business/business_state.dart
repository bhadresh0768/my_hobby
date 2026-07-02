import 'package:equatable/equatable.dart';
import '../../../common/models/business_model.dart';

enum BusinessStatus { initial, loading, success, error }

class BusinessState extends Equatable {
  final BusinessStatus status;
  final List<Business> businesses;
  final String? errorMessage;

  const BusinessState({
    this.status = BusinessStatus.initial,
    this.businesses = const [],
    this.errorMessage,
  });

  BusinessState copyWith({
    BusinessStatus? status,
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
