class AppUser {
  final String uid;
  final String email;
  final String? dob;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime? locationTimestamp;

  AppUser({
    required this.uid,
    required this.email,
    this.dob,
    this.latitude,
    this.longitude,
    this.address,
    this.locationTimestamp,
  });

  // Save to Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'dob': dob,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'locationTimestamp': locationTimestamp?.toIso8601String(),
    };
  }

  // Load from Firestore
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      dob: map['dob'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
      locationTimestamp: map['locationTimestamp'] != null
          ? DateTime.tryParse(map['locationTimestamp'])
          : null,
    );
  }
}
