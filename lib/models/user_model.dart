
class AppUser {
  final String uid;
  final String email;
  final String? dob;

  AppUser({
    required this.uid,
    required this.email,
    this.dob,
  });

  // For saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'dob': dob,
    };
  }

  // For loading from Firestore
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      dob: map['dob'],
    );
  }
}
