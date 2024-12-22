class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
    };
  }

  // Add a factory constructor to create from a map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      email: map['email'],
      displayName: map['displayName'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      photoUrl: map['photoUrl'],
    );
  }
}