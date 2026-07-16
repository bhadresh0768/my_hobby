import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'promo_event.dart';
import 'promo_state.dart';
import '../../../core/repositories/promo_repository.dart';
import '../../../common/models/promo_model.dart';
import '../../../common/models/offer_model.dart';

class PromoBloc extends Bloc<PromoEvent, PromoState> {
  final PromoRepository _promoRepository;
  StreamSubscription? _promosSubscription;
  StreamSubscription? _offersSubscription;
  StreamSubscription? _userClaimsSubscription;
  StreamSubscription? _promoClaimsSubscription;

  PromoBloc({required PromoRepository promoRepository})
      : _promoRepository = promoRepository,
        super(PromoState()) {
    on<PromoLoadForBusinessRequested>(_onLoadForBusinessRequested);
    on<PromoCreateRequested>(_onCreateRequested);
    on<PromoUpdateRequested>(_onUpdateRequested);
    on<PromoDeleteRequested>(_onDeleteRequested);
    on<PromoClaimRequested>(_onClaimRequested);
    on<OfferCreateRequested>(_onOfferCreateRequested);
    on<OfferUpdateRequested>(_onOfferUpdateRequested);
    on<OfferDeleteRequested>(_onOfferDeleteRequested);
    on<UserClaimsLoadRequested>(_onUserClaimsLoadRequested);
    on<PromoClaimsLoadRequested>(_onPromoClaimsLoadRequested);
    on<PromoCancelRequested>(_onPromoCancelRequested);
    on<PromoRedeemRequested>(_onPromoRedeemRequested);
    on<_PromoErrorOccurred>(_onPromoErrorOccurred);
    on<_PromoListUpdated>(_onPromoListUpdated);
    on<_OfferListUpdated>(_onOfferListUpdated);
    on<_UserClaimsUpdated>(_onUserClaimsUpdated);
    on<_PromoClaimsUpdated>(_onPromoClaimsUpdated);
  }

  String _cleanError(dynamic e) {
    String error = e.toString();
    if (error.startsWith('Exception: ')) {
      return error.replaceFirst('Exception: ', '');
    }
    return error;
  }

  void _onPromoListUpdated(_PromoListUpdated event, Emitter<PromoState> emit) {
    emit(state.copyWith(promos: event.promos, status: PromoStatus.success));
  }

  void _onOfferListUpdated(_OfferListUpdated event, Emitter<PromoState> emit) {
    emit(state.copyWith(offers: event.offers, status: PromoStatus.success));
  }

  void _onUserClaimsUpdated(_UserClaimsUpdated event, Emitter<PromoState> emit) {
    emit(state.copyWith(userClaims: event.claims, status: PromoStatus.success));
  }

  void _onPromoClaimsUpdated(_PromoClaimsUpdated event, Emitter<PromoState> emit) {
    emit(state.copyWith(promoClaims: event.claims, status: PromoStatus.success));
  }

  void _onPromoErrorOccurred(_PromoErrorOccurred event, Emitter<PromoState> emit) {
    emit(state.copyWith(status: PromoStatus.failure, error: event.error));
  }

  Future<void> _onLoadForBusinessRequested(
    PromoLoadForBusinessRequested event,
    Emitter<PromoState> emit,
  ) async {
    emit(state.copyWith(status: PromoStatus.loading, claimSuccess: false, cancelSuccess: false));
    
    await _promosSubscription?.cancel();
    await _offersSubscription?.cancel();

    _promosSubscription = _promoRepository.getPromosForBusiness(event.businessId).listen((promos) {
      add(_PromoListUpdated(promos));
    });

    _offersSubscription = _promoRepository.getOffersForBusiness(event.businessId).listen((offers) {
      add(_OfferListUpdated(offers));
    });
  }

  Future<void> _onUserClaimsLoadRequested(UserClaimsLoadRequested event, Emitter<PromoState> emit) async {
    emit(state.copyWith(status: PromoStatus.loading, claimSuccess: false, cancelSuccess: false));
    await _userClaimsSubscription?.cancel();
    _userClaimsSubscription = _promoRepository
        .getUserClaims(event.userId, status: event.status)
        .listen(
      (claims) {
        add(_UserClaimsUpdated(claims));
      },
      onError: (e) {
        add(_PromoErrorOccurred(e.toString()));
      },
    );
  }

