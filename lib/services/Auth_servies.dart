import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final Box _box;

  AuthServices() {
    _box = Hive.box('auth');
  }

  Stream<User?> get userChanges => _auth.authStateChanges();

  Future<String> getCurrentUserRole() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String role = data['role'] ?? 'cashier';
          await _saveRoleToHive(role);
          return role;
        }
      }
      return _box.get('user_role', defaultValue: 'cashier');
    } catch (e) {
      print('❌ Error getting role: $e');
      return _box.get('user_role', defaultValue: 'cashier');
    }
  }

  Future<void> setCurrentUserRole(String role) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'role': role,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await _saveRoleToHive(role);
    } catch (e) {
      print('❌ Error setting role: $e');
      await _saveRoleToHive(role);
    }
  }

  Future<void> _saveRoleToHive(String role) async {
    await _box.put('user_role', role);
  }

  Future<UserCredential?> signUpWithEmail(String email, String password, {String role = 'cashier'}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.sendEmailVerification();

      if (cred.user != null) {
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'uid': cred.user!.uid,
        });
        await _saveRoleToHive(role);
      }
      return cred;
    } catch (e) {
      print('❌ Sign up error: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) await getCurrentUserRole();
      return cred;
    } catch (e) {
      print('❌ Sign in error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _box.delete('user_role');
      await _auth.signOut();
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }
  // ---------------- RESET PASSWORD ----------------
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Reset password email sent to $email');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Unknown error sending reset email: $e');
      return false;
    }
  }

}
