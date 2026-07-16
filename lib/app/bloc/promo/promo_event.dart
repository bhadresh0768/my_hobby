import 'dart:io';
import '../../../common/models/promo_model.dart';
import '../../../common/models/offer_model.dart';

abstract class PromoEvent {}

class PromoLoadForBusinessRequested extends PromoEvent {
  final String businessId;
  PromoLoadForBusinessRequested(this.businessId);
}

class PromoCreateRequested extends PromoEvent {
  final PromoCode promo;
  final List<File> images;
  PromoCreateRequested(this.promo, {this.images = const []});
}

class PromoUpdateRequested extends PromoEvent {
  final PromoCode promo;
  final List<File> newImages;
  PromoUpdateRequested(this.promo, {this.newImages = const []});
}

class PromoDeleteRequested extends PromoEvent {
  final String promoId;
  PromoDeleteRequested(this.promoId);
}

class PromoClaimRequested extends PromoEvent {
  final String userId;
  final String promoId;
  final String? userName;
  final String? userPhone;
  PromoClaimRequested(this.userId, this.promoId, {this.userName, this.userPhone});
}

class UserClaimsLoadRequested extends PromoEvent {
  final String userId;
  UserClaimsLoadRequested(this.userId);
}

class PromoClaimsLoadRequested extends PromoEvent {
  final String promoId;
  PromoClaimsLoadRequested(this.promoId);
}

class PromoCancelRequested extends PromoEvent {
  final String userId;
  final String promoId;
  PromoCancelRequested(this.userId, this.promoId);
}

class PromoRedeemRequested extends PromoEvent {
  final String userId;
  final String promoId;
  final String verificationCode;
  PromoRedeemRequested(this.userId, this.promoId, this.verificationCode);
}

class OfferCreateRequested extends PromoEvent {
  final Offer offer;
  final List<File> images;
  OfferCreateRequested(this.offer, {this.images = const []});
}

class OfferUpdateRequested extends PromoEvent {
  final Offer offer;
  final List<File> newImages;
  OfferUpdateRequested(this.offer, {this.newImages = const []});
}

class OfferDeleteRequested extends PromoEvent {
  final String offerId;
  OfferDeleteRequested(this.offerId);
}
