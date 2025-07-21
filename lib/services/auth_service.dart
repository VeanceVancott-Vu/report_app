import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // 👈 Add this
import '../models/user_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentAppUser;

  /// 👤 Firebase user (UID, email only)
  User? get currentUser => _auth.currentUser;

  /// 🔁 Firestore-based user model
  AppUser? get currentAppUser => _currentAppUser;

  AuthService() {
    _loadCurrentUser(); // 👈 Automatically check if logged in
  }

  Future<void> _loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        _currentAppUser = AppUser.fromMap(snapshot.data()!);
        notifyListeners(); // 👈 Notify once user is loaded
      }
    }
  }

  // 🔐 Sign Up with location
  Future<AppUser> signUp(String email, String password, String dob) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user!;

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert to address
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final place = placemarks.first;
        address = '${place.locality}, ${place.administrativeArea}, ${place.country}';
      } catch (e) {
        print("Reverse geocoding failed: $e");
      }

      final appUser = AppUser(
        uid: user.uid,
        email: email,
        dob: dob,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        locationTimestamp: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());

      _currentAppUser = appUser;
      notifyListeners(); // 👈 Update UI

      return appUser;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // 🔓 Log In with optional location
  Future<UserCredential> logIn({
    required String email,
    required String password,
    Position? location,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = result.user!.uid;

    // Optionally update location
    if (location != null) {
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        final place = placemarks.first;
        address = '${place.locality}, ${place.administrativeArea}, ${place.country}';
      } catch (e) {
        print("Reverse geocoding failed: $e");
      }
      await _firestore.collection('users').doc(uid).set({
        'address': address,
        'locationTimestamp': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }

    // Load AppUser from Firestore
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (snapshot.exists) {
      _currentAppUser = AppUser.fromMap(snapshot.data()!);
      notifyListeners(); // 👈 Notify after login
    }

    return result;
  }

  // 🚪 Log Out
  Future<void> logOut() async {
    await _auth.signOut();
    _currentAppUser = null;
    notifyListeners(); // 👈 Clear state
  }
}
