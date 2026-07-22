import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/business_repository.dart';
import 'business_event.dart';
import 'business_state.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final BusinessRepository _businessRepository;

  BusinessBloc({required BusinessRepository businessRepository})
      : _businessRepository = businessRepository,
        super(const BusinessState()) {
    on<BusinessRegisterRequested>(_onRegisterRequested);
    on<BusinessUpdateRequested>(_onUpdateRequested);
    on<BusinessFetchRequested>(_onFetchRequested);
    on<BusinessLoadMoreRequested>(_onLoadMoreRequested);
    on<BusinessFetchMyBusinessesRequested>(_onFetchMyBusinessesRequested);
    on<BusinessDeleteRequested>(_onDeleteRequested);
    on<BusinessUpdated>(_onUpdated);
    on<BusinessErrorOccurred>(_onErrorOccurred);
  }

  Future<void> _onRegisterRequested(
      BusinessRegisterRequested event, Emitter<BusinessState> emit) async {
    emit(state.copyWith(status: BusinessBlocStatus.loading));
    try {
      await _businessRepository.registerBusiness(event.business);
      emit(state.copyWith(status: BusinessBlocStatus.submissionSuccess));
    } catch (e) {
      emit(state.copyWith(status: BusinessBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
      BusinessUpdateRequested event, Emitter<BusinessState> emit) async {
    emit(state.copyWith(status: BusinessBlocStatus.loading));
    try {
      await _businessRepository.updateBusiness(event.business);
      emit(state.copyWith(status: BusinessBlocStatus.submissionSuccess));
    } catch (e) {
      emit(state.copyWith(status: BusinessBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onFetchRequested(BusinessFetchRequested event, Emitter<BusinessState> emit) async {
    emit(state.copyWith(
      status: BusinessBlocStatus.loading,
      businesses: [],
      sortBy: event.sortBy,
      selectedCity: event.city,
      latitude: event.latitude,
      longitude: event.longitude,
    ));

    try {
      var result = await _businessRepository.getBusinesses(
        category: event.category,
        city: event.city,
        sortBy: event.sortBy,
        latitude: event.latitude,
        longitude: event.longitude,
      );

      // Fallback: If no businesses in current city, fetch top rated globally
      if (result.businesses.isEmpty && event.city != null) {
        result = await _businessRepository.getBusinesses(
          category: event.category,
          city: null, // Global
          sortBy: 'top_rated',
        );
      }

      emit(state.copyWith(
        status: BusinessBlocStatus.success,
        businesses: result.businesses,
        lastDoc: result.lastDoc,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(status: BusinessBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(BusinessLoadMoreRequested event, Emitter<BusinessState> emit) async {
    if (!state.hasMore || state.isFetchingMore || state.status == BusinessBlocStatus.loading) return;

    emit(state.copyWith(isFetchingMore: true));

    try {
      final result = await _businessRepository.getBusinesses(
        category: event.category,
        city: event.city ?? state.selectedCity,
        lastDoc: state.lastDoc,
        sortBy: state.sortBy,
        latitude: state.latitude,
        longitude: state.longitude,
      );

      emit(state.copyWith(
        isFetchingMore: false,
        businesses: [...state.businesses, ...result.businesses],
        lastDoc: result.lastDoc,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(isFetchingMore: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onFetchMyBusinessesRequested(
      BusinessFetchMyBusinessesRequested event, Emitter<BusinessState> emit) async {
    emit(state.copyWith(status: BusinessBlocStatus.loading));
    
    try {
      final stream = _businessRepository.getMyBusinesses(event.ownerId);
      
      await emit.forEach(
        stream,
        onData: (businesses) => state.copyWith(status: BusinessBlocStatus.success, businesses: businesses),
        onError: (error, stackTrace) => state.copyWith(status: BusinessBlocStatus.error, errorMessage: error.toString()),
      );
    } catch (e) {
      emit(state.copyWith(status: BusinessBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
      BusinessDeleteRequested event, Emitter<BusinessState> emit) async {
    try {
      await _businessRepository.deleteBusiness(event.id);
      // Manually remove from state since we switched to pagination/futures
      final updatedList = state.businesses.where((b) => b.id != event.id).toList();
      emit(state.copyWith(businesses: updatedList));
    } catch (e) {
      emit(state.copyWith(status: BusinessBlocStatus.error, errorMessage: e.toString()));
    }
  }

  void _onUpdated(BusinessUpdated event, Emitter<BusinessState> emit) {
    emit(state.copyWith(status: BusinessBlocStatus.success, businesses: event.businesses));
  }

  void _onErrorOccurred(BusinessErrorOccurred event, Emitter<BusinessState> emit) {
    emit(state.copyWith(status: BusinessBlocStatus.error, errorMessage: event.errorMessage));
  }
}
