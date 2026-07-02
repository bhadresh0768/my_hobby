import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/models/business_model.dart';
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

  Future<void> _onFetchRequested(BusinessFetchRequested event, Emitter<BusinessState> emit) async {
    emit(state.copyWith(status: BusinessStatus.loading));
    _businessesSubscription?.cancel();
    
    // Use restartable or switchMap logic manually for the subscription
    await emit.forEach<List<Business>>(
      _businessRepository.getBusinesses(category: event.category),
      onData: (businesses) => state.copyWith(
        status: BusinessStatus.success,
        businesses: businesses,
      ),
      onError: (error, stackTrace) => state.copyWith(
        status: BusinessStatus.error,
        errorMessage: error.toString(),
      ),
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
