import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final DateTime? startDate;
  final DateTime? endDate;
  final String termsAndConditions;
  final bool isActive;

  Offer({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    this.imageUrls = const [],
    this.startDate,
    this.endDate,
    this.termsAndConditions = '',
    this.isActive = true,
  });

  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);
  bool get isStarted => startDate == null || DateTime.now().isAfter(startDate!);
  bool get isAvailable => isActive && isStarted && !isExpired;

  factory Offer.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Offer(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      termsAndConditions: data['termsAndConditions'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'termsAndConditions': termsAndConditions,
      'isActive': isActive,
    };
  }
}
