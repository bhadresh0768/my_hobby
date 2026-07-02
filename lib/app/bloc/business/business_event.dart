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

class BusinessFetchRequested extends BusinessEvent {
  final String? category;
  BusinessFetchRequested({this.category});
  @override
  List<Object?> get props => [category];
}

class BusinessUpdated extends BusinessEvent {
  final List<Business> businesses;
  BusinessUpdated(this.businesses);
  @override
  List<Object?> get props => [businesses];
}
