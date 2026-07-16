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
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> imageUrls;
  final String termsAndConditions;
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
    this.startDate,
    this.endDate,
    this.imageUrls = const [],
    this.termsAndConditions = '',
    this.isPublic = true,
    this.isActive = true,
  });

  int get remainingUsage => maxUsage - currentUsage;
  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);
  bool get isStarted => startDate == null || DateTime.now().isAfter(startDate!);
  bool get isAvailable => isActive && isStarted && !isExpired && remainingUsage > 0;

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
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? (data['expiryDate'] as Timestamp?)?.toDate(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      termsAndConditions: data['termsAndConditions'] ?? '',
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
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'imageUrls': imageUrls,
      'termsAndConditions': termsAndConditions,
      'isPublic': isPublic,
      'isActive': isActive,
    };
  }
}
