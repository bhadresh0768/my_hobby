import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { guest, customer, businessOwner, admin }

class UserModel {
  final String uid;
  final String? phoneNumber;
  final String displayName;
  final UserRole role;
  final String? photoUrl;
  final DateTime createdAt;
  final List<String> favorites;

  UserModel({
    required this.uid,
    this.phoneNumber,
    required this.displayName,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    this.favorites = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      phoneNumber: data['phoneNumber'],
      displayName: data['displayName'] ?? '',
      role: _parseRole(data['role']),
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      favorites: List<String>.from(data['favorites'] ?? []),
    );
  }

  static UserRole _parseRole(String? roleStr) {
    switch (roleStr) {
      case 'customer':
        return UserRole.customer;
      case 'businessOwner':
        return UserRole.businessOwner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.guest;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'role': role.name,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'favorites': favorites,
    };
  }
}
