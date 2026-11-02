class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  final String? imageUrl;
  final String? text;
  final String? textBackground;
  final int duration; // en heures : 12, 24, 48
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoUrl,
    this.imageUrl,
    this.text,
    this.textBackground,
    required this.duration,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isText => !isImage && text != null && text!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'imageUrl': imageUrl,
      'text': text,
      'textBackground': textBackground,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'viewedBy': viewedBy,
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    return StoryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      imageUrl: map['imageUrl'],
      text: map['text'],
      textBackground: map['textBackground'],
      duration: map['duration'] ?? 24,
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt: DateTime.parse(map['expiresAt']),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
    );
  }
}