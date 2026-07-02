import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/models/business_model.dart';
import '../../core/app_constants.dart';

class BusinessRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerBusiness(Business business) async {
    await _firestore
        .collection(AppConstants.businessesCollection)
        .doc(business.id)
        .set(business.toFirestore());
    
    // Also update user document to link business if needed
    // (Optional: depending on if one user can have multiple businesses)
  }

  Future<Business?> getBusiness(String id) async {
    final doc = await _firestore.collection(AppConstants.businessesCollection).doc(id).get();
    if (doc.exists) {
      return Business.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<Business>> getBusinesses({String? category}) {
    Query query = _firestore.collection(AppConstants.businessesCollection);
    
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Business.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateBusiness(Business business) async {
    await _firestore
        .collection(AppConstants.businessesCollection)
        .doc(business.id)
        .update(business.toFirestore());
  }
}
