class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? photoUrl;
  final String? bio;
  final String? phoneNumber;
  final List<String> friends;
  final String usernameLower;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    this.bio,
    this.phoneNumber,
    this.friends = const [],
    this.usernameLower = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'friends': friends,
      'usernameLower': username.toLowerCase(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      phoneNumber: map['phoneNumber'],
      friends: List<String>.from(map['friends'] ?? []),
      usernameLower: map['usernameLower'] ?? map['username']?.toLowerCase() ?? '',
    );
  }
}