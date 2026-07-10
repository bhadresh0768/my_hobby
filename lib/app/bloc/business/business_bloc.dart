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
    on<BusinessUpdateRequested>(_onUpdateRequested);
    on<BusinessFetchRequested>(_onFetchRequested);
    on<BusinessFetchMyBusinessesRequested>(_onFetchMyBusinessesRequested);
    on<BusinessDeleteRequested>(_onDeleteRequested);
    on<BusinessUpdated>(_onUpdated);
    on<BusinessErrorOccurred>(_onErrorOccurred);
  }

  Future<void> _onRegisterRequested(
      BusinessRegisterRequested event, Emitter<BusinessState> emit) async {
    emit(state.copyWith(status: BusinessStatus.loading));
    try {
      await _businessRepository.registerBusiness(event.business);
      emit(state.copyWith(status: BusinessStatus.submissionSuccess));
    } catch (e) {
      emit(state.copyWith(status: BusinessStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
      BusinessUpdateRequested event, Emitter<BusinessState> emit) async {
    emit(state.copyWith(status: BusinessStatus.loading));
    try {
      await _businessRepository.updateBusiness(event.business);
      emit(state.copyWith(status: BusinessStatus.submissionSuccess));
    } catch (e) {
      emit(state.copyWith(status: BusinessStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onFetchRequested(BusinessFetchRequested event, Emitter<BusinessState> emit) async {
    emit(state.copyWith(status: BusinessStatus.loading));
    
    await _businessesSubscription?.cancel();
    
    final stream = _businessRepository.getBusinesses(category: event.category);
    
    _businessesSubscription = stream.listen(
      (businesses) => add(BusinessUpdated(businesses)),
      onError: (error) => add(BusinessErrorOccurred(error.toString())),
    );
  }

  Future<void> _onFetchMyBusinessesRequested(
      BusinessFetchMyBusinessesRequested event, Emitter<BusinessState> emit) async {
    emit(state.copyWith(status: BusinessStatus.loading));
    
    await _businessesSubscription?.cancel();
    
    final stream = _businessRepository.getMyBusinesses(event.ownerId);
    
    _businessesSubscription = stream.listen(
      (businesses) => add(BusinessUpdated(businesses)),
      onError: (error) => add(BusinessErrorOccurred(error.toString())),
    );
  }

  Future<void> _onDeleteRequested(
      BusinessDeleteRequested event, Emitter<BusinessState> emit) async {
    try {
      await _businessRepository.deleteBusiness(event.id);
      // The stream subscription will automatically update the list
    } catch (e) {
      emit(state.copyWith(status: BusinessStatus.error, errorMessage: e.toString()));
    }
  }

  void _onUpdated(BusinessUpdated event, Emitter<BusinessState> emit) {
    emit(state.copyWith(status: BusinessStatus.success, businesses: event.businesses));
  }

  void _onErrorOccurred(BusinessErrorOccurred event, Emitter<BusinessState> emit) {
    emit(state.copyWith(status: BusinessStatus.error, errorMessage: event.errorMessage));
  }

  @override
  Future<void> close() {
    _businessesSubscription?.cancel();
    return super.close();
  }
}
