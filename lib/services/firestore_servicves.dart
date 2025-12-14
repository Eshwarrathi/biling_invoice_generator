import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------- CURRENT USER ID ----------------
  static String? get currentUserId => _auth.currentUser?.uid;

  // ---------------- CURRENT USER ROLE ----------------
  static Future<String?> getCurrentUserRole() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return null;

    return userDoc.data()?['role'] as String?;
  }

  // ---------------- ADD RECORD ----------------
  static Future<String> addRecord(String collection, Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userId = user.uid;

    // Ensure userId is correct
    final docRef = _firestore.collection(collection).doc();
    final dataWithMeta = {
      ...data,
      'userId': userId, // 🔥 Must match Firestore rules
      'createdAt': FieldValue.serverTimestamp(),
      'id': docRef.id,
    };

    await docRef.set(dataWithMeta);
    return docRef.id;
  }

  // ---------------- UPDATE RECORD ----------------
  static Future<bool> updateRecord(String collection, String docId, Map<String, dynamic> newData) async {
    try {
      final docRef = _firestore.collection(collection).doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Document does not exist');

      final userId = currentUserId;
      final role = await getCurrentUserRole();
      final docData = doc.data() as Map<String, dynamic>;

      // Must be owner or admin
      if (userId != docData['userId'] && role != 'admin') {
        throw Exception('Permission denied to update this document');
      }

      final dataWithMeta = {
        ...newData,
        'userId': docData['userId'], // preserve owner
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.update(dataWithMeta);
      return true;
    } catch (e) {
      print('❌ Error updating record: $e');
      return false;
    }
  }

  // ---------------- DELETE RECORD ----------------
  static Future<bool> deleteRecord(String collection, String docId) async {
    try {
      final docRef = _firestore.collection(collection).doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Document does not exist');

      final userId = currentUserId;
      final role = await getCurrentUserRole();
      final docData = doc.data() as Map<String, dynamic>;

      // Must be owner or admin
      if (userId != docData['userId'] && role != 'admin') {
        throw Exception('Permission denied to delete this document');
      }

      await docRef.delete();
      return true;
    } catch (e) {
      print('❌ Error deleting record: $e');
      return false;
    }
  }

  // ---------------- GET MY RECORDS ----------------
  static Future<List<Map<String, dynamic>>> getMyRecords(String collection) async {
    final userId = currentUserId;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // ---------------- GET ALL RECORDS ----------------
  static Future<List<Map<String, dynamic>>> getAllRecords(String collection) async {
    final snapshot = await _firestore.collection(collection).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}