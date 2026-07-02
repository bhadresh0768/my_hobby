import 'package:cloud_firestore/cloud_firestore.dart';

class PromoCode {
  final String id;
  final String businessId;
  final String code;
  final String description;
  final double discountValue;
  final String discountType; // 'percentage' or 'fixed'
  final int maxUsage;
  final int currentUsage;
  final DateTime? expiryDate;
  final bool isPublic;
  final bool isActive;

  PromoCode({
    required this.id,
    required this.businessId,
    required this.code,
    required this.description,
    required this.discountValue,
    required this.discountType,
    required this.maxUsage,
    this.currentUsage = 0,
    this.expiryDate,
    this.isPublic = true,
    this.isActive = true,
  });

  factory PromoCode.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PromoCode(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      code: data['code'] ?? '',
      description: data['description'] ?? '',
      discountValue: (data['discountValue'] ?? 0.0).toDouble(),
      discountType: data['discountType'] ?? 'percentage',
      maxUsage: data['maxUsage'] ?? 0,
      currentUsage: data['currentUsage'] ?? 0,
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      isPublic: data['isPublic'] ?? true,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'code': code,
      'description': description,
      'discountValue': discountValue,
      'discountType': discountType,
      'maxUsage': maxUsage,
      'currentUsage': currentUsage,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'isPublic': isPublic,
      'isActive': isActive,
    };
  }
}
