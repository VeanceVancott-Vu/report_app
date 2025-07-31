import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final logger = Logger();
  AppUser? _currentAppUser;

  /// 👤 Firebase user (UID, email only)
  User? get currentUser => _auth.currentUser;

  /// 🔁 Firestore-based user model
  AppUser? get currentAppUser => _currentAppUser;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _currentAppUser = null;
        notifyListeners();
      } else {
        _loadCurrentUser();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          _currentAppUser = AppUser.fromMap(snapshot.data()!);
          logger.d('Loaded user: ${user.uid}, role: ${_currentAppUser?.role}');
          notifyListeners();
        }
      } catch (e) {
        logger.e('Error loading user: $e');
      }
    }
  }

  // 🔐 Sign Up with location and role
  Future<AppUser> signUp(String email, String password, String dob, {String role = 'citizen'}) async {
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
        logger.e('Reverse geocoding failed: $e');
      }

      final appUser = AppUser(
        uid: user.uid,
        email: email,
        dob: dob,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        locationTimestamp: DateTime.now(),
        role: role,
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());

      _currentAppUser = appUser;
      logger.d('Sign-up successful: ${user.uid}, role: $role');
      notifyListeners();

      return appUser;
    } catch (e) {
      logger.e('Sign-up error: $e');
      rethrow;
    }
  }

  // 🔓 Log In with optional location
  Future<(UserCredential, AppUser?)> logIn({
    required String email,
    required String password,
    Position? location,
  }) async {
    try {
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
          logger.e('Reverse geocoding failed: $e');
        }
        await _firestore.collection('users').doc(uid).set({
          'latitude': location.latitude,
          'longitude': location.longitude,
          'address': address,
          'locationTimestamp': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      // Load AppUser from Firestore
      AppUser? loadedUser;
      final snapshot = await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        loadedUser = AppUser.fromMap(snapshot.data()!);
        _currentAppUser = loadedUser;
        logger.d('Login successful: $uid, role: ${loadedUser.role}');
        notifyListeners();
      } else {
        logger.w('User document not found for $uid');
      }

      return (result, loadedUser); // ✅ Return both
    } catch (e) {
      logger.e('Login error: $e');
      rethrow;
    }
  }

  // 🚪 Log Out
  Future<void> logOut() async {
    try {
      await _auth.signOut();
      _currentAppUser = null;
      logger.d('Log out successful');
      notifyListeners();
    } catch (e) {
      logger.e('Log out error: $e');
      rethrow;
    }
  }
}