  Future<void> _onPromoClaimsLoadRequested(PromoClaimsLoadRequested event, Emitter<PromoState> emit) async {
    emit(state.copyWith(status: PromoStatus.loading));
    await _promoClaimsSubscription?.cancel();
    _promoClaimsSubscription = _promoRepository.getClaimsForPromo(event.promoId).listen((claims) {
      add(_PromoClaimsUpdated(claims));
    });
  }

  Future<void> _onCreateRequested(PromoCreateRequested event, Emitter<PromoState> emit) async {
    emit(state.copyWith(status: PromoStatus.loading));
    try {
      List<String> imageUrls = [];
      if (event.images.isNotEmpty) {
        imageUrls = await _promoRepository.uploadImages(event.promo.businessId, 'promos', event.images);
      }
      final newPromo = PromoCode(
        id: event.promo.id,
        businessId: event.promo.businessId,
        code: event.promo.code,
        description: event.promo.description,
        discountValue: event.promo.discountValue,
        discountType: event.promo.discountType,
        maxUsage: event.promo.maxUsage,
        currentUsage: event.promo.currentUsage,
        startDate: event.promo.startDate,
        endDate: event.promo.endDate,
        imageUrls: imageUrls,
        termsAndConditions: event.promo.termsAndConditions,
        isActive: event.promo.isActive,
        isPublic: event.promo.isPublic,
      );
      await _promoRepository.createPromoCode(newPromo);
    } catch (e) {
      emit(state.copyWith(status: PromoStatus.failure, error: _cleanError(e)));
    }
  }

  Future<void> _onUpdateRequested(PromoUpdateRequested event, Emitter<PromoState> emit) async {
    emit(state.copyWith(status: PromoStatus.loading));
    try {
      List<String> imageUrls = List.from(event.promo.imageUrls);
      if (event.newImages.isNotEmpty) {
        final newUrls = await _promoRepository.uploadImages(event.promo.businessId, 'promos', event.newImages);
        imageUrls.addAll(newUrls);
      }
      final updatedPromo = PromoCode(
        id: event.promo.id,
        businessId: event.promo.businessId,
        code: event.promo.code,
        description: event.promo.description,
        discountValue: event.promo.discountValue,
        discountType: event.promo.discountType,
        maxUsage: event.promo.maxUsage,
        currentUsage: event.promo.currentUsage,
        startDate: event.promo.startDate,
        endDate: event.promo.endDate,
        imageUrls: imageUrls,
        termsAndConditions: event.promo.termsAndConditions,
        isActive: event.promo.isActive,
        isPublic: event.promo.isPublic,
      );
      await _promoRepository.updatePromoCode(updatedPromo);
    } catch (e) {
      emit(state.copyWith(status: PromoStatus.failure, error: _cleanError(e)));
    }
  }

  Future<void> _onDeleteRequested(PromoDeleteRequested event, Emitter<PromoState> emit) async {
    try {
      await _promoRepository.deletePromoCode(event.promoId);
    } catch (e) {
      emit(state.copyWith(status: PromoStatus.failure, error: _cleanError(e)));
    }
  }

  Future<void> _onClaimRequested(PromoClaimRequested event, Emitter<PromoState> emit) async {
    emit(state.copyWith(
      status: PromoStatus.claiming, 
      claimingPromoId: event.promoId,
      claimSuccess: false, 
      cancelSuccess: false,
    ));
    try {
      await _promoRepository.claimPromoCode(
        event.userId,
        event.promoId,
        userName: event.userName,
        userPhone: event.userPhone,
      );
      emit(state.copyWith(status: PromoStatus.success, claimSuccess: true, claimingPromoId: null));
    } catch (e) {
      emit(state.copyWith(status: PromoStatus.failure, error: _cleanError(e), claimingPromoId: null));
    }
  }

