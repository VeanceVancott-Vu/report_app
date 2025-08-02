class AppUser {
  // Private fields
  String _uid;
  String _email;
  String? _dob;
  double? _latitude;
  double? _longitude;
  String? _address;
  DateTime? _locationTimestamp;
  String _role; // New field: 'citizen' or 'admin'
  String? _profilePictureUrl; // New field for profile picture URL

  // Constructor
  AppUser({
    required String uid,
    required String email,
    String? dob,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? locationTimestamp,
    String role = 'citizen',
    String? profilePictureUrl,
  })  : _uid = uid,
        _email = email,
        _dob = dob,
        _latitude = latitude,
        _longitude = longitude,
        _address = address,
        _locationTimestamp = locationTimestamp,
        _role = role,
        _profilePictureUrl = profilePictureUrl;

  // Getters
  String get uid => _uid;
  String get userId => _uid; // Alias for compatibility
  String get email => _email;
  String? get dob => _dob;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get address => _address;
  DateTime? get locationTimestamp => _locationTimestamp;
  String get role => _role;
  String? get profilePictureUrl => _profilePictureUrl;

  // Setters
  set uid(String value) => _uid = value;
  set email(String value) => _email = value;
  set dob(String? value) => _dob = value;
  set latitude(double? value) => _latitude = value;
  set longitude(double? value) => _longitude = value;
  set address(String? value) => _address = value;
  set locationTimestamp(DateTime? value) => _locationTimestamp = value;
  set role(String value) => _role = value;
  set profilePictureUrl(String? value) => _profilePictureUrl = value;

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'uid': _uid,
      'email': _email,
      'dob': _dob,
      'latitude': _latitude,
      'longitude': _longitude,
      'address': _address,
      'locationTimestamp': _locationTimestamp?.toIso8601String(),
      'role': _role,
      'profilePictureUrl': _profilePictureUrl,
    };
  }

  // Create instance from Firestore map
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
      role: map['role'] ?? 'citizen',
      profilePictureUrl: map['profilePictureUrl'],
    );
  }
}