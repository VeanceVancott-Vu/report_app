import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      await _firestore.collection('users').doc(result.user!.uid).set({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': address,
        'locationTimestamp': DateTime.now().toIso8601String(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return result;
  }

  // 🚪 Log Out
  Future<void> logOut() async {
    await _auth.signOut();
  }

  // 👤 Current User
  User? get currentUser => _auth.currentUser;
}
