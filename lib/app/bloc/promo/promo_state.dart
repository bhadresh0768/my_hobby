import '../../../common/models/promo_model.dart';
import '../../../common/models/offer_model.dart';

enum PromoStatus { initial, loading, success, failure, claiming, canceling }

class PromoState {
  final List<PromoCode> promos;
  final List<Offer> offers;
  final List<Map<String, dynamic>> userClaims;
  final List<Map<String, dynamic>> promoClaims;
  final PromoStatus status;
  final String? error;
  final bool claimSuccess;
  final bool cancelSuccess;
  final String? claimingPromoId;

  PromoState({
    this.promos = const [],
    this.offers = const [],
    this.userClaims = const [],
    this.promoClaims = const [],
    this.status = PromoStatus.initial,
    this.error,
    this.claimSuccess = false,
    this.cancelSuccess = false,
    this.claimingPromoId,
  });

  PromoState copyWith({
    List<PromoCode>? promos,
    List<Offer>? offers,
    List<Map<String, dynamic>>? userClaims,
    List<Map<String, dynamic>>? promoClaims,
    PromoStatus? status,
    String? error,
    bool? claimSuccess,
    bool? cancelSuccess,
    String? claimingPromoId,
  }) {
    return PromoState(
      promos: promos ?? this.promos,
      offers: offers ?? this.offers,
      userClaims: userClaims ?? this.userClaims,
      promoClaims: promoClaims ?? this.promoClaims,
      status: status ?? this.status,
      error: error,
      claimSuccess: claimSuccess ?? this.claimSuccess,
      cancelSuccess: cancelSuccess ?? this.cancelSuccess,
      claimingPromoId: claimingPromoId ?? this.claimingPromoId,
    );
  }
}
