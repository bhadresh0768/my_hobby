import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/business_repository.dart';
import 'business_event.dart';
import 'business_state.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final BusinessRepository _businessRepository;
  StreamSubscription? _businessesSubscription;

  BusinessBloc({required BusinessRepository businessRepository})
      : _businessRepository = businessRepository,
        super(const BusinessState()) {
    on<BusinessRegisterRequested>(_onRegisterRequested);
    on<BusinessFetchRequested>(_onFetchRequested);
    on<BusinessUpdated>(_onUpdated);
  }

  Future<void> _onRegisterRequested(
      BusinessRegisterRequested event, Emitter<BusinessState> emit) async {
    emit(state.copyWith(status: BusinessStatus.loading));
    try {
      await _businessRepository.registerBusiness(event.business);
      emit(state.copyWith(status: BusinessStatus.success));
    } catch (e) {
      emit(state.copyWith(status: BusinessStatus.error, errorMessage: e.toString()));
    }
  }

  void _onFetchRequested(BusinessFetchRequested event, Emitter<BusinessState> emit) {
    emit(state.copyWith(status: BusinessStatus.loading));
    _businessesSubscription?.cancel();
    _businessesSubscription = _businessRepository.getBusinesses(category: event.category).listen(
      (businesses) => add(BusinessUpdated(businesses)),
      onError: (error) => emit(state.copyWith(status: BusinessStatus.error, errorMessage: error.toString())),
    );
  }

  void _onUpdated(BusinessUpdated event, Emitter<BusinessState> emit) {
    emit(state.copyWith(status: BusinessStatus.success, businesses: event.businesses));
  }

  @override
  Future<void> close() {
    _businessesSubscription?.cancel();
    return super.close();
  }
}
