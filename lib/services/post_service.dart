import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'notification_service.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Créer un post
  Future<void> createPost({
    required String userId,
    required String username,
    String? userPhotoUrl,
    required String imageUrl,
    List<String> imageUrls = const [],
    String? caption,
    String? textBackground,
  }) async {
    final id = _uuid.v4();
    final post = PostModel(
      id: id,
      userId: userId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      caption: caption,
      textBackground: textBackground,
      likes: [],
      commentsCount: 0,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('posts').doc(id).set(post.toMap());

    await NotificationService.showNewPostNotification(
      username: username,
      caption: caption ?? '',
    );
  }

  // Récupérer les posts en temps réel
  Stream<List<PostModel>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PostModel.fromMap(doc.data())).toList());
  }

  // Liker / unliker un post
  Future<void> toggleLike(String postId, String userId) async {
    final ref = _firestore.collection('posts').doc(postId);
    final doc = await ref.get();
    final likes = List<String>.from(doc['likes'] ?? []);

    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }

    await ref.update({'likes': likes});
  }

  // Supprimer un post
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  // Récupérer les posts likés par un user
  Stream<List<PostModel>> getFavoritePostsStream(String userId) {
    return _firestore
        .collection('posts')
        .where('likes', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PostModel.fromMap(doc.data())).toList());
  }
}
