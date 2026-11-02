class PostModel {
  final String id;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  final String imageUrl;
  final String? caption;
  final List<String> likes;
  final DateTime createdAt;
  final int commentsCount;
  final List<String> imageUrls;
  final String? textBackground;
  final String captionLower;
  final String usernameLower;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoUrl,
    required this.imageUrl,
    this.caption,
    required this.likes,
    required this.createdAt,
    required this.commentsCount,
    this.imageUrls = const [],
    this.textBackground,
    this.captionLower = '',
    this.usernameLower = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'likes': likes,
      'createdAt': createdAt.toIso8601String(),
      'imageUrls': imageUrls,
      'textBackground': textBackground,
      'captionLower': (caption ?? '').toLowerCase(),
      'usernameLower': username.toLowerCase(),
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'],
      likes: List<String>.from(map['likes'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      commentsCount: map['commentsCount'] ?? 0,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      textBackground: map['textBackground'],
      captionLower: map['captionLower'] ?? (map['caption'] ?? '').toLowerCase(),
      usernameLower: map['usernameLower'] ?? map['username']?.toLowerCase() ?? '',
    );
  }
}