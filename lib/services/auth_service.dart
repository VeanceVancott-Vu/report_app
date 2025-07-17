import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser> signUp(String email, String password, String dob) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user!;
      final appUser = AppUser(uid: user.uid, email: email, dob: dob);

      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());

      return appUser;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  
  // 🔑 Sign In
  Future<UserCredential> logIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 🔓 Sign Out
  Future<void> logOut() async {
    await _auth.signOut();
  }

  // 👤 Current User
  User? get currentUser => _auth.currentUser;




}
