import 'package:cloud_firestore/cloud_firestore.dart';

enum BusinessStatus { pending, approved, active, suspended }

class Business {
  final String id;
  final String ownerId;
  final String name;
  final String category;
  final String description;
  final String location;
  final String city;
  final String state;
  final String zipcode;
  final String country;
  final double? latitude;
  final double? longitude;
  final String phoneNumber;
  final String whatsappNumber;
  final String email;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? websiteUrl;
  final String? logoUrl;
  final bool isVerified;
  final double averageRating;
  final int totalReviews;
  final int favoriteCount;
  final List<String> imageUrls;
  final Map<String, dynamic>? metadata;

  final BusinessStatus status;
  final bool isSubscriptionEnabled;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime createdAt;

  Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.city,
    required this.state,
    required this.zipcode,
    required this.country,
    this.latitude,
    this.longitude,
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.email,
    this.instagramUrl,
    this.facebookUrl,
    this.websiteUrl,
    this.logoUrl,
    this.isVerified = false,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.favoriteCount = 0,
    this.imageUrls = const [],
    this.metadata,
    this.status = BusinessStatus.approved,
    this.isSubscriptionEnabled = false,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.createdAt,
  });

  bool get isPubliclyVisible {
    // 1. Basic Status Check
    if (status != BusinessStatus.approved && status != BusinessStatus.active) {
      return false;
    }

    // 2. Subscription Logic
    if (isSubscriptionEnabled) {
      final now = DateTime.now();
      if (subscriptionStartDate != null && now.isBefore(subscriptionStartDate!)) {
        return false;
      }
      if (subscriptionEndDate != null && now.isAfter(subscriptionEndDate!)) {
        return false;
      }
    }

    return true;
  }

  factory Business.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Business(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipcode: data['zipcode'] ?? '',
      country: data['country'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      phoneNumber: data['phoneNumber'] ?? '',
      whatsappNumber: data['whatsappNumber'] ?? '',
      email: data['email'] ?? '',
      instagramUrl: data['instagramUrl'],
      facebookUrl: data['facebookUrl'],
      websiteUrl: data['websiteUrl'],
      logoUrl: data['logoUrl'],
      isVerified: data['isVerified'] ?? false,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      favoriteCount: data['favoriteCount'] ?? 0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      metadata: data['metadata'],
      status: _parseStatus(data['status']),
      isSubscriptionEnabled: data['isSubscriptionEnabled'] ?? false,
      subscriptionStartDate: (data['subscriptionStartDate'] as Timestamp?)?.toDate(),
      subscriptionEndDate: (data['subscriptionEndDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static BusinessStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'pending':
        return BusinessStatus.pending;
      case 'active':
        return BusinessStatus.active;
      case 'suspended':
        return BusinessStatus.suspended;
      case 'approved':
      default:
        return BusinessStatus.approved;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'category': category,
      'description': description,
      'location': location,
      'city': city,
      'state': state,
      'zipcode': zipcode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'email': email,
      'instagramUrl': instagramUrl,
      'facebookUrl': facebookUrl,
      'websiteUrl': websiteUrl,
      'logoUrl': logoUrl,
      'isVerified': isVerified,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'favoriteCount': favoriteCount,
      'imageUrls': imageUrls,
      'metadata': metadata,
      'status': status.name,
      'isSubscriptionEnabled': isSubscriptionEnabled,
      'subscriptionStartDate': subscriptionStartDate != null ? Timestamp.fromDate(subscriptionStartDate!) : null,
      'subscriptionEndDate': subscriptionEndDate != null ? Timestamp.fromDate(subscriptionEndDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
