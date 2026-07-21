import 'package:equatable/equatable.dart';
import '../../../common/models/business_model.dart';

abstract class BusinessEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class BusinessRegisterRequested extends BusinessEvent {
  final Business business;
  BusinessRegisterRequested(this.business);
  @override
  List<Object?> get props => [business];
}

class BusinessUpdateRequested extends BusinessEvent {
  final Business business;
  BusinessUpdateRequested(this.business);
  @override
  List<Object?> get props => [business];
}

class BusinessFetchRequested extends BusinessEvent {
  final String? category;
  final String? city;
  final String sortBy;
  final double? latitude;
  final double? longitude;

  BusinessFetchRequested({
    this.category,
    this.city,
    this.sortBy = 'newest',
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [category, city, sortBy, latitude, longitude];
}

class BusinessLoadMoreRequested extends BusinessEvent {
  final String? category;
  final String? city;
  BusinessLoadMoreRequested({this.category, this.city});
  @override
  List<Object?> get props => [category, city];
}

class BusinessFetchMyBusinessesRequested extends BusinessEvent {
  final String ownerId;
  BusinessFetchMyBusinessesRequested(this.ownerId);
  @override
  List<Object?> get props => [ownerId];
}

class BusinessDeleteRequested extends BusinessEvent {
  final String id;
  BusinessDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class BusinessUpdated extends BusinessEvent {
  final List<Business> businesses;
  BusinessUpdated(this.businesses);
  @override
  List<Object?> get props => [businesses];
}

class BusinessErrorOccurred extends BusinessEvent {
  final String errorMessage;
  BusinessErrorOccurred(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}
