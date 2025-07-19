
import 'package:permission_handler/permission_handler.dart';
import '/utils/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io'; // for exit(0)

Future<Position?> requestLocationPermission() async {
  var status = await Permission.location.request();

  if (status.isGranted) {
    logger.d('Location permission granted');
    // Check if GPS is enabled
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }
      try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      logger.d(" Failed to get location: $e");
      return null;
    }
  } else if (status.isDenied) {
    logger.d(' Location permission denied');
     exit(0);
  } else if (status.isPermanentlyDenied) {
    openAppSettings(); // Open settings if user permanently denied
  }
}