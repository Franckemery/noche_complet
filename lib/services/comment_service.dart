import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Ajouter un commentaire
  Future<void> addComment({
    required String postId,
    required String userId,
    required String username,
    String? userPhotoUrl,
    required String text,
  }) async {
    final id = _uuid.v4();
    final comment = CommentModel(
      id: id,
      postId: postId,
      userId: userId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      text: text,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    batch.set(
      _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(id),
      comment.toMap(),
    );

    batch.update(
      _firestore.collection('posts').doc(postId),
      {'commentsCount': FieldValue.increment(1)},
    );

    await batch.commit();
  }

  // Supprimer un commentaire
  Future<void> deleteComment(String postId, String commentId) async {
    final batch = _firestore.batch();

    batch.delete(
      _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId),
    );

    batch.update(
      _firestore.collection('posts').doc(postId),
      {'commentsCount': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  // Récupérer les commentaires d'un post
  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CommentModel.fromMap(doc.data()))
            .toList());
  }
}