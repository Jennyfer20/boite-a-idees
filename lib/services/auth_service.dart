import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isLoggedIn => currentUser != null;

  String get currentUserId => currentUser?.uid ?? '';
  String get currentUserName => currentUser?.displayName ?? currentUser?.email ?? 'Utilisateur';
  String get currentUserEmail => currentUser?.email ?? '';

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(displayName);

    await _db.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'displayName': displayName,
      'isAdmin': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<bool> isAdmin() async {
    if (currentUser == null) return false;
    final doc = await _db.collection('users').doc(currentUser!.uid).get();
    return doc.data()?['isAdmin'] ?? false;
  }
}