  Future<void> _onOfferCreateRequested(OfferCreateRequested event, Emitter<PromoState> emit) async {
    emit(state.copyWith(status: PromoStatus.loading));
    try {
      List<String> imageUrls = [];
      if (event.images.isNotEmpty) {
        imageUrls = await _promoRepository.uploadImages(event.offer.businessId, 'offers', event.images);
      }
      final newOffer = Offer(
        id: event.offer.id,
        businessId: event.offer.businessId,
        title: event.offer.title,
        description: event.offer.description,
        imageUrls: imageUrls,
        startDate: event.offer.startDate,
        endDate: event.offer.endDate,
        termsAndConditions: event.offer.termsAndConditions,
        isActive: event.offer.isActive,
      );
      await _promoRepository.createOffer(newOffer);
    } catch (e) {
      emit(state.copyWith(status: PromoStatus.failure, error: _cleanError(e)));
    }
  }

  Future<void> _onOfferUpdateRequested(OfferUpdateRequested event, Emitter<PromoState> emit) async {
    emit(state.copyWith(status: PromoStatus.loading));
    try {
      List<String> imageUrls = List.from(event.offer.imageUrls);
      if (event.newImages.isNotEmpty) {
        final newUrls = await _promoRepository.uploadImages(event.offer.businessId, 'offers', event.newImages);
        imageUrls.addAll(newUrls);
      }
      final updatedOffer = Offer(
        id: event.offer.id,
        businessId: event.offer.businessId,
        title: event.offer.title,
        description: event.offer.description,
        imageUrls: imageUrls,
        startDate: event.offer.startDate,
        endDate: event.offer.endDate,
        termsAndConditions: event.offer.termsAndConditions,
        isActive: event.offer.isActive,
      );
      await _promoRepository.updateOffer(updatedOffer);
    } catch (e) {
      emit(state.copyWith(status: PromoStatus.failure, error: _cleanError(e)));
    }
  }

  Future<void> _onOfferDeleteRequested(OfferDeleteRequested event, Emitter<PromoState> emit) async {
    try {
      await _promoRepository.deleteOffer(event.offerId);
    } catch (e) {
      emit(state.copyWith(status: PromoStatus.failure, error: _cleanError(e)));
    }
  }

  Future<void> _onPromoCancelRequested(PromoCancelRequested event, Emitter<PromoState> emit) async {
    emit(state.copyWith(status: PromoStatus.canceling, cancelSuccess: false, claimSuccess: false));
    try {
      await _promoRepository.cancelPromoCode(event.userId, event.promoId);
      emit(state.copyWith(status: PromoStatus.success, cancelSuccess: true));
    } catch (e) {
      emit(state.copyWith(status: PromoStatus.failure, error: _cleanError(e)));
    }
  }

  Future<void> _onPromoRedeemRequested(PromoRedeemRequested event, Emitter<PromoState> emit) async {
    try {
      await _promoRepository.redeemPromoCode(event.userId, event.promoId, event.verificationCode);
    } catch (e) {
      emit(state.copyWith(status: PromoStatus.failure, error: _cleanError(e)));
    }
  }

  @override
  Future<void> close() {
    _promosSubscription?.cancel();
    _offersSubscription?.cancel();
    _userClaimsSubscription?.cancel();
    _promoClaimsSubscription?.cancel();
    return super.close();
  }
}

class _PromoListUpdated extends PromoEvent {
  final List<PromoCode> promos;
  _PromoListUpdated(this.promos);
}

class _OfferListUpdated extends PromoEvent {
  final List<Offer> offers;
  _OfferListUpdated(this.offers);
}

class _UserClaimsUpdated extends PromoEvent {
  final List<Map<String, dynamic>> claims;
  _UserClaimsUpdated(this.claims);
}

class _PromoClaimsUpdated extends PromoEvent {
  final List<Map<String, dynamic>> claims;
  _PromoClaimsUpdated(this.claims);
}

class _PromoErrorOccurred extends PromoEvent {
  final String error;
  _PromoErrorOccurred(this.error);
}
